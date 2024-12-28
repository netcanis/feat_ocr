//
//  HiOCRAnalyzerWrapper.mm
//  HiOCR
//
//  Created by MWKG on 5/2/24.
//

#import "HiOCRAnalyzerWrapper.h"

// Forward declaration of the C++ class
#ifdef __cplusplus
#include "HiOCRAnalyzer.h"
#endif


/// Objective-C++ wrapper for the HiOCRAnalyzer C++ class.
@interface HiOCRAnalyzerWrapper () {
    HiOCRAnalyzer *analyzer;  // Pointer to the C++ object
}
@property (nonatomic, assign) NSInteger scanType;  // The scan type used for initialization
@end

@implementation HiOCRAnalyzerWrapper

/// Initializes a new instance of `HiOCRAnalyzerWrapper`.
- (instancetype)init {
    return [self initWithScanType:0 licenseKey:@""]; // Call the designated initializer
}

/// Initializes a new instance of `HiOCRAnalyzerWrapper` with a specific scan type.
/// - Parameter scanType: The scan type used to configure the analyzer.
- (instancetype)initWithScanType:(NSInteger)scanType licenseKey:(NSString *)licenseKey {
    self = [super init];
    if (self) {
        _scanType = scanType;  // Assign scan type
        if (analyzer == NULL) {
            // Convert NSString to std::string
            std::string cppLicenseKey = [licenseKey UTF8String];
            // Pass parameters to the C++ class
            analyzer = new HiOCRAnalyzer(static_cast<long>(scanType), cppLicenseKey);
        }
    }
    return self;
}

/// Deallocates the C++ class instance and cleans up memory.
- (void)dealloc {
    delete analyzer;  // Free the C++ class instance
    analyzer = nullptr;
}

/// Analyzes an array of text information using the underlying C++ analyzer.
///
/// Converts the provided `HiTextInfoWrapper` objects into C++ `HiTextInfo` objects,
/// processes them using the `HiOCRAnalyzer` instance, and returns the result as an
/// Objective-C dictionary.
///
/// - Parameter textInfos: An array of `HiTextInfoWrapper` objects representing the text data to analyze.
/// - Returns: A dictionary containing the analysis results, or `nil` if an error occurs.
- (nullable NSDictionary<NSString *, id> *)analyzeTextData:(NSArray<HiTextInfoWrapper *> *)textInfos {
    std::vector<HiTextInfo*> cppTextInfos;  // Vector to hold C++ text information
    for (HiTextInfoWrapper *wrapper in textInfos) {
        HiTextInfo *pTextInfo = (HiTextInfo *)[wrapper getTextInfo];  // Get the C++ object from the wrapper
        cppTextInfos.push_back(pTextInfo);  // Add the object to the vector
    }

    // Call the C++ method to analyze text data
    std::string resultString = analyzer->analyzeTextData(cppTextInfos);

    // Convert the result from a JSON string to an NSDictionary
    NSString *jsonString = [NSString stringWithUTF8String:resultString.c_str()];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"JSON Parsing Error: %@", error);  // Log any parsing errors
        return nil;
    }
    return resultDict;  // Return the parsed dictionary
}

/// Decrypts the provided input string using the underlying C++ analyzer.
///
/// - Parameter input: The string to decrypt.
/// - Returns: The decrypted string, or an empty string if decryption fails.
- (NSString *)decryptionDataWithInput:(NSString *)input {
    std::string cppInput = [input UTF8String];  // Convert Objective-C string to C++ string
    std::string result = analyzer->decryptionData(cppInput);  // Decrypt the input using the C++ method
    if (result.empty()) { return @""; }  // Return an empty string if the result is empty
    NSString *output = [NSString stringWithUTF8String:result.c_str()];  // Convert the result to an Objective-C string
    if (output == nil || [output length] == 0) { return @""; }
    // Clear sensitive data
    std::fill(cppInput.begin(), cppInput.end(), 0);
    std::fill(result.begin(), result.end(), 0);
    return output;  // Return the decrypted string
}

@end
