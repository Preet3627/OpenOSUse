import Foundation

final class AgentSettings: ObservableObject {
    static let shared = AgentSettings()

    @Published var provider: String {
        didSet { UserDefaults.standard.set(provider, forKey: "provider") }
    }
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: "modelName") }
    }
    @Published var serverURLString: String {
        didSet { UserDefaults.standard.set(serverURLString, forKey: "serverURL") }
    }
    @Published var coolDownMs: Double {
        didSet { UserDefaults.standard.set(coolDownMs, forKey: "coolDownMs") }
    }
    @Published var useAXTree: Bool {
        didSet { UserDefaults.standard.set(useAXTree, forKey: "useAXTree") }
    }
    @Published var maxRetries: Int {
        didSet { UserDefaults.standard.set(maxRetries, forKey: "maxRetries") }
    }
    @Published var requestTimeout: Double {
        didSet { UserDefaults.standard.set(requestTimeout, forKey: "requestTimeout") }
    }
    @Published var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: "showNotifications") }
    }

    let supportedProviders = [
        ("anthropic", "Anthropic Claude"),
        ("google", "Google Gemini"),
        ("groq", "Groq"),
        ("grok", "Grok (X.AI)"),
        ("ollama", "Ollama (local)"),
    ]

    var serverURL: URL {
        URL(string: serverURLString) ?? URL(string: "http://localhost:3000/api/agent/step")!
    }

    private init() {
        let defaults = UserDefaults.standard
        provider = defaults.string(forKey: "provider") ?? "anthropic"
        modelName = defaults.string(forKey: "modelName") ?? "claude-3-5-sonnet-20241022"
        serverURLString = defaults.string(forKey: "serverURL") ?? "http://localhost:3000/api/agent/step"
        coolDownMs = defaults.object(forKey: "coolDownMs") as? Double ?? 500
        useAXTree = defaults.bool(forKey: "useAXTree")
        maxRetries = defaults.object(forKey: "maxRetries") as? Int ?? 3
        requestTimeout = defaults.object(forKey: "requestTimeout") as? Double ?? 30
        showNotifications = defaults.object(forKey: "showNotifications") as? Bool ?? true
    }

    @MainActor func applyToOrchestrator() {
        let loop = AgentOrchestrationLoop.shared
        loop.provider = provider
        loop.modelName = modelName
        loop.serverURL = serverURL
        loop.coolDownMs = UInt64(coolDownMs)
        loop.useAXTree = useAXTree
    }
}

