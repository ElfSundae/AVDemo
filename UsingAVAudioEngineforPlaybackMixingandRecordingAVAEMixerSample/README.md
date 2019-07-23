# Using AVAudioEngine for Playback, Mixing and Recording

This sample uses the AVAudioEngine with two AVAudioPlayerNode and AVAudioPCMBuffer objects along with an AVAudioUnitDelay and AVAudioUnitReverb to playback two loops which can then be mixed, processed and recorded.

AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs an audio signal generation, processing, or input/output task.

For more information refer to AVAudioEngine in Practice WWDC 2014: https://developer.apple.com/videos/wwdc/2014/#502

## Requirements

### Build

iOS 10 SDK, Xcode Version 8 or greater

### Runtime

iOS 10.x

## Version History
1.0 First public version

1.1 Minor updates:
* added audio to the UIBackgroundModes in the plist
* improved handling of audio interruptions
* changed the audio category to Playback, previous version used PlayAndRecord, but doesn't require audio input
* fixed a bug in handleMediaServicesReset: method
* corrected some old comments

2.0 Major update:
* (new) Demonstrates use of AVAudioSequencer, AVAudioMixing, AVAudioDestinationMixing
* (new) Added support for iPhone, iPad using Size Classes
* (modified) Useage of a single AVAudioPlayerNode that toggles between a recorded AVAudioFile and a AVAudioPCMBuffer

2.1 Minor update:
* (modified) Explicitly use the buffer format as the connection format for the player to reverb & reverb to mainMixer, to make it clear that these formats must match.

2.2 Minor update:
* (new) Audio parameter views on iPhone now have a 'Dismiss' button in addition to 'Swipe down' to dismiss.
* (modified) AVAudioEngine is now paused when nothing is playing or being recorded.
* (modified) Refactored some methods to support pausing and to ensure proper initialization after reset or engine reconfiguration.

2.3 Minor update:
* (modified) handleMediaServicesReset now configures AVAudioSession per QA1749

Copyright (C) 2015-2017 Apple Inc. All rights reserved.
