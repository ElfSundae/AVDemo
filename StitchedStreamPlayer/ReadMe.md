
### StitchedStreamPlayer ###

===========================================================================
DESCRIPTION:

A simple AVFoundation demonstration of how timed metadata can be used to identify different content in a stream, supporting a custom seek UI.

This sample expects the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries.

In this example, the metadata payload is either a list of ads ("ad-list") or an ad record ("url"). Each ad in the list of ads is specified by a start-time and end-time pair of values. Each ad record is specified by a URL which points to the ad video to play.

The ID3 key
AVMetadataID3MetadataKeyGeneralEncapsulatedObject is used to identify the metadata in the stream.

===========================================================================
DETAILS:

You can add various kinds of metadata to media stream segments. For example, you can add the album art, artist’s name, and song title to an audio stream. As another example, you could add the current batter’s name and statistics to video of a baseball game.




The specified metadata source can be a file in ID3 format or an image file (JPEG or PNG). Metadata specified this way is automatically inserted into every media segment.











===========================================================================
BUILD REQUIREMENTS:

iOS 9.3 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 8 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.4 - Update for iOS 9.3 SDK, fixed crash at launch due to window not having a root view controller, various other miscellaneous changes.

1.3 - Update for iOS 4.3

===========================================================================
Copyright (C) 2008-2016 Apple Inc. All rights reserved.