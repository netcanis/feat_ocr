//
//  HiPreProcessImage.swift
//  feat_ocr_engine
//
//  Created by netcanis on 12/13/24.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// A utility class for preprocessing images for text recognition.
final class HiPreProcessImage {
    // MARK: - Singleton Instance
    /// Shared instance of `HiPreProcessImage` for easy access.
    nonisolated(unsafe) static let shared = HiPreProcessImage()
    private init() {}

    // MARK: - Public Method

    /// Preprocesses an image for text recognition.
    ///
    /// The processing steps include:
    /// 1. Grayscale conversion and contrast adjustment.
    /// 2. Gaussian blur for noise reduction.
    /// 3. Thresholding to emphasize text.
    /// 4. Brightness and contrast adjustment based on image analysis.
    ///
    /// - Parameter image: The input `CIImage` to preprocess.
    /// - Returns: A `CIImage` processed for optimal text recognition, or `nil` if processing fails.
    func preprocessForTextRecognition(image: CIImage) -> CIImage? {
        // 1. Grayscale, Contrast, Brightness
        guard let grayImage = applyGrayscale(image: image) else {
            return nil
        }
        
        // 2. Gaussian Blur (Noise Reduction)
        guard let blurImage = applyGaussianBlur(image: grayImage, radius: 2.0) else {
            return nil
        }
        
        // 3. Thresholding (Emphasizing Text Using CIColorMatrix)
        guard let emphasizedImage = emphasizeTextUsingColorMatrix(image: blurImage, threshold: 1.8) else {
            return nil
        }
        
        // 4. Brightness and Contrast Adjustment
        guard let analyzedImage = analyzeImage(emphasizedImage) else {
            return nil
        }
        
        return analyzedImage
    }

    // MARK: - Private Methods

    /// Converts the image to grayscale.
    private func applyGrayscale(image: CIImage) -> CIImage? {
        let grayscaleFilter = CIFilter(name: "CIColorControls")
        grayscaleFilter?.setValue(image, forKey: kCIInputImageKey)
        grayscaleFilter?.setValue(0.0, forKey: kCIInputSaturationKey) // Remove colors (grayscale)
        grayscaleFilter?.setValue(1.0, forKey: kCIInputContrastKey)   // Maintain default contrast
        grayscaleFilter?.setValue(0.0, forKey: kCIInputBrightnessKey) // Maintain default brightness
        return grayscaleFilter?.outputImage
    }

    /// Applies a Gaussian blur to reduce noise in the image.
    ///
    /// - Parameters:
    ///   - image: The input image.
    ///   - radius: The blur radius (default is 2.0).
    /// - Returns: A blurred `CIImage`.
    func applyGaussianBlur(image: CIImage, radius: Double = 2.0) -> CIImage? {
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            print("Failed to create CIGaussianBlur filter")
            return image
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        // Crop the output image to the original image extent
        if let blurredImage = filter.outputImage {
            return blurredImage.cropped(to: image.extent)
        }
        return image
    }

    /// Emphasizes text using a color matrix for thresholding.
    ///
    /// - Parameters:
    ///   - image: The input image.
    ///   - threshold: The threshold value to emphasize text (default is 0.5).
    /// - Returns: A thresholded `CIImage`.
    func emphasizeTextUsingColorMatrix(image: CIImage, threshold: Float = 0.5) -> CIImage? {
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else {
            print("Failed to create CIColorMatrix filter")
            return image
        }

        colorMatrixFilter.setValue(image, forKey: kCIInputImageKey)

        let scaleValue = 1.0 / (1.0 - CGFloat(threshold))
        let biasValue = -CGFloat(threshold) * scaleValue

        // Set channel transformation vectors
        let scaleVector = CIVector(x: scaleValue, y: scaleValue, z: scaleValue, w: 0)
        let biasVector = CIVector(x: biasValue, y: biasValue, z: biasValue, w: 0)

        // Apply the same transformation to R, G, and B channels
        colorMatrixFilter.setValue(scaleVector, forKey: "inputRVector")
        colorMatrixFilter.setValue(scaleVector, forKey: "inputGVector")
        colorMatrixFilter.setValue(scaleVector, forKey: "inputBVector")

        // Set brightness offset
        colorMatrixFilter.setValue(biasVector, forKey: "inputBiasVector")

        // Maintain alpha channel
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

        return colorMatrixFilter.outputImage
    }

    /// Analyzes the image to calculate contrast and brightness adjustments.
    ///
    /// - Parameter image: The input image.
    /// - Returns: A tuple containing the contrast factor and brightness offset, or `nil` if analysis fails.
    func analyzeImage(_ image: CIImage) -> CIImage? {
        let meanFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: image,
            kCIInputExtentKey: CIVector(cgRect: image.extent)
        ])

        guard let outputImage = meanFilter?.outputImage else {
            print("Failed to apply mean filter")
            return image
        }

        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4) // RGBA 8-bit
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let r = Int(bitmap[0])
        let g = Int(bitmap[1])
        let b = Int(bitmap[2])

        let brightness = 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
        let isBrightBackground = brightness > 192
        let contrastFactor = calculateContrastFactor(minBrightness: Int(brightness), maxBrightness: 255)
        let brightnessOffset = calculateBrightnessOffset(averageBrightness: brightness, isBrightBackground: isBrightBackground)

        let adjustedImage = adjustContrastAndBrightness(
            image,
            contrastFactor: contrastFactor,
            brightnessOffset: brightnessOffset
        ) ?? image
        
        return isBrightBackground ? invertColors(image: adjustedImage) : adjustedImage
    }

    /// Adjusts the contrast and brightness of the image.
    ///
    /// - Parameters:
    ///   - image: The input image.
    ///   - contrastFactor: The factor by which to adjust contrast.
    ///   - brightnessOffset: The offset by which to adjust brightness.
    /// - Returns: A `CIImage` with adjusted contrast and brightness, or `nil` if adjustment fails.
    private func adjustContrastAndBrightness(_ image: CIImage, contrastFactor: Float, brightnessOffset: Int) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(contrastFactor, forKey: "inputContrast")
        filter?.setValue(Float(brightnessOffset) / 255.0, forKey: "inputBrightness")
        return filter?.outputImage
    }

    /// Calculates the contrast factor based on brightness range.
    private func calculateContrastFactor(minBrightness: Int, maxBrightness: Int) -> Float {
        let range = maxBrightness - minBrightness
        return range > 0 ? Float(255) / Float(range) : 1.0
    }

    /// Calculates the brightness offset based on average brightness and background brightness.
    private func calculateBrightnessOffset(averageBrightness: Double, isBrightBackground: Bool) -> Int {
        return isBrightBackground ? -15 : Int(128 - averageBrightness)
    }
    
    private func invertColors(image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(image, forKey: kCIInputImageKey)
        return filter?.outputImage ?? image
    }
}
