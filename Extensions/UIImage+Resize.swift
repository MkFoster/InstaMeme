//
//  UIImage+Resize.swift
//  InstaMeme
//
//  Created by Mark Foster on 11/25/25.
//

import UIKit

extension UIImage {

    /// Returns a resized copy of the image preserving aspect ratio.
    /// If the image is already under the max dimension, it returns self.
    func resized(maxDimension: CGFloat = 1080) -> UIImage {
        let width = size.width
        let height = size.height

        guard max(width, height) > maxDimension else {
            return self // Already small enough
        }

        let scale = maxDimension / max(width, height)
        let newSize = CGSize(width: width * scale, height: height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

