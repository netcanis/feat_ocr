//
//  HiCardScanner.swift
//  feat_ocr
//
//  Created by netcanis on 11/25/24.
//

import Foundation
import UIKit
import AVFoundation
import Combine
@preconcurrency import Vision
import HiOCRWrapper

/// A class for scanning credit card information.
public class HiCardScanner: NSObject, @unchecked Sendable {
    /// Singleton instance of the scanner.
    public static let shared = HiCardScanner()
    
    public var licenseKey: String = ""
    
    /// Indicates whether the scanner is currently active.
    private var isScanning: Bool = false

    /// Callback invoked with the scan results.
    private var scanCallback: ((HiCardResult) -> Void)?

    // UI components
    private var parentView: UIView?
    private var previewView: UIView?
    private var maskView: HiCardRoiMaskView?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var torchButton: UIButton?
    private var closeButton: UIButton?

    /// Defines the region of interest (ROI) for the scanner.
    private var roiRect: CGRect = .zero

    /// The screen size.
    private var screenSize: CGSize = .zero

    /// Analyzer used for OCR processing.
    private var analyzer: HiOCRAnalyzerWrapper?

    /// Frame count for image processing.
    private var count: UInt8 = 0 // 0~255

    /// Stores the last scanned image.
    public var lastScannedImage: UIImage?

    /// Starts the scanner.
    /// - Parameter callback: A closure to receive the scan results.
    public func start(withCallback callback: @escaping (HiCardResult) -> Void) {
        guard !isScanning else {
            print("Scanning is already in progress.")
            return
        }

        self.scanCallback = callback

        if hasRequiredPermissions() {
            setupAndStartScanning()
        } else {
            requestCameraPermissionAndStartScanning()
        }

        analyzer = HiOCRAnalyzerWrapper(scanType: 0, licenseKey: licenseKey)
    }

