//
//  MemeTextModelService.swift
//  InstaMeme
//
//  Uses MLX Llama-3.2-1B-Instruct-4bit to turn Vision labels into meme captions.
//

import Foundation

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
#endif

enum MemeTextModelError: Error {
    case mlxPackagesMissing
    case modelNotLoaded
}

/// Singleton that wraps the small LLM used for meme caption generation.
@MainActor
final class MemeTextModelService {

    static let shared = MemeTextModelService()

    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private var container: ModelContainer?
    private var isLoading = false
    #endif

    private init() {}

    // MARK: - Public API

    /// Ensure the Llama model is loaded and ready.
    func prepareIfNeeded() async throws {
        #if !(canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon))
        throw MemeTextModelError.mlxPackagesMissing
        #else
        if container != nil || isLoading { return }

        isLoading = true
        defer { isLoading = false }

        // Optional: limit GPU cache for mobile
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

        // Configure Llama-3.2-1B-Instruct-4bit from mlx-community
        let config = ModelConfiguration(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            defaultPrompt: "You are a meme caption generator."
        )

        print("Loading \(config.id)...")

        container = try await LLMModelFactory.shared.loadContainer(
            configuration: config
        ) { progress in
            let percent = Int(progress.fractionCompleted * 100)
            print("Llama download: \(percent)%")
        }

        if let container {
            let numParams = await container.perform { context in
                context.model.numParameters()
            }

            print("Llama model loaded. Params: \(numParams / (1024 * 1024))M")
        }
        #endif
    }


    /// Generate 2–3 meme-style captions given a set of labels from Vision.
    func generateCaptions(forLabels labels: [String]) async throws -> [String] {
        #if !(canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon))
        throw MemeTextModelError.mlxPackagesMissing
        #else
        try await prepareIfNeeded()
        guard let container else { throw MemeTextModelError.modelNotLoaded }

        let labelText = labels.joined(separator: ", ")

        let prompt = """
        You are a meme caption generator.

        Objects or concepts detected in the image:
        \(labelText)

        Your task:
        - Generate EXACTLY 3 short, punchy meme captions for this image.
        - Each caption must be under 80 characters.
        - Make them casual, internet-meme style, but not offensive.
        - IMPORTANT: Start immediately with the numbered list.
        - Do NOT explain your reasoning or say things like "I need to think".

        Format:
        1) first caption
        2) second caption
        3) third caption
        """

        let parameters = GenerateParameters(
            temperature: 0.8,
            topP: 0.95,
            repetitionPenalty: 1.1,
            repetitionContextSize: 40
        )

        // Preferred modern MLX pattern: perform(_:) with ModelContext
        let result = try await container.perform { context in
            // Turn the prompt into an LMInput
            let input = try await context.processor.prepare(input: .init(prompt: prompt))

            // Generate tokens → result with .output already decoded
            return try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            ) { tokens in
                // Simple safety limit: stop if we ever went wild
                if tokens.count >= 128 {
                    return .stop
                } else {
                    return .more
                }
            }
        }

        let text = result.output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try numbered list first
        let parsed = parseNumberedList(from: text)
        if !parsed.isEmpty {
            return parsed
        }

        // Fallback: pick short lines, or labels if needed
        let fallback = fallbackCaptions(from: text, labels: labels)
        return fallback
        #endif
    }

    
    // MARK: - Parsing helpers

    /// Parse "1) foo\n2) bar\n3) baz" into ["foo", "bar", "baz"].
    private func parseNumberedList(from text: String) -> [String] {
        var results: [String] = []

        let lines = text.components(separatedBy: .newlines)
        let pattern = #"^\s*\d+[\).\-\:]\s*(.+)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            if let match = regex.firstMatch(in: line, options: [], range: range),
               match.numberOfRanges >= 2 {
                let captionRange = match.range(at: 1)
                if captionRange.location != NSNotFound,
                   let swiftRange = Range(captionRange, in: line) {
                    let caption = String(line[swiftRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !caption.isEmpty {
                        results.append(caption)
                    }
                }
            }
        }

        return results
    }

    /// Fallback: grab up to 3 short, non-empty lines; or return the labels.
    private func fallbackCaptions(from text: String, labels: [String]) -> [String] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Prefer lines that are not super long (heuristic)
        let shortLines = lines.filter { $0.count <= 120 }

        if !shortLines.isEmpty {
            return Array(shortLines.prefix(3))
        }

        // Absolute last resort: just echo labels as "captions"
        if !labels.isEmpty {
            return labels
        }

        // If even labels are empty, return something minimal so UI still works
        return ["(No meme ideas – add your own text!)"]
    }
}

