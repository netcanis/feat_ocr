//
//  HiCardNumberListView.swift
//  feat_ocr
//
//  Created by netcanis on 11/30/24.
//

import SwiftUI

/// View for displaying a list of scanned card numbers.
/// - Shows the date of the scan and card number details in a list format.
public struct HiCardNumberListView: View {
    /// Array to store the results of scanned card numbers.
    @State private var numbers: [HiCardResult] = [] // Consider refactoring to a more structured data type.
    @Environment(\.dismiss) private var dismiss // Environment variable to handle view dismissal.

    // Initializer
    public init() {}

    public var body: some View {
        NavigationView {
            VStack {
                // Display a message if no card numbers are available.
                if numbers.isEmpty {
                    Text("No Card Numbers Scanned")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Display the scanned card numbers in a list.
                    List(numbers, id: \.cardNumber) { result in
                        VStack(alignment: .leading) {
                            Text("Card Number: \(result.cardNumber ?? "")")
                                .font(.headline)
                            Text("Expiry Date: \(result.expiryDate ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Card Holder: \(result.holderName ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Card Number Scans") // Set the navigation title.
            .navigationBarTitleDisplayMode(.inline) // Align the title in the center.
            .onAppear(perform: startCardScan) // Start scanning when the view appears.
            .onDisappear { HiCardScanner.shared.stop() } // Stop scanning when the view disappears.
        }
    }

    /// Starts scanning for card numbers.
    /// - Updates the list if the card number is already present.
    /// - Adds a new card number to the list if it's not a duplicate.
    private func startCardScan() {
        HiCardScanner.shared.licenseKey = "9597cbfa0d43a47b3e48842bb1025b409bf8ab3919a89d44acaab17b08bebd14|1737361504"
        HiCardScanner.shared.start { result in
            DispatchQueue.main.async {
                if let index = numbers.firstIndex(where: { $0.cardNumber == result.cardNumber }) {
                    // Update the existing card number if found.
                    numbers[index] = result
                    print("Updated Card Number: \(result.cardNumber ?? "")")
                } else {
                    // Add a new card number to the list.
                    numbers.append(result)
                    print("Added new Card Number: \(result.cardNumber ?? "")")
                }

                // Automatically stop scanning if a valid card number and expiry date are found.
                let cardNumber = result.cardNumber ?? ""
                let expiryDate = result.expiryDate ?? ""
                if !cardNumber.isEmpty && !expiryDate.isEmpty {
                    HiCardScanner.shared.stop()
                }
            }
        }
    }
}

#Preview {
    HiCardNumberListView()
}
