//
//  HiTextInfoWrapper.m
//  HiOCR
//
//  Created by netcanis on 5/2/24.
//

#import "HiTextInfoWrapper.h"

// Forward declaration of the C++ class
#ifdef __cplusplus
#include "HiTextInfo.h"  // C++ class definition
#endif

/// Wrapper class for the HiTextInfo C++ class, providing an Objective-C interface.
@interface HiTextInfoWrapper () {
    HiTextInfo *hiTextInfo;  // Pointer to the encapsulated C++ object
}

@end

@implementation HiTextInfoWrapper

/// Initializes a new instance of `HiTextInfoWrapper`.
///
/// This method creates a new C++ `HiTextInfo` instance and initializes it with
/// the given text and bounding box.
///
/// - Parameters:
///   - text: The recognized text.
///   - bbox: The bounding box of the text in CGRect format.
/// - Returns: An initialized instance of `HiTextInfoWrapper`.
- (instancetype)initWithText:(NSString *)text bbox:(CGRect)bbox {
    if (self = [super init]) {
        // Create a new HiTextInfo instance with the provided text and bounding box.
        hiTextInfo = new HiTextInfo([text UTF8String], {bbox.origin.x, bbox.origin.y, bbox.size.width, bbox.size.height});
    }
    return self;
}

/// Deallocates the C++ object to free memory.
- (void)dealloc {
    delete hiTextInfo;  // Free the memory allocated for the C++ object
}

/// Retrieves the text stored in the C++ object.
///
/// - Returns: The recognized text as an NSString.
- (NSString *)text {
    return [NSString stringWithUTF8String:hiTextInfo->getText().c_str()];
}

/// Retrieves the bounding box stored in the C++ object.
///
/// - Returns: The bounding box as a CGRect.
- (CGRect)bbox {
    HiRect rect = hiTextInfo->getBBox();  // Get the bounding box as a HiRect (C++ struct)
    return CGRectMake(rect.x, rect.y, rect.width, rect.height);  // Convert HiRect to CGRect
}

/// Provides a pointer to the encapsulated C++ object.
///
/// This method can be used to pass the C++ object to other methods or classes
/// that need direct access to the underlying `HiTextInfo` instance.
///
/// - Returns: A pointer to the `HiTextInfo` C++ object.
- (void *)getTextInfo {
    return hiTextInfo;
}

@end
