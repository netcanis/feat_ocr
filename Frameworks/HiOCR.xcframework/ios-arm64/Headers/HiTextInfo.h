//
//  HiTextInfo.h
//  HiOCR
//
//  Created by netcanis on 4/30/24.
//

#ifndef HITEXTINFO_H
#define HITEXTINFO_H

#include <string>

struct HiRect {
    double x, y, width, height;
};

class HiTextInfo {
public:
    HiTextInfo(const std::string& str, const HiRect& rect);
    HiTextInfo& operator=(const HiTextInfo& other);
    std::string getText() const;
    HiRect getBBox() const;

private:
    std::string text;
    HiRect bbox;
};

#endif // HITEXTINFO_H