    /// Stops the scanner and cleans up resources.
    @MainActor
    public func stop() {
        guard isScanning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.resetUI()
            self?.isScanning = false
        }
    }

    /// Checks if the required camera permissions are granted.
    /// - Returns: A Boolean indicating whether the permissions are granted.
    public func hasRequiredPermissions() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// Toggles the device's torch (flashlight).
    /// - Parameter isOn: A Boolean indicating whether to turn the torch on or off.
    public func toggleTorch(isOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure torch: \(error)")
        }
    }

    /// Sets up the preview UI for the scanner.
    @MainActor
    private func setupPreviewUI() {
        parentView = UIViewController.hiTopMostViewController()?.view
        guard let parentView = parentView else {
            scanCallback?(HiCardResult(cardNumber: "", holderName: "", expiryDate: "", error: "Parent view setup is required."))
            stop()
            return
        }

        previewView = UIView(frame: parentView.bounds)
        previewView?.backgroundColor = .black
        parentView.addSubview(previewView!)

        previewLayer?.frame = previewView?.layer.bounds ?? UIScreen.main.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView?.layer.addSublayer(previewLayer!)
    }
    
    /// Sets up the mask and buttons for the scanning interface.
    @MainActor
    private func setupMaskAndButtons() {
        screenSize = UIScreen.main.bounds.size

        // The standard aspect ratio of a credit card is 1.586:1.
        let sideMargin: CGFloat = 10
        let boxWidth = previewView!.bounds.width - (sideMargin * 2)
        let boxHeight = boxWidth / 1.586
        roiRect = CGRect(x: sideMargin, y: (previewView!.bounds.height - boxHeight) / 2.0, width: boxWidth, height: boxHeight)

        maskView = HiCardRoiMaskView(frame: previewView!.bounds)
        maskView?.backgroundColor = .clear
        maskView?.scanBox = roiRect
        previewView?.addSubview(maskView!)

        let bundle = getFeatOcrBundle()
        torchButton = UIButton(type: .custom)
        torchButton?.setImage(UIImage(named: "flashOff", in: bundle, compatibleWith: nil), for: .normal)
        torchButton?.frame = CGRect(x: 20, y: 50, width: 30, height: 30)
        torchButton?.addTarget(self, action: #selector(self.onTorch), for: .touchUpInside)
        previewView?.addSubview(torchButton!)

        closeButton = UIButton(type: .custom)
        closeButton?.setImage(UIImage(named: "closeWhite", in: bundle, compatibleWith: nil), for: .normal)
        closeButton?.frame = CGRect(x: parentView!.bounds.width - 50, y: 50, width: 30, height: 30)
        closeButton?.addTarget(self, action: #selector(self.onClose), for: .touchUpInside)
        previewView?.addSubview(closeButton!)
    }

    /// Resets and cleans up the UI after scanning stops.
    private func resetUI() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.captureSession = nil
            self.previewLayer = nil
            self.parentView = nil
            self.previewView?.removeFromSuperview()
            self.previewView = nil
            self.torchButton = nil
            self.closeButton = nil
            self.maskView = nil
            print("Card scanning has been stopped.")
        }
    }

    /// Initializes the capture session and camera setup.
    @MainActor
    private func initialize() {
        guard !isScanning else { return }

        captureSession = AVCaptureSession()
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            scanCallback?(HiCardResult(cardNumber: "", holderName: "", expiryDate: "", error: "Failed to access the camera."))
            stop()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            captureSession.sessionPreset = .photo
            setFocusAtCenter(videoDevice: videoCaptureDevice)
        } else {
            scanCallback?(HiCardResult(cardNumber: "", holderName: "", expiryDate: "", error: "Failed to add input to capture session."))
            stop()
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            if let videoConnection = videoOutput.connection(with: .video) {
                videoConnection.videoOrientation = .portrait
            }
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.mwkg.HiCardScanner.videoProcessing"))
        } else {
            scanCallback?(HiCardResult(cardNumber: "", holderName: "", expiryDate: "", error: "Failed to add video output."))
            stop()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard previewLayer != nil else {
            scanCallback?(HiCardResult(cardNumber: "", holderName: "", expiryDate: "", error: "Failed to create preview layer."))
            stop()
            return
        }
    }

    /// Sets up and starts the scanning process.
    private func setupAndStartScanning() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.initialize() // Initialize camera and capture session
            self.setupPreviewUI() // Set up the camera preview
            self.setupMaskAndButtons() // Add UI elements like mask and buttons
            self.beginCaptureSession() // Start the capture session
        }
    }

    /// Requests camera permission from the user and starts scanning if granted.
    private func requestCameraPermissionAndStartScanning() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if granted {
                    self.setupAndStartScanning() // Proceed with scanning setup
                } else {
                    print("Camera permission is required.")
                }
            }
        }
    }

    /// Begins the camera capture session in the background.
    /// This method starts the session on a high-priority background thread.
    private func beginCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning() // Start capturing video frames
            self?.isScanning = true // Mark scanning as active
        }
    }

    /// Sets the focus point of the camera to the center of the screen.
    /// - Parameter videoDevice: The video capture device to configure.
    private func setFocusAtCenter(videoDevice: AVCaptureDevice) {
        guard videoDevice.isFocusPointOfInterestSupported else { return }
        do {
            try videoDevice.lockForConfiguration() // Lock the device for configuration
            let centerPoint = CGPoint(x: 0.5, y: 0.5) // Define center as the focus point
            videoDevice.focusPointOfInterest = centerPoint // Set the focus point
            videoDevice.focusMode = .continuousAutoFocus // Enable continuous auto-focus
            // Set focus range restriction to near for close objects
            if videoDevice.isAutoFocusRangeRestrictionSupported {
                videoDevice.autoFocusRangeRestriction = .near
            }
            videoDevice.unlockForConfiguration() // Unlock the device
        } catch {
            print("Failed to set focus point: \(error)") // Log errors
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension HiCardScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Could not get the pixel buffer, dropping frame")
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        // Crop the frame to the specified ROI (scanBox)
        let croppedImage = ciImage.hiCropToCameraCoordinates(roiRect: roiRect, screenSize: screenSize)
        // Resize cropped image (1586 x 1000)
        let resizedImage = croppedImage.hiResizeToFill(targetSize: CGSize(width: 1586.0, height: 1000.0))
        
        // Setup OCR request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error during text recognition: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text found")
                return
            }

            // Extract recognized text
            var recognizedTextInfos: [HiTextInfoWrapper] = []
            for observation in observations {
                if let candidate = observation.topCandidates(1).first, candidate.confidence >= 0.3 {
                    recognizedTextInfos.append(
                        HiTextInfoWrapper(
                            text: candidate.string,
                            bbox: observation.boundingBox
                        )
                    )
                }
            }

            // Analyze the recognized data
            guard let analyzedData = self.analyzer?.analyzeTextData(recognizedTextInfos), !analyzedData.isEmpty else { return }
            
            // Handle analyzed data
            Task { @MainActor [weak self] in
                guard let self = self, self.isScanning else { return }

                let card_number = analyzedData["card_number"] as? String ?? ""
                let holder_name = analyzedData["holder_name"] as? String ?? ""
                let expiry_month = analyzedData["expiry_month"] as? String ?? ""
                let expiry_year = analyzedData["expiry_year"] as? String ?? ""
                let issuing_network = analyzedData["issuing_network"] as? String ?? ""

                let cardNumber = self.analyzer?.decryptionData(withInput: card_number) ?? ""
                let holderName = self.analyzer?.decryptionData(withInput: holder_name) ?? ""
                let expirationMonth = self.analyzer?.decryptionData(withInput: expiry_month) ?? ""
                let expirationYear = self.analyzer?.decryptionData(withInput: expiry_year) ?? ""
                let issuingNetwork = self.analyzer?.decryptionData(withInput: issuing_network) ?? ""

                if !card_number.isEmpty {
                    let result = HiCardResult(
                        cardNumber: cardNumber,
                        holderName: holderName,
                        expiryDate:"\(expirationMonth)/\(expirationYear)",
                        issuingNetwork: issuingNetwork
                    )
                    self.scanCallback?(result)
                }
            }
        }

        // Configure OCR request
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false

        // Preprocess the image
        var preprocessedCIImage: CIImage = resizedImage
        if (count % 3 == 0) {
            imageProcessBlock: do {
                guard let outputUIImage = resizedImage.hiConvertToUIImage() else {
                    print("Failed to convert CIImage to UIImage")
                    break imageProcessBlock
                }
                self.lastScannedImage = outputUIImage

                let preprocessedUIImage = HiImageProcessor.processCardImage(outputUIImage)
                guard let outputCIImage = preprocessedUIImage.hiConvertToCIImage() else {
                    print("Failed to convert UIImage to CIImage")
                    break imageProcessBlock
                }
                preprocessedCIImage = outputCIImage
            }
        }

        // Perform OCR
        let handler = VNImageRequestHandler(ciImage: preprocessedCIImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error.localizedDescription)")
        }
        
        
        // 카운트를 증가 (자동으로 0~255 범위 순환)
        count = (count + 1) % 255
    }
}

