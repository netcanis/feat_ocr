//
//  HiLicenseManager.h
//  HiOCR
//
//  Created by netcanis on 4/30/24.
//

#ifndef HILICENSEMANAGER_H
#define HILICENSEMANAGER_H

#include <string> // For std::unique_ptr
#include <memory>

/**
 * @class HiLicenseManager
 * @brief Manages license key validation and expiration checks using HMAC encryption.
 */
class HiLicenseManager {
public:
    /**
     * @brief Constructs a license manager with a given serial key.
     * @param serialKey The license key to validate.
     */
    HiLicenseManager(const std::string& serialKey, const std::string& seed);
    ~HiLicenseManager();
    
    /**
     * @brief Validates the license key.
     * @return True if the license is valid, false otherwise.
     */
    bool validateLicense() const;

    /**
     * @brief Gets the expiration date of the license.
     * @return The expiration date in UTC format.
     */
    std::string getExpirationDate() const;

    /**
     * @brief Checks if the license is currently active.
     * @return True if the license is active, false otherwise.
     */
    bool isLicenseActive() const;

private:
    class Impl;  ///< Forward declaration for implementation details.
    Impl* pImpl; ///< Pointer to implementation details.
};

#endif // HILICENSEMANAGER_H
