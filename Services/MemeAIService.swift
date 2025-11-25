//
//  MemeAIService.swift
//  InstaMeme
//
//  Uses Vision to analyze the image and a small text model (Llama)
//  to generate meme captions. If the text model fails, we fall back
//  to Vision labels so the UI still works.
//

import Foundation
import UIKit
import Vision

enum AIServiceError: Error {
    case invalidImage
}

final class MemeAIService {

    static let shared = MemeAIService()

    private init() {}

    /// High-level API used by CameraMemeView.
    ///
    /// 1. Uses Vision to classify the image (top labels).
    /// 2. Asks MemeTextModelService (Llama) to turn labels into captions.
    /// 3. If the LLM fails, falls back to returning the labels themselves.
    func suggestCaptions(for image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw AIServiceError.invalidImage
        }

        // 1. Get top labels via Vision
        let labels: [String]
        do {
            labels = try await classifyTopLabels(from: cgImage)
        } catch {
            print("Vision classification failed: \(error)")
            // If Vision fails, just give a generic suggestion.
            return ["(Couldn't analyze image; add your own caption!)"]
        }

        if labels.isEmpty {
            return ["(Couldn't recognize anything; add your own caption!)"]
        }

        // 2. Ask the text model to turn labels into meme captions.
        do {
            let captions = try await MemeTextModelService.shared.generateCaptions(forLabels: labels)
            return captions
        } catch {
            // 3. Fallback: LLM not available or failed → just use labels.
            print("Text model failed, falling back to labels: \(error)")
            return labels
        }
    }

    // MARK: - Vision helpers

    private func classifyTopLabels(from cgImage: CGImage) async throws -> [String] {
        let observations = try await classifyImage(cgImage: cgImage)

        let top = observations
            .filter { $0.confidence >= 0.1 }  // tweak as needed
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)

        return top.map { $0.identifier }
    }

    private func classifyImage(cgImage: CGImage) async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNClassifyImageRequest()

                do {
                    try handler.perform([request])
                    let results = request.results ?? []
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

