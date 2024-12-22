//
//  HiPreProcessImage.swift
//  feat_ocr_engine
//
//  Created by netcanis on 12/13/24.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import feat_util

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
        // 1. Convert to Grayscale
        guard let grayscaleImage = image.hiApplyGrayscale() else {
            return nil
        }
        
        // 2. Apply Gaussian Blur for Noise Reduction
        guard let noiseReducedImage = grayscaleImage.hiApplyGaussianBlur(radius: 2.0) else {
            return nil
        }
        
        // 3. Apply Thresholding to Emphasize Text
        guard let thresholdedImage = noiseReducedImage.hiEmphasizeTextUsingColorMatrix(threshold: 1.8) else {
            return nil
        }
        
        // 4. Adjust Brightness and Contrast
        guard let finalImage = thresholdedImage.hiAnalyzeAndAdjust() else {
            return nil
        }
        
        return finalImage
    }
}
