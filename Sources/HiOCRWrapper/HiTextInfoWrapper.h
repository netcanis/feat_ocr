//
//  HiTextInfoWrapper.h
//  HiOCR
//
//  Created by netcanis on 5/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


NS_ASSUME_NONNULL_BEGIN

@interface HiTextInfoWrapper : NSObject

- (instancetype)initWithText:(NSString *)text bbox:(CGRect)bbox;
- (NSString *)text;
- (CGRect)bbox;
- (void *)getTextInfo;

@end

NS_ASSUME_NONNULL_END
