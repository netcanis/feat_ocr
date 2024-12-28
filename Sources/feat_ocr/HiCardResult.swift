//
//  HiCardResult.swift
//  feat_ocr
//
//  Created by netcanis on 12/17/24.
//

import Foundation

/// Represents the result of a credit card scan.
public class HiCardResult {
    /// The scanned card number.
    public var cardNumber: String?

    /// The name of the cardholder.
    public var holderName: String?

    /// The expiration date of the card (in MM/YY format).
    public var expiryDate: String?

    /// The credit card issuing network.
    public var issuingNetwork: String?

    /// Error details, if any.
    public let error: String

    /// Initializes a new instance of the credit card scan result.
    /// - Parameters:
    ///   - cardNumber: The scanned card number.
    ///   - holderName: The name of the cardholder.
    ///   - expiryDate: The expiration date of the card.
    ///   - issuingNetwork: The credit card issuing network.
    ///   - error: Details of any error that occurred during the scan.
    public init(cardNumber: String?, holderName: String?, expiryDate: String?, issuingNetwork: String = "", error: String = "") {
        self.cardNumber = cardNumber
        self.holderName = holderName
        self.expiryDate = expiryDate
        self.issuingNetwork = issuingNetwork
        self.error = error
    }
}
