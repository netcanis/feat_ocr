# **feat_ocr**

A **Swift Package** for Optical Character Recognition (OCR) on iOS, focusing on real-time scanning of credit card information with customizable UI support.

---

## **Overview**

`feat_ocr` is a lightweight Swift package that enables:
- Scanning and extracting credit card information in real-time.
- Image preprocessing to enhance OCR accuracy.
- Integration with Vision and Core Image frameworks.
- Customizable UI overlays for scanning regions.

This module is compatible with **iOS 16 and above** and designed for seamless integration via **Swift Package Manager (SPM)**.

---

## **Features**

- ✅ **Real-time Credit Card Scanning**: Detect and extract card number, holder name, and expiry date.
- ✅ **Image Preprocessing**: Enhance recognition accuracy with noise reduction and text highlighting.
- ✅ **Customizable UI**: Easily overlay scanning regions with your design.
- ✅ **Torch Control**: Enable flashlight for low-light scanning environments.

---

## **Requirements**

| Requirement     | Minimum Version         |
|------------------|-------------------------|
| **iOS**         | 16.0                    |
| **Swift**       | 5.7                     |
| **Xcode**       | 14.0                    |

---

## **Installation**

### **Swift Package Manager (SPM)**

1. Open your project in **Xcode**.
2. Navigate to **File > Add Packages...**.
3. Enter the repository URL:  https://github.com/netcanis/feat_ocr.git
4. Select the version and integrate the package into your project.

---

## **Usage**

### **1. Start Card Scanning**

To start scanning for credit card details:

```swift
import feat_ocr

HiCardScanner.shared.start { result in
    print("Card Number: \(result.cardNumber ?? "N/A")")
    print("Expiry Date: \(result.expiryDate ?? "N/A")")
    print("Holder Name: \(result.holderName ?? "N/A")")
}
```

### **2. Stop Card Scanning**

Stop scanning when it’s no longer needed:

```swift
HiCardScanner.shared.stop()
```

### **3. Custom UI for Card Scanning**

You can provide your own preview view and scan region overlay:

```swift
import feat_ocr

let cardScanner = HiCardScanner()
let customPreviewView = UIView() // Replace with your preview view
let scanBox = CGRect(x: 50, y: 100, width: 300, height: 190)

cardScanner.start(previewView: customPreviewView, roi: scanBox) { result in
    print("Card Number: \(result.cardNumber ?? "N/A")")
    cardScanner.stop()
}
```

### **4. Set License Key**

Before starting the scanner, you must configure the license key to enable the package:

```swift
import feat_ocr

HiCardScanner.shared.licenseKey = "5172842b555966c14149f47505756c48c5f5394178f18b0cffb3dbd11e69898b|1750331753"
```

---

## **HiCardResult**

The scan results are provided in the HiQrResult class. Here are its properties:

| Property          | Type      | Description                     |
|-------------------|-----------|---------------------------------|
| cardNumber        | String?   | The scanned credit card number. |
| holderName        | String?   | The name of the cardholder.     |
| expiryDate        | String?   | The expiry date in MM/YY format.|
| issuingNetwork    | String?   | The issuing card network.       |
| error             | String    | Error message, if any.          |

---

## **Permissions**

Add the following key to your Info.plist file to request camera permission:

```
<key>NSCameraUsageDescription</key>
<string>We use the camera to scan credit cards.</string>
```

---

## **Example UI**

To display a SwiftUI view for managing card scans:

```swift
import SwiftUI
import feat_ocr

public struct HiCardNumberListView: View {
    @State private var numbers: [HiCardResult] = []

    public var body: some View {
        VStack {
            List(numbers, id: \.cardNumber) { result in
                VStack(alignment: .leading) {
                    Text("Card Number: \(result.cardNumber ?? "N/A")")
                    Text("Expiry Date: \(result.expiryDate ?? "N/A")")
                    Text("Holder Name: \(result.holderName ?? "N/A")")
                }
            }
            .navigationTitle("Card Scans")
            .onAppear(perform: startCardScan)
            .onDisappear { HiCardScanner.shared.stop() }
        }
    }

    private func startCardScan() {
            HiCardScanner.shared.licenseKey = "5172842b555966c14149f47505756c48c5f5394178f18b0cffb3dbd11e69898b|1750331753"
        HiCardScanner.shared.start { result in
            DispatchQueue.main.async {
                if let index = numbers.firstIndex(where: { $0.cardNumber == result.cardNumber }) {
                    numbers[index] = result
                } else {
                    numbers.append(result)
                }
            }
        }
    }
}

#Preview {
    HiCardNumberListView()
}
```

---

## **License**

feat_qr is available under the Apache License 2.0. See the LICENSE file for details.

---

## **Contributing**

Contributions are welcome! To contribute:

1. Fork this repository.
2. Create a feature branch:
```
git checkout -b feature/your-feature
```
3. Commit your changes:
```
git commit -m "Add feature: description"
```
4. Push to the branch:
```
git push origin feature/your-feature
```
5. Submit a Pull Request.

---

## **Author**

### **netcanis**
GitHub: https://github.com/netcanis

---
