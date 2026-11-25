#pragma once

#include "rendermark_export.h"

#include <QColor>
#include <QImage>
#include <QQuickPaintedItem>
#include <QString>
#include <QtQml/qqmlregistration.h>

/**
 * @brief Native math-formula renderer backed by JKQTMathText.
 *
 * The item exposes a small QML surface (latex, fontSize, color, padding) and
 * caches the rendered QImage. When the JKQTMathText backend is not available
 * at build time the same item falls back to drawing the formula source as
 * plain text, so the QML module remains loadable without the optional
 * dependency.
 */
class RENDERMARK_EXPORT MathTextItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString latex READ latex WRITE setLatex NOTIFY latexChanged)
    Q_PROPERTY(int fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(int padding READ padding WRITE setPadding NOTIFY paddingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit MathTextItem(QQuickItem *parent = nullptr);

    QString latex() const;
    void setLatex(const QString &latex);

    int fontSize() const;
    void setFontSize(int fontSize);

    QColor color() const;
    void setColor(const QColor &color);

    int padding() const;
    void setPadding(int padding);

    QString error() const;

    void paint(QPainter *painter) override;

signals:
    void latexChanged();
    void fontSizeChanged();
    void colorChanged();
    void paddingChanged();
    void errorChanged();

protected:
    void itemChange(ItemChange change, const ItemChangeData &data) override;

private:
    void rebuild();
    void rebuildFallback();

    QString m_latex;
    int m_fontSize = 20;
    QColor m_color = Qt::black;
    int m_padding = 4;
    QString m_error;
    QImage m_image;
    qreal m_lastDpr = 1.0;
};
