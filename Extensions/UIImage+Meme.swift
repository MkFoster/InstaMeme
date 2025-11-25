//
//  UIImage+Meme.swift
//  InstaMeme
//
//  Created by Mark Foster on 11/25/25.
//
import UIKit

extension UIImage {

    /// Returns a new image with top/bottom meme text rendered onto it.
    /// Text is uppercased, white, and drawn over black bars.
    func withMemeText(topText: String, bottomText: String) -> UIImage {
        let imageSize = size

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { _ in
            // Draw base image
            self.draw(in: CGRect(origin: .zero, size: imageSize))

            let context = UIGraphicsGetCurrentContext()
            context?.setAllowsAntialiasing(true)
            context?.setShouldAntialias(true)

            // Common text attributes
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let baseFontSize = imageSize.height * 0.06
            let font = UIFont.systemFont(ofSize: baseFontSize, weight: .heavy)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]

            let horizontalPadding: CGFloat = 32
            let barHeight = imageSize.height * 0.18

            // Helper to draw a bar + centered text in a rect
            func drawMemeLine(text: String, in rect: CGRect) {
                guard !text.isEmpty else { return }

                // Draw black bar
                UIColor.black.setFill()
                context?.fill(rect)

                let upper = text.uppercased() as NSString

                let textRect = rect.insetBy(dx: horizontalPadding, dy: rect.height * 0.2)
                upper.draw(in: textRect, withAttributes: attributes)
            }

            // Top text bar
            if !topText.isEmpty {
                let topBarRect = CGRect(
                    x: 0,
                    y: 0,
                    width: imageSize.width,
                    height: barHeight
                )
                drawMemeLine(text: topText, in: topBarRect)
            }

            // Bottom text bar
            if !bottomText.isEmpty {
                let bottomBarRect = CGRect(
                    x: 0,
                    y: imageSize.height - barHeight,
                    width: imageSize.width,
                    height: barHeight
                )
                drawMemeLine(text: bottomText, in: bottomBarRect)
            }
        }
    }
}

