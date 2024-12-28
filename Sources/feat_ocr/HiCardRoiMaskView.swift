//
//  HiCardRoiMaskView.swift
//  feat_ocr
//
//  Created by netcanis on 11/4/24.
//

import UIKit

/// A custom UIView that represents a mask view with a transparent ROI (Region of Interest) rectangle.
public class HiCardRoiMaskView: UIView {

    /// The rectangle that defines the ROI area.
    public var scanBox: CGRect = .zero {
        didSet {
            setNeedsDisplay() // Redraw the view when the scanBox changes.
        }
    }

    /// The dimming color for the background (default is semi-transparent black).
    public var dimColor: UIColor = UIColor.black.withAlphaComponent(0.5)

    /// The thickness of the corner lines.
    public var lineThickness: CGFloat = 4.0

    /// The color of the corner lines (default is red).
    public var cornerLineColor: UIColor = .red

    /// Draws the view’s contents.
    /// - Parameter rect: The area to draw in.
    public override func draw(_ rect: CGRect) {
        guard !scanBox.isEmpty else { return }

        // Obtain the current graphics context.
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        // Fill the entire view with the dimming color.
        dimColor.setFill()
        context.fill(rect)

        // Clear the scanBox area to make it transparent.
        context.setBlendMode(.clear)
        context.fill(scanBox)
        context.setBlendMode(.normal)

        // Set the stroke color for the corner lines.
        cornerLineColor.setStroke()
        let cornerLength: CGFloat = 40.0 // Length of the corner lines.

        // Draw the corner lines at each corner of the scanBox.
        drawCorner(context: context, startPoint: scanBox.origin, horizontalLength: cornerLength, verticalLength: cornerLength, thickness: lineThickness) // Top-left
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.maxX, y: scanBox.minY), horizontalLength: -cornerLength, verticalLength: cornerLength, thickness: lineThickness) // Top-right
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.minX, y: scanBox.maxY), horizontalLength: cornerLength, verticalLength: -cornerLength, thickness: lineThickness) // Bottom-left
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.maxX, y: scanBox.maxY), horizontalLength: -cornerLength, verticalLength: -cornerLength, thickness: lineThickness) // Bottom-right

        context.restoreGState()
    }

    /// Draws a corner line at the specified start point.
    /// - Parameters:
    ///   - context: The graphics context.
    ///   - startPoint: The starting point of the corner.
    ///   - horizontalLength: The horizontal length of the corner line.
    ///   - verticalLength: The vertical length of the corner line.
    ///   - thickness: The thickness of the corner lines.
    private func drawCorner(context: CGContext, startPoint: CGPoint, horizontalLength: CGFloat, verticalLength: CGFloat, thickness: CGFloat) {
        context.setLineWidth(thickness)
        context.beginPath()

        // Draw the horizontal line.
        context.move(to: startPoint)
        context.addLine(to: CGPoint(x: startPoint.x + horizontalLength, y: startPoint.y))
        context.strokePath()

        // Draw the vertical line.
        context.move(to: startPoint)
        context.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y + verticalLength))
        context.strokePath()
    }
}
