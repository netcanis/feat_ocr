//
//  HiOCRAnalyzer.h
//  HiOCR
//
//  Created by netcanis on 4/30/24.
//

#ifndef HIOCRANALYZER_H
#define HIOCRANALYZER_H

#include <string>
#include <memory>
#include <vector>

class HiTextInfo;
class HiOCRAnalyzer {
public:
    explicit HiOCRAnalyzer(long scanType, const std::string &licenseKey);
    ~HiOCRAnalyzer();
    HiOCRAnalyzer(const HiOCRAnalyzer& other);
    HiOCRAnalyzer& operator=(const HiOCRAnalyzer& other);
    std::string analyzeTextData(const std::vector<HiTextInfo*>& textInfos);
    std::string decryptionData(const std::string &input);

private:
    struct Impl;
    std::unique_ptr<Impl> pImpl;
};

#endif // HIOCRANALYZER_H