// MARK: - Events
extension HiCardScanner {
    /// Toggles the device's torch (flashlight) on or off.
    /// Updates the torch button image to reflect the current state.
    @MainActor
    @objc private func onTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        let isTorchOn = device.torchMode == .on
        toggleTorch(isOn: !isTorchOn)

        // Update the torch button image based on the current torch state
        let bundle = getFeatOcrBundle()
        let torchImageName = isTorchOn ? "flashOff" : "flashOn"
        torchButton?.setImage(UIImage(named: torchImageName, in: bundle, compatibleWith: nil), for: .normal)
    }

    /// Stops the scanning process and closes the scanner.
    /// Typically invoked when the user taps the close button.
    @MainActor
    @objc private func onClose() {
        stop()
    }
}

// MARK: - Custom UI Integration
extension HiCardScanner {
    /// Starts the card scanner with a custom preview view and a specified region of interest (ROI).
    ///
    /// - Parameters:
    ///   - previewView: The `UIView` where the camera preview will be displayed.
    ///   - roi: The `CGRect` defining the region of interest for scanning.
    ///   - callback: A closure that handles the scanning result.
    public func start(previewView: UIView, roi: CGRect, withCallback callback: @escaping (HiCardResult) -> Void) {
        // Ensure the scanner is not already running
        guard !isScanning else {
            print("Scanning is already in progress.")
            return
        }

        self.scanCallback = callback

        // Check permissions and start scanning
        if hasRequiredPermissions() {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.previewView = previewView // Set the provided preview view
                self.initialize()
                self.setupCustomPreviewUI(previewView, roi)
                self.beginCaptureSession()
            }
        } else {
            // Request camera permissions and start scanning if granted
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if granted {
                        self.previewView = previewView // Set the provided preview view
                        self.initialize()
                        self.setupCustomPreviewUI(previewView, roi)
                        self.beginCaptureSession()
                    } else {
                        print("Camera access is required.")
                    }
                }
            }
        }
    }

    /// Configures the custom preview view and region of interest (ROI) for scanning.
    ///
    /// - Parameters:
    ///   - previewView: The view where the camera preview will be displayed.
    ///   - roi: The region of interest for scanning.
    @MainActor
    public func setupCustomPreviewUI(_ previewView: UIView?, _ roi: CGRect?) {
        // Ensure the view's layout is updated
        previewView?.layoutIfNeeded()

        // Configure the preview layer
        previewLayer?.frame = previewView?.layer.bounds ?? UIScreen.main.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView?.layer.addSublayer(previewLayer!)

        // Configure and add the ROI mask view
        maskView = HiCardRoiMaskView(frame: previewView!.bounds)
        maskView?.backgroundColor = .clear
        maskView?.scanBox = roi!
        previewView?.addSubview(maskView!)
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    /// Returns the top-most view controller in the app's hierarchy.
    ///
    /// - Returns: The top-most `UIViewController` or `nil` if it cannot be determined.
    static func hiTopMostViewController() -> UIViewController? {
        // For iOS 15 and later: use UIWindowScene's windows
        guard let keyWindow = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            return nil
        }
        return UIViewController.hiGetTopViewController(from: rootViewController)
    }

    /// Recursively retrieves the top-most view controller from a given root view controller.
    ///
    /// - Parameter viewController: The root view controller to start from.
    /// - Returns: The top-most `UIViewController`.
    private static func hiGetTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return hiGetTopViewController(from: presentedViewController)
        }
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return hiGetTopViewController(from: visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return hiGetTopViewController(from: selectedViewController)
        }
        return viewController
    }
}


