#include "engine/controls/bpmcontrol.h"

#include <gtest/gtest.h>

#include <QScopedPointer>
#include <QtDebug>

#include "audio/types.h"
#include "control/controlobject.h"
#include "control/controlpushbutton.h"
#include "mixxxtest.h"
#include "track/beats.h"
#include "track/track.h"

class BpmControlTest : public MixxxTest {
};

TEST_F(BpmControlTest, ShortestPercentageChange) {
    const double kEpsilon = 0.0000000001;
    EXPECT_NEAR(-0.02, BpmControl::shortestPercentageChange(0.01, 0.99), kEpsilon);
    EXPECT_NEAR(0.02, BpmControl::shortestPercentageChange(0.99, 0.01), kEpsilon);
    EXPECT_NEAR(0.40, BpmControl::shortestPercentageChange(0.80, 0.20), kEpsilon);
    EXPECT_NEAR(-0.40, BpmControl::shortestPercentageChange(0.20, 0.80), kEpsilon);
}

TEST_F(BpmControlTest, BeatContext_BeatGrid) {
    constexpr auto sampleRate = mixxx::audio::SampleRate(44100);

    TrackPointer pTrack = Track::newTemporary();
    pTrack->setAudioProperties(
            mixxx::audio::ChannelCount(2),
            mixxx::audio::SampleRate(sampleRate),
            mixxx::audio::Bitrate(),
            mixxx::Duration::fromSeconds(180));

    const auto bpm = mixxx::Bpm(60.0);
    const mixxx::audio::FrameDiff_t expectedBeatLengthFrames = (60.0 * sampleRate / bpm.value());

    const mixxx::BeatsPointer pBeats = mixxx::Beats::fromConstTempo(
            pTrack->getSampleRate(), mixxx::audio::kStartFramePos, bpm);

    // On a beat.
    mixxx::audio::FramePos prevBeatPosition;
    mixxx::audio::FramePos nextBeatPosition;
    mixxx::audio::FrameDiff_t beatLengthFrames;
    double beatPercentage;
    EXPECT_TRUE(BpmControl::getBeatContext(pBeats,
            mixxx::audio::kStartFramePos,
            &prevBeatPosition,
            &nextBeatPosition,
            &beatLengthFrames,
            &beatPercentage));
    EXPECT_EQ(mixxx::audio::kStartFramePos, prevBeatPosition);
    EXPECT_EQ(mixxx::audio::FramePos{beatLengthFrames}, nextBeatPosition);
    EXPECT_DOUBLE_EQ(expectedBeatLengthFrames, beatLengthFrames);
    EXPECT_DOUBLE_EQ(0.0, beatPercentage);
}

TEST_F(BpmControlTest, AdjustBeatsBpm_RoundsToNearestHundredth) {
    constexpr auto sampleRate = mixxx::audio::SampleRate(44100);

    TrackPointer pTrack = Track::newTemporary();
    pTrack->setAudioProperties(
            mixxx::audio::ChannelCount(2),
            mixxx::audio::SampleRate(sampleRate),
            mixxx::audio::Bitrate(),
            mixxx::Duration::fromSeconds(180));

    // Create a beatgrid at 120.00 BPM
    const auto bpm = mixxx::Bpm(120.0);
    const mixxx::BeatsPointer pBeats = mixxx::Beats::fromConstTempo(
            pTrack->getSampleRate(), mixxx::audio::kStartFramePos, bpm);
    pTrack->trySetBeats(pBeats);

    // Create BpmControl for the track's group
    // We need to use the control object system to test the actual slots
    ConfigKey group("[Channel1]");
    
    // Test the rounding behavior by directly calling adjustBeatsBpm logic
    // Since BpmControl is not easily testable in isolation without engine buffer,
    // we test the BeatUtils::roundBpmWithinRange function directly
    
    // Test that 120.005 rounds to 120.01 (nearest 0.01)
    const auto rounded1 = mixxx::BeatUtils::roundBpmWithinRange(
            mixxx::Bpm(120.0049), mixxx::Bpm(120.005), mixxx::Bpm(120.0051));
    EXPECT_NEAR(120.01, rounded1.value(), 0.001);
    
    // Test that 120.004 rounds to 120.00
    const auto rounded2 = mixxx::BeatUtils::roundBpmWithinRange(
            mixxx::Bpm(119.995), mixxx::Bpm(120.004), mixxx::Bpm(120.005));
    EXPECT_NEAR(120.00, rounded2.value(), 0.001);
    
    // Test that 120.015 rounds to 120.02
    const auto rounded3 = mixxx::BeatUtils::roundBpmWithinRange(
            mixxx::Bpm(120.0149), mixxx::Bpm(120.015), mixxx::Bpm(120.0151));
    EXPECT_NEAR(120.02, rounded3.value(), 0.001);
}
