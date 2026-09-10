#include "qml/qmlskincontrolcreator.h"

#include <QtDebug>

#include "control/controlobject.h"
#include "moc_qmlskincontrolcreator.cpp"
#include "util/assert.h"

namespace {
const QString kSkinGroup = QStringLiteral("[Skin]");
} // namespace

namespace mixxx {
namespace qml {

QmlSkinControlCreator::QmlSkinControlCreator(QObject* parent)
        : QObject(parent),
          m_persist(false),
          m_persistConfigured(false),
          m_defaultValue(0.0),
          m_defaultValueConfigured(false),
          m_buttonMode(ButtonMode::Toggle),
          m_isComponentComplete(false) {
}

void QmlSkinControlCreator::componentComplete() {
    m_isComponentComplete = true;
    if (!m_pControl) {
        createControl();
    }
}

void QmlSkinControlCreator::setGroup(const QString& group) {
    if (m_key.group == group) {
        return;
    }
    m_key.group = group;
    emit groupChanged(group);
    createDefaultControlBeforeComponentComplete();
    createControl();
}

const QString& QmlSkinControlCreator::getGroup() const {
    return m_key.group;
}

void QmlSkinControlCreator::setKey(const QString& key) {
    if (m_key.item == key) {
        return;
    }
    m_key.item = key;
    emit keyChanged(key);
    createDefaultControlBeforeComponentComplete();
    createControl();
}

const QString& QmlSkinControlCreator::getKey() const {
    return m_key.item;
}

void QmlSkinControlCreator::setPersist(bool persist) {
    if (m_persist == persist) {
        return;
    }
    m_persist = persist;
    m_persistConfigured = true;
    emit persistChanged(persist);
    createDefaultControlBeforeComponentComplete();
    createControl();
}

bool QmlSkinControlCreator::getPersist() const {
    return m_persist;
}

void QmlSkinControlCreator::setDefaultValue(double defaultValue) {
    const bool changed = m_defaultValue != defaultValue;
    m_defaultValue = defaultValue;
    m_defaultValueConfigured = true;
    if (changed) {
        emit defaultValueChanged(defaultValue);
    }
    createDefaultControlBeforeComponentComplete();
    createControl();
}

double QmlSkinControlCreator::getDefaultValue() const {
    return m_defaultValue;
}

void QmlSkinControlCreator::setButtonMode(ButtonMode buttonMode) {
    if (m_buttonMode == buttonMode) {
        return;
    }
    m_buttonMode = buttonMode;
    emit buttonModeChanged(buttonMode);
    if (m_pControl) {
        m_pControl->setButtonMode(toControlButtonMode(m_buttonMode));
    }
}

QmlSkinControlCreator::ButtonMode QmlSkinControlCreator::getButtonMode() const {
    return m_buttonMode;
}

mixxx::control::ButtonMode QmlSkinControlCreator::toControlButtonMode(
        ButtonMode buttonMode) {
    switch (buttonMode) {
    case ButtonMode::Push:
        return mixxx::control::ButtonMode::Push;
    case ButtonMode::Toggle:
        return mixxx::control::ButtonMode::Toggle;
    case ButtonMode::PowerWindow:
        return mixxx::control::ButtonMode::PowerWindow;
    case ButtonMode::LongPressLatching:
        return mixxx::control::ButtonMode::LongPressLatching;
    case ButtonMode::Trigger:
        return mixxx::control::ButtonMode::Trigger;
    }
    DEBUG_ASSERT(false);
    return mixxx::control::ButtonMode::Toggle;
}

void QmlSkinControlCreator::createControl(bool allowBeforeComponentComplete) {
    if (!m_isComponentComplete && !allowBeforeComponentComplete) {
        qDebug() << "[BeatGridDiag] SkinControlCreator: deferred creation (not complete)"
                 << m_key.group << m_key.item;
        return;
    }
    m_pControl.reset();

    if (!m_key.isValid()) {
        qWarning() << "[BeatGridDiag] SkinControlCreator: invalid key" << m_key.group << m_key.item;
        return;
    }
    if (m_key.group != kSkinGroup) {
        qWarning() << "[BeatGridDiag] SkinControlCreator: Cannot create non-skin control"
                   << m_key.group << m_key.item;
        return;
    }
    if (ControlObject::exists(m_key)) {
        qWarning() << "[BeatGridDiag] SkinControlCreator: Already exists"
                   << m_key.group << m_key.item;
        return;
    }

    qDebug() << "[BeatGridDiag] SkinControlCreator: CREATING control"
             << m_key.group << m_key.item
             << "persist=" << m_persist << "default=" << m_defaultValue
             << "mode=" << static_cast<int>(m_buttonMode);

    m_pControl = std::make_unique<ControlPushButton>(
            m_key,
            m_persist,
            m_defaultValue);
    m_pControl->setButtonMode(toControlButtonMode(m_buttonMode));

    qDebug() << "[BeatGridDiag] SkinControlCreator: CREATED control"
             << m_key.group << m_key.item;
}

void QmlSkinControlCreator::createDefaultControlBeforeComponentComplete() {
    if (m_isComponentComplete || m_pControl || !m_persistConfigured ||
            !m_defaultValueConfigured ||
            !m_key.isValid() || m_key.group != kSkinGroup ||
            ControlObject::exists(m_key)) {
        return;
    }
    createControl(true);
}

} // namespace qml
} // namespace mixxx
