import Foundation

enum ModelFetcher {

    static func fetchModels(provider: String, apiKey: String?) async -> [String] {
        switch provider {
        case "ollama":
            return await fetchOllama(baseURL: apiKey ?? "http://localhost:11434")
        case "google":
            return await fetchGemini(apiKey: apiKey ?? "")
        case "anthropic":
            return await fetchAnthropic(apiKey: apiKey ?? "")
        case "groq":
            return await fetchGroq(apiKey: apiKey ?? "")
        case "grok":
            return await fetchGrok(apiKey: apiKey ?? "")
        default:
            return []
        }
    }

    static func isVisionModel(_ id: String, provider: String) -> Bool {
        let lower = id.lowercased()
        switch provider {
        case "anthropic", "google":
            return true
        case "ollama":
            return lower.contains("llava")
                || lower.contains("bakllava")
                || lower.contains("moondream")
                || lower.contains("vision")
                || lower.contains("pixtral")
        case "groq":
            return lower.contains("llava")
                || lower.contains("pixtral")
                || lower.contains("vision")
                || lower == "llama-3.2-11b-vision-preview"
                || lower == "llama-3.2-90b-vision-preview"
        case "grok":
            return lower.contains("vision")
        default:
            return false
        }
    }

    // MARK: - Ollama

    private static func fetchOllama(baseURL: String) async -> [String] {
        let urlStr = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/api/tags"
        guard let url = URL(string: urlStr) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoded = try JSONDecoder().decode(OllamaTagResponse.self, from: data)
            return decoded.models.map { $0.name }
        } catch {
            return []
        }
    }

    private struct OllamaTagResponse: Decodable {
        let models: [OllamaModel]
    }

    private struct OllamaModel: Decodable {
        let name: String
    }

    // MARK: - Gemini

    private static func fetchGemini(apiKey: String) async -> [String] {
        guard !apiKey.isEmpty else { return [] }
        let urlStr = "https://generativelanguage.googleapis.com/v1/models?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoded = try JSONDecoder().decode(GeminiListResponse.self, from: data)
            return decoded.models
                .filter { $0.supportedGenerationMethods.contains("generateContent") }
                .map { $0.name.replacingOccurrences(of: "models/", with: "") }
        } catch {
            return []
        }
    }

    private struct GeminiListResponse: Decodable {
        let models: [GeminiModel]
    }

    private struct GeminiModel: Decodable {
        let name: String
        let supportedGenerationMethods: [String]
    }

    // MARK: - Anthropic

    private static func fetchAnthropic(apiKey: String) async -> [String] {
        guard !apiKey.isEmpty else { return [] }
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(AnthropicListResponse.self, from: data)
            return decoded.data.map { $0.id }
        } catch {
            return []
        }
    }

    private struct AnthropicListResponse: Decodable {
        let data: [AnthropicModel]
    }

    private struct AnthropicModel: Decodable {
        let id: String
    }

    // MARK: - Groq

    private static func fetchGroq(apiKey: String) async -> [String] {
        guard !apiKey.isEmpty else { return [] }
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(OpenAIListResponse.self, from: data)
            return decoded.data.map { $0.id }
        } catch {
            return []
        }
    }

    // MARK: - Grok (xAI)

    private static func fetchGrok(apiKey: String) async -> [String] {
        guard !apiKey.isEmpty else { return [] }
        guard let url = URL(string: "https://api.x.ai/v1/models") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(OpenAIListResponse.self, from: data)
            return decoded.data.map { $0.id }
        } catch {
            return []
        }
    }

    // MARK: - Shared (OpenAI-compatible)

    private struct OpenAIListResponse: Decodable {
        let data: [OpenAIModel]
    }

    private struct OpenAIModel: Decodable {
        let id: String
    }
}
