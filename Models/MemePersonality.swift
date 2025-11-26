//
//  MemePersonality.swift
//  InstaMeme
//
//  Created by Mark Foster on 11/25/25.
//

import Foundation

enum MemePersonality: String, CaseIterable, Identifiable, Codable {
    case relatable
    case sarcastic
    case wholesome
    case chaotic
    case corporate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relatable: return "Relatable"
        case .sarcastic: return "Sarcastic"
        case .wholesome: return "Wholesome"
        case .chaotic: return "Chaotic"
        case .corporate: return "Corporate"
        }
    }

    /// Extra context to guide the LLM style.
    var stylePrompt: String {
        switch self {
        case .relatable:
            return "Make it feel like a relatable, everyday meme that people see on social media."
        case .sarcastic:
            return "Use dry, sarcastic humor. Subtle but obviously snarky."
        case .wholesome:
            return "Keep it positive, kind, and wholesome. No negativity, no roasting."
        case .chaotic:
            return "Make it chaotic and unhinged, but still PG-13 and non-offensive."
        case .corporate:
            return "Make it sound like a corporate or work-life meme, office and productivity themed."
        }
    }
}
