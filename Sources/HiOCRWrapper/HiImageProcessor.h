//
//  HiImageProcessor.h
//  feat_ocr
//
//  Created by netcanis on 12/23/24.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HiImageProcessor : NSObject

+ (UIImage *)processCardImage:(UIImage *)uiImage;
+ (UIImage *)processCardImageForEmbossedText:(UIImage *)uiImage;

@end

NS_ASSUME_NONNULL_END
