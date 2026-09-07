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
// PortMidi is intentionally disabled on Android. The Android USB-MIDI
// implementation is compiled through this existing MIDI target source so no
// audio or global ControllerManager build plumbing is required.
#include "controllers/midi/portmidicontroller.cpp"
#include "controllers/midi/portmidienumerator.cpp"
#endif

MidiEnumerator::MidiEnumerator() : ControllerEnumerator() {
}

MidiEnumerator::~MidiEnumerator() {
}
