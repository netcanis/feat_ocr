//
//  HiOCRAnalyzerWrapper.h
//  HiOCR
//
//  Created by netcanis on 5/2/24.
//

#import <Foundation/Foundation.h>
#import "HiTextInfoWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface HiOCRAnalyzerWrapper : NSObject
- (instancetype)initWithScanType:(NSInteger)scanType licenseKey:(NSString *)licenseKey;
- (nullable NSDictionary<NSString *, id> *)analyzeTextData:(NSArray<HiTextInfoWrapper *> *)textInfos;
- (NSString *)decryptionDataWithInput:(NSString *)input;

@end

NS_ASSUME_NONNULL_END
