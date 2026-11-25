#include "MathTextItem.h"

#include <QFont>
#include <QFontMetricsF>
#include <QPainter>
#include <QQuickWindow>
#include <QtMath>

#ifdef RENDERMARK_ENABLE_MATH_TEXT
#include "jkqtmathtext/jkqtmathtext.h"
#endif

namespace {

// Untrusted Markdown can contain formulas with thousands of glyphs or huge
// spacing commands. Bound both the parser input and the raster allocation so a
// single message cannot exhaust memory.
constexpr int kMaxFormulaChars = 8192;
constexpr int kMaxFormulaDepth = 64;
constexpr int kMaxFormulaCommands = 1024;
constexpr int kMaxRenderedDimension = 4096;
constexpr qint64 kMaxRenderedPixels = 8 * 1024 * 1024;

bool formulaTooComplex(const QString &formula, QString *reason)
{
    int depth = 0;
    int maxDepth = 0;
    int commands = 0;

    for (int i = 0; i < formula.size(); ++i) {
        const QChar character = formula.at(i);
        if (character == QLatin1Char('\\')) {
            ++commands;
            // Escaped braces are literal characters, not grouping.
            if (i + 1 < formula.size())
                ++i;
        } else if (character == QLatin1Char('{')) {
            maxDepth = qMax(maxDepth, ++depth);
        } else if (character == QLatin1Char('}') && depth > 0) {
            --depth;
        }
    }

    if (maxDepth > kMaxFormulaDepth) {
        *reason = QStringLiteral("Formula nesting exceeds the safe limit");
        return true;
    }
    if (commands > kMaxFormulaCommands) {
        *reason = QStringLiteral("Formula has too many commands to render safely");
        return true;
    }
    return false;
}

} // namespace

MathTextItem::MathTextItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    setFlag(ItemHasContents, true);
}

QString MathTextItem::latex() const
{
    return m_latex;
}

void MathTextItem::setLatex(const QString &latex)
{
    if (m_latex == latex)
        return;
    m_latex = latex;
    emit latexChanged();
    rebuild();
}

int MathTextItem::fontSize() const
{
    return m_fontSize;
}

void MathTextItem::setFontSize(int fontSize)
{
    const int clamped = qBound(6, fontSize, 160);
    if (m_fontSize == clamped)
        return;
    m_fontSize = clamped;
    emit fontSizeChanged();
    rebuild();
}

QColor MathTextItem::color() const
{
    return m_color;
}

void MathTextItem::setColor(const QColor &color)
{
    if (m_color == color)
        return;
    m_color = color;
    emit colorChanged();
    rebuild();
}

int MathTextItem::padding() const
{
    return m_padding;
}

void MathTextItem::setPadding(int padding)
{
    const int clamped = qBound(0, padding, 64);
    if (m_padding == clamped)
        return;
    m_padding = clamped;
    emit paddingChanged();
    rebuild();
}

QString MathTextItem::error() const
{
    return m_error;
}

void MathTextItem::paint(QPainter *painter)
{
    if (m_image.isNull())
        rebuild();

    if (m_image.isNull())
        return;

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setRenderHint(QPainter::TextAntialiasing, true);
    painter->drawImage(QRectF(0, 0, width(), height()), m_image);
    painter->restore();
}

void MathTextItem::itemChange(ItemChange change, const ItemChangeData &data)
{
    QQuickPaintedItem::itemChange(change, data);
    if (change == ItemSceneChange) {
        const qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
        if (!qFuzzyCompare(dpr, m_lastDpr))
            rebuild();
    }
}

void MathTextItem::rebuild()
{
    const qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
    m_lastDpr = dpr;
    m_error.clear();
    m_image = QImage();

    const QString formula = m_latex.trimmed();
    if (formula.isEmpty()) {
        setImplicitSize(0, 0);
        update();
        emit errorChanged();
        return;
    }

    if (formula.size() > kMaxFormulaChars) {
        m_error = QStringLiteral("Formula exceeds the %1 character limit")
                      .arg(kMaxFormulaChars);
        rebuildFallback();
        emit errorChanged();
        return;
    }
    if (formulaTooComplex(formula, &m_error)) {
        rebuildFallback();
        emit errorChanged();
        return;
    }

#ifdef RENDERMARK_ENABLE_MATH_TEXT
    {
        JKQTMathText math;
        math.setFontSize(m_fontSize);
        math.setFontColor(m_color);

        if (math.parse(formula)) {
            QImage probe(1, 1, QImage::Format_ARGB32_Premultiplied);
            QPainter probePainter(&probe);
            const QSizeF formulaSize = math.getSize(probePainter);
            probePainter.end();

            const qreal widthPx = (formulaSize.width() + m_padding * 2) * dpr;
            const qreal heightPx = (formulaSize.height() + m_padding * 2) * dpr;
            if (!qIsFinite(widthPx) || !qIsFinite(heightPx) || widthPx <= 0
                || heightPx <= 0 || widthPx > kMaxRenderedDimension
                || heightPx > kMaxRenderedDimension
                || widthPx * heightPx > kMaxRenderedPixels) {
                m_error = QStringLiteral("Formula is too large to render safely");
                rebuildFallback();
                emit errorChanged();
                return;
            }

            m_image = math.drawIntoImage(false, QColor(Qt::transparent),
                                         m_padding, dpr, 96);
            if (!m_image.isNull()) {
                setImplicitSize(m_image.width() / dpr, m_image.height() / dpr);
                update();
                emit errorChanged();
                return;
            }
            m_error = QStringLiteral("JKQTMathText returned an empty image");
        } else {
            m_error = math.getErrorList().join(QStringLiteral("; "));
            if (m_error.isEmpty())
                m_error = QStringLiteral("JKQTMathText parse failed");
        }
    }
#endif

    rebuildFallback();
    emit errorChanged();
}

void MathTextItem::rebuildFallback()
{
    QFont font;
    font.setPixelSize(m_fontSize);
    font.setStyleHint(QFont::Serif);

    const QFontMetricsF metrics(font);
    const int padding = m_padding;
    const qreal availableWidth = qMax(1, kMaxRenderedDimension - padding * 2);

    QString displayText = m_latex;
    if (metrics.horizontalAdvance(displayText) > availableWidth)
        displayText = metrics.elidedText(displayText, Qt::ElideRight,
                                         qFloor(availableWidth));

    const qreal textWidth = metrics.horizontalAdvance(displayText);
    const qreal textHeight = metrics.height();

    QImage image(qCeil(textWidth) + padding * 2,
                 qCeil(textHeight) + padding * 2,
                 QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);

    QPainter painter(&image);
    painter.setRenderHint(QPainter::TextAntialiasing, true);
    painter.setFont(font);
    painter.setPen(m_color);
    painter.drawText(QPointF(padding, padding + metrics.ascent()), displayText);
    painter.end();

    m_image = image;
    setImplicitSize(image.width(), image.height());
    update();
}
