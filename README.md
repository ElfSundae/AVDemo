
**Demo projects for iOS Audio & Video development:**


###AVCam

	AVCam demonstrates usage of AV Foundation capture API for recording movies, taking still images, and switching cameras. It runs only on an actual device, either an iPad or iPhone, and cannot be run in the simulator.


###AVCamManualUsingtheManualCaptureAPI

	AVCamManual adds manual controls for focus, exposure, and white balance to the AVCam sample application.


###AVBasicVideoOutput

	The AVBasicVideoOutput This sample shows how to perform **real-time video processing** using `AVPlayerItemVideoOutput` and how to optimally display processed video frames on screen using CAEAGLLayer and CADisplayLink. It uses simple math to adjust the luma and chroma values of pixels in every video frame in real time. 
	
	An AVPlayerItemVideoOutput object vends CVPixelBuffers in real-time. To drive the AVPlayerItemVideoOutput we need to use a fixed rate, **hardware synchronized service** like CADisplayLink or GLKitViewController. These services send a callback to the application at the vertical sync frequency. Through these callbacks we can query AVPlayerItemVideoOutput for a new pixel buffer (if available) for the next vertical sync. This pixel buffer is then processed for any video effect we wish to apply and rendered to screen on a view backed by a CAEAGLLayer.


###GLCameraRipple

	This sample demonstrates how to use the AVFoundation framework to capture YUV
	frames from the camera and process them using shaders in OpenGL ES 2.0.
	CVOpenGLESTextureCache, which is new to iOS 5.0, is used to provide optimal
	performance when using the AVCaptureOutput as an OpenGL texture. In addition, a
	ripple effect is applied by modifying the texture coordinates of a densely
	tessellated quad.

###RosyWriter

	This sample demonstrates how to use AVCaptureVideoDataOutput to bring frames from the camera into various processing pipelines, including CPU-based, OpenGL (i.e. on the GPU), CoreImage filters, and OpenCV. It also demonstrates best practices for writing the processed output of these pipelines to a movie file using AVAssetWriter.
	
	The project includes a different target for each of the different processing pipelines.


###UIImagePicker Video Recorder

	Demonstrates how to create a custom UI for the camera variant of the UIImagePickerController and how to programmatically control video recording.

