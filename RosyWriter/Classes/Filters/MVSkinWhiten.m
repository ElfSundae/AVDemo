//
//  MVSkinWhiten.m
//  RosyWriter
//
//  Created by Elf Sundae on 1/13/15.
//
//

#import "MVSkinWhiten.h"

@interface MVSkinWhiten ()
@property (nonatomic, strong) CIImage *inputImage;
@property (nonatomic, strong) NSNumber *inputDegree;

@property (nonatomic, strong) CIDetector *faceDetector;
@end

@implementation MVSkinWhiten
@synthesize inputImage;
@synthesize inputDegree;

- (instancetype)init
{
    self = [super init];
    NSDictionary *detectorOptions = @{
                                      CIDetectorTracking : @YES,
                                      CIDetectorAccuracy : CIDetectorAccuracyLow,
                                      };
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];

    return self;
}

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName : @"MV Skin Whiten",
             kCIAttributeFilterCategories : @[kCICategoryVideo, kCICategoryStillImage, kCICategoryBlur],
             @"inputDegree" :
                 @{
                     kCIAttributeType : kCIAttributeTypeScalar,
                     kCIAttributeSliderMin : @-1.0,
                     kCIAttributeSliderMax : @1.0,
                     kCIAttributeDefault : @1.0,
                     },
             };
}

- (void)setDefaults
{
    self.inputDegree = @1.0;
}


- (CIImage *)outputImage
{
    if (!self.inputImage) {
        return nil;
    }
    
    CIImage *result = nil;
#if 0
    CIFilter *colorControls = [CIFilter filterWithName:@"CIColorControls"];
    [colorControls setValue:@(0.0) forKey:@"inputSaturation"];
    [colorControls setValue:self.inputImage forKey:@"inputImage"];
    result = colorControls.outputImage;
#endif
    
    NSArray *faceFeatures = [self.faceDetector featuresInImage:self.inputImage options:nil];
    
    if (faceFeatures.count) {
        NSLog(@"%@", faceFeatures);
    }
#if 0
    CIFaceFeature *ff = faceFeatures.firstObject;
//    for (CIFaceFeature *ff in faceFeatures) {
        CGRect faceRect = ff.bounds;
        //the rect is rotate 90 deg, so we switch width/height and x/y
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        
        //TODO: adjust scaling
//    }
    //NSLog(@"%@", NSStringFromCGRect(faceRect));
#endif
    CGRect rect = self.inputImage.extent;
    rect.size.width /= 2.f;
    rect.size.height /= 2.f;
    rect.origin.x = (self.inputImage.extent.size.width - rect.size.width) / 2.f;
    rect.origin.y = (self.inputImage.extent.size.height - rect.size.height) / 2.f;
    CIImage *blurredImage = [[[CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputRadius", @(2.0), kCIInputImageKey, self.inputImage, nil] valueForKey:kCIOutputImageKey]
                             imageByCroppingToRect:[inputImage extent]];
    return blurredImage;
    result = [[CIFilter filterWithName:@"CIBlendWithMask" withInputParameters:
              @{kCIInputImageKey : blurredImage,
//                @"inputMaskImage" : maskImage;
                @"inputBackgroundImage" : self.inputImage}
              ] valueForKey:kCIOutputImageKey];
//    CGFloat h = [inputImage extent].size.height;
//    
//    CIColor *opaqueGreen      = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
//    CIColor *transparentGreen = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0];
//    
//    CIImage *gradient0 = [[CIFilter filterWithName:@"CILinearGradient" keysAndValues:
//                           @"inputPoint0", [CIVector vectorWithX:0.0 Y:h*0.75],
//                           @"inputPoint1", [CIVector vectorWithX:0.0 Y:h*0.50],
//                           @"inputColor0", opaqueGreen,
//                           @"inputColor1", transparentGreen, nil] valueForKey:kCIOutputImageKey];
//    
//    CIImage *gradient1 = [[CIFilter filterWithName:@"CILinearGradient" keysAndValues:
//                           @"inputPoint0", [CIVector vectorWithX:0.0 Y:h*0.25],
//                           @"inputPoint1", [CIVector vectorWithX:0.0 Y:h*0.50],
//                           @"inputColor0", opaqueGreen,
//                           @"inputColor1", transparentGreen, nil] valueForKey:kCIOutputImageKey];
//    
//    CIImage *maskImage = [[CIFilter filterWithName:@"CIAdditionCompositing" keysAndValues:
//                           kCIInputImageKey, gradient0, kCIInputBackgroundImageKey, gradient1,
//                           nil] valueForKey:kCIOutputImageKey];
//    
//    return [[CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:
//             kCIInputImageKey, blurredImage,
//             @"inputMaskImage", maskImage,
//             @"inputBackgroundImage", inputImage, nil]
//            valueForKey:kCIOutputImageKey];
    
    return result;
}

@end
