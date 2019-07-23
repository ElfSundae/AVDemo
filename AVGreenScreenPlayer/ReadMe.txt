### AVGreenScreenPlayer ###

===========================================================================
DESCRIPTION:

This OS X sample application demonstrates real-time video processing, specifically chroma key-effect, using AVPlayerItemVideoOutput. It uses AVPlayerItemVideoOutput in combination with a custom CIFilter to do basic chroma keying. The sample demonstrates the use of CVDisplayLink to drive AVPlayerItemVideoOutput to vend pixel buffers and also AVSampleBufferDisplayLayer to display the processed buffers. The user can input color using the color well and this color is used for the chroma key effect through a CIFilter which is added as a filter to the AVSampleBufferDisplayLayer.

===========================================================================
USING THE APP:

Launch the app and you will be prompted to open an existing video file to perform the custom video processing. You can open additional video files using the File->Open menu item.

Click the color well to select a color to use for the chroma key effect.

Press the Play button to play the movie and the chroma key effect is applied during playback. 

===========================================================================
BUILD REQUIREMENTS:

Xcode 5 or later, Mac OS X v10.9 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.8 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Fixed a crash when opening then closing an empty window. Updated to display open file dialog at app launch if no documents are open from a previous launch. Fixed a potential memory leak. Other misc. changes.

Version 1.1
- Set layerUsesCoreImagesFilters on NSView’s subclass to adopt API changes.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012-2014 Apple Inc. All rights reserved.
