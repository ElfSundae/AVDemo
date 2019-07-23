/*
     File: GSChromaKeyFilter.m
 Abstract: Core Image chroma key filter
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "GSChromaKeyFilter.h"

#define GSChromaKeyFilter_DEFAULT_COLOR [CIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f]

@implementation GSChromaKeyFilter

static CIKernel *_GSChromaKeyFilterKernel;

- (id)init
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *code = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"GSChromaKeyFilter" withExtension:@"cikernel"] usedEncoding:NULL error:NULL];
		NSArray *kernels = [CIKernel kernelsWithString:code];
		_GSChromaKeyFilterKernel = kernels[0];
	});
	
	self = [super init];
	
	if (self)
	{
		inputColor = GSChromaKeyFilter_DEFAULT_COLOR;
	}
	
	return self;
}

- (CIImage *)outputImage
{
	NSParameterAssert(inputImage != nil && [inputImage isKindOfClass:[CIImage class]]);
	NSParameterAssert(inputColor != nil && [inputColor isKindOfClass:[CIColor class]]);
	
	// Create checkerboard image used as background for filter.
	CGRect imageExtent = [inputImage extent];
	CIImage *backgroundImage = [[[CIFilter filterWithName:@"CICheckerboardGenerator"
											keysAndValues:kCIInputCenterKey, [CIVector vectorWithX:(CGRectGetWidth(imageExtent) * 0.5f)
																								 Y:(CGRectGetHeight(imageExtent) * 0.5f)],
								  @"inputColor0", [CIColor colorWithRed:0.5f green:0.5f blue:0.5f],
								  @"inputColor1", [CIColor colorWithRed:1.0f green:1.0f blue:1.0f],
								  kCIInputWidthKey, @10.0,
								  kCIInputSharpnessKey, @1.0, nil]
								 valueForKey:kCIOutputImageKey] imageByCroppingToRect:imageExtent];
	
	// Create output image by applying chroma key filter.
	CIImage *outputImage = [self apply:_GSChromaKeyFilterKernel,
							[CISampler samplerWithImage:inputImage],
							[CISampler samplerWithImage:backgroundImage],
							[CIVector vectorWithX:[inputColor red] Y:[inputColor green] Z:[inputColor blue] W:[inputColor alpha]],
							kCIApplyOptionDefinition, [inputImage definition],
							nil];
	
	return outputImage;
}

- (NSDictionary *)customAttributes
{
	return @{kCIInputColorKey : @{kCIAttributeClass : [CIColor class],
	                              kCIAttributeDefault : GSChromaKeyFilter_DEFAULT_COLOR,
	                              kCIAttributeType : kCIAttributeTypeOpaqueColor}};
}

@end
