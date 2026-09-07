/**
* @file midienumerator.cpp
* @author Sean Pappalardo spappalardo@mixxx.org
* @date Tue 15 Mar 2012
* @brief Base class handling discovery and enumeration of DJ controllers that use the MIDI protocol.
*
*/

#include "controllers/midi/midienumerator.h"

#include "moc_midienumerator.cpp"

#ifdef __ANDROID__
// Android builds do not enable the desktop PortMidi library. The existing
// PortMidiController/PortMidiEnumerator classes contain the native Android
// USB-MIDI implementation, so compile them through this already-built MIDI
// translation unit.
#include "controllers/midi/portmidicontroller.cpp"
#include "controllers/midi/portmidienumerator.cpp"
#endif

MidiEnumerator::MidiEnumerator() : ControllerEnumerator() {
}

MidiEnumerator::~MidiEnumerator() {
}