extension UIImage {
    func hiConvertToCIImage() -> CIImage? {
        // 1. UIImage에서 이미 CIImage를 가져올 수 있는 경우
        if let ciImage = self.ciImage {
            return ciImage
        }

        // 2. UIImage에서 CGImage를 가져와서 CIImage로 변환
        if let cgImage = self.cgImage {
            return CIImage(cgImage: cgImage)
        }

        // 변환 실패 시 nil 반환
        return nil
    }
}

extension CIImage {
    /// Converts the `CIImage` to a `UIImage`.
    /// - Returns: A `UIImage` representation of the `CIImage`.
    func hiConvertToUIImage() -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(self, from: self.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Rotates the image by the specified degrees.
    /// - Parameter degrees: The rotation angle in degrees.
    /// - Returns: A new rotated `CIImage`.
    func hiRotate(by degrees: CGFloat) -> CIImage {
        guard degrees != 0.0 else { return self }

        let radians = degrees * .pi / 180
        let originalWidth = self.extent.width
        let originalHeight = self.extent.height

        let transform = CGAffineTransform(translationX: originalWidth / 2, y: originalHeight / 2)
            .rotated(by: radians)
            .translatedBy(x: -originalWidth / 2, y: -originalHeight / 2)

        return self.transformed(by: transform)
    }

    /// Crops the image to a region defined by camera coordinates.
    /// - Parameters:
    ///   - roiRect: The region of interest in screen coordinates.
    ///   - screenSize: The size of the screen.
    /// - Returns: A cropped `CIImage`.
    func hiCropToCameraCoordinates(roiRect: CGRect, screenSize: CGSize) -> CIImage {
        let cameraWidth = self.extent.width
        let cameraHeight = self.extent.height

        let widthScale = cameraWidth / screenSize.width
        let heightScale = cameraHeight / screenSize.height
        let minScale = min(widthScale, heightScale)

        let cropHeight = roiRect.height * minScale
        let cropWidth = cropHeight * 1.586
        let cropOriginX = (cameraWidth - cropWidth) / 2
        let cropOriginY = cameraHeight - (roiRect.origin.y + roiRect.height) * minScale

        let scaledScanBox = CGRect(
            x: cropOriginX,
            y: cropOriginY,
            width: cropWidth,
            height: cropHeight
        )

        return self.cropped(to: scaledScanBox)
    }

    /// Resizes the image to fit the specified target size while maintaining aspect ratio.
    /// - Parameter targetSize: The target size for the image.
    /// - Returns: A resized `CIImage`.
    func hiResizeToFit(targetSize: CGSize) -> CIImage {
        let originalWidth = self.extent.width
        let originalHeight = self.extent.height
        let widthRatio = targetSize.width / originalWidth
        let heightRatio = targetSize.height / originalHeight
        let scale = min(widthRatio, heightRatio)

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let resizedImage = self.transformed(by: transform)
        let centeredX = (targetSize.width - resizedImage.extent.width) / 2.0
        let centeredY = (targetSize.height - resizedImage.extent.height) / 2.0

        return resizedImage.transformed(by: CGAffineTransform(translationX: centeredX, y: centeredY))
    }

    /// Resizes the image to fill the specified target size while maintaining aspect ratio.
    /// - Parameter targetSize: The target size for the image.
    /// - Returns: A resized and cropped `CIImage`.
    func hiResizeToFill(targetSize: CGSize) -> CIImage {
        let originalWidth = self.extent.width
        let originalHeight = self.extent.height
        let widthScale = targetSize.width / originalWidth
        let heightScale = targetSize.height / originalHeight
        let scale = max(widthScale, heightScale)

        let scaledImage = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let scaledExtent = scaledImage.extent

        let cropOriginX = max((scaledExtent.width - targetSize.width) / 2.0, 0)
        let cropOriginY = max((scaledExtent.height - targetSize.height) / 2.0, 0)
        let cropRect = CGRect(x: cropOriginX, y: cropOriginY, width: targetSize.width, height: targetSize.height)

        // Crop and return the final image
        guard scaledExtent.contains(cropRect) else {
            return scaledImage
        }
        return scaledImage.cropped(to: cropRect)
    }
}

