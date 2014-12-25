
**Demo projects for iOS Audio & Video development:**

------

UIImagePicker Video Recorder
=======

Demonstrates how to create a custom UI for the camera variant of the UIImagePickerController and how to programmatically control video recording.

AVCam
=======

AVCam demonstrates usage of AV Foundation capture API for recording movies, taking still images, and switching cameras. It runs only on an actual device, either an iPad or iPhone, and cannot be run in the simulator.

VideoSnake
=======

This sample demonstrates temporal synchronization of video with motion data from the accelerometer and gyroscope. It also includes a class which illustrates best practices for using the AVAssetWriter API to record movies.  This is based on the VideoSnake demo presented at WWDC 2012, Session 520, "What's new in Camera Capture".


AVCamManualUsingtheManualCaptureAPI
=======

AVCamManual adds manual controls for focus, exposure, and white balance to the AVCam sample application.


AVBasicVideoOutput
=======

The AVBasicVideoOutput This sample shows how to perform **real-time video processing** using `AVPlayerItemVideoOutput` and how to optimally display processed video frames on screen using CAEAGLLayer and CADisplayLink. It uses simple math to adjust the luma and chroma values of pixels in every video frame in real time. 

An AVPlayerItemVideoOutput object vends CVPixelBuffers in real-time. To drive the AVPlayerItemVideoOutput we need to use a fixed rate, **hardware synchronized service** like CADisplayLink or GLKitViewController. These services send a callback to the application at the vertical sync frequency. Through these callbacks we can query AVPlayerItemVideoOutput for a new pixel buffer (if available) for the next vertical sync. This pixel buffer is then processed for any video effect we wish to apply and rendered to screen on a view backed by a CAEAGLLayer.

CapturePause sample
======

iPhone CapturePause sample from http://www.gdcl.co.uk//2013/04/03/Fix-CapturePause.html


GLCameraRipple
=======

This sample demonstrates how to use the AVFoundation framework to capture YUV
frames from the camera and process them using shaders in OpenGL ES 2.0.
CVOpenGLESTextureCache, which is new to iOS 5.0, is used to provide optimal
performance when using the AVCaptureOutput as an OpenGL texture. In addition, a
ripple effect is applied by modifying the texture coordinates of a densely
tessellated quad.

RosyWriter
=======

This sample demonstrates how to use AVCaptureVideoDataOutput to bring frames from the camera into various processing pipelines, including CPU-based, OpenGL (i.e. on the GPU), CoreImage filters, and OpenCV. It also demonstrates best practices for writing the processed output of these pipelines to a movie file using AVAssetWriter.

The project includes a different target for each of the different processing pipelines.

AVSimpleEditoriOS
=======

A simple AV Foundation based movie editing application for iOS.

AVCustomEdit
=======

AVCustomEdit is a simple AVFoundation based movie editing application demonstrating custom compositing to add transitions. The sample demonstrates the use of custom compositors to add transitions to an AVMutableComposition. It implements the AVVideoCompositing and AVVideoCompositionInstruction protocols to have access to individual source frames, which are then be rendered using OpenGL off screen rendering. 

Note: The sample has been developed for iPhones 4S and above/iPods with 4-inch display and iPads. These developed transitions are not supported on simulator.

VideoEditing-Final2
======

From [AVFoundation Tutorial: Adding Overlays and Animations to Videos](http://www.raywenderlich.com/30200/avfoundation-tutorial-adding-overlays-and-animations-to-videos)

This AVFoundation tutorial will build upon that by teaching all you budding video editors how to add the following effects to your videos:

+ Colored borders with custom sizes.
+ Multiple overlays.
+ Text for subtitles or captions.
+ Tilt effects.
+ Twinkle, rotate, and fade animation effects!


AVCompositionDebugVieweriOS
=======

This sample application has an AVCompositionDebugView which presents a visual description of the underlying AVComposition, AVVideoComposition and AVAudioMix objects which form the composition made using two clips, adding a cross fade transition in between and audio ramps to the two audio tracks. The visualization provided by the sample can be used as a debugging tool to discover issues with an incorrect composition/video composition. For example: a break in video composition would render black frames to screen, which can easily be detected using the visualization in the sample.


AVMovieExporter
=======

This universal sample application reads movie files from the asset and media library then 
exports them to a new media file with user defined settings. The user can adjust the exported file 
in the following ways:

- Export presets can be chosen which influence the size and quality of the output. 	
- The file type can be changed.
- Tracks and existing metadata can be inspected.
- Metadata can be inserted or deleted.


AudioTapProcessor
=======

Sample application that uses the MTAudioProcessingTap in combination with AV Foundation to visualize audio samples as well as applying a Core Audio audio unit effect (Bandpass Filter) to the audio data.

*Note:* The sample requires at least one video asset in the Asset Library (Camera Roll) to use as the source media. It will automatically select the first one it finds.

