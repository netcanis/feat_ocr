//
//  HiSHA256.hpp
//  HiOCR
//
//  Created by netcanis on 4/30/24.
//

#ifndef HISHA256_H
#define HISHA256_H

#include <string>
#include <memory> // for std::unique_ptr

/**
 * @class HiSHA256
 * @brief Provides SHA-256 hashing functionality.
 *
 * This class allows hashing data using the SHA-256 algorithm. It supports
 * incremental data updates through the `update` method and produces the
 * final hash using the `finalize` method.
 */
class HiSHA256 {
public:
    HiSHA256();
    ~HiSHA256();

    /**
     * @brief Updates the hash with new data.
     * @param data The input data to update the hash state.
     *
     * This method appends the given data to the internal buffer and processes
     * it in blocks of 64 bytes as per the SHA-256 algorithm.
     */
    void update(const std::string& data);

    /**
     * @brief Finalizes the hash computation and returns the result.
     * @return A string containing the final SHA-256 hash in hexadecimal format.
     *
     * This method performs the final padding and processes any remaining data
     * in the buffer, then returns the resulting hash as a hex string.
     */
    std::string finalize();

private:
    struct Impl;                   ///< Forward declaration of the implementation class.
    std::unique_ptr<Impl> pImpl;   ///< Smart pointer to implementation details.
};

#endif // HISHA256_H
