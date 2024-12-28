//
//  HiCardInfo.h
//  HiOCR
//
//  Created by netcanis on 4/30/24.
//

#ifndef HICARDINFO_H
#define HICARDINFO_H

#include <string>
#include <vector>

class HiCardInfo {
public:
    std::string issuingNetwork;
    std::vector<std::string> iinRanges;
    std::vector<int> length;
    std::string validation;
    bool isActive;

    HiCardInfo(const std::string& network, const std::vector<std::string>& ranges,
               const std::vector<int>& len, const std::string& val, bool active);

    HiCardInfo(const HiCardInfo& other);
    HiCardInfo& operator=(const HiCardInfo& other);
};

#endif // HICARDINFO_H
