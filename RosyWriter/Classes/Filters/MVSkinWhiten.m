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
@end

@implementation MVSkinWhiten
@synthesize inputImage;
@synthesize inputDegree;

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
    CIFilter *colorControls = [CIFilter filterWithName:@"CIColorControls"];
    [colorControls setValue:@(0.0) forKey:@"inputSaturation"];
    [colorControls setValue:self.inputImage forKey:@"inputImage"];
    result = colorControls.outputImage;
    return result;
}

@end
