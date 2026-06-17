import Foundation

final class AgentSettings: ObservableObject {
    static let shared = AgentSettings()

    @Published var provider: String {
        didSet { UserDefaults.standard.set(provider, forKey: "provider") }
    }
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: "modelName") }
    }
    @Published var visionModelName: String {
        didSet { UserDefaults.standard.set(visionModelName, forKey: "visionModelName") }
    }
    @Published var availableModels: [String] = []
    @Published var isLoadingModels = false
    @Published var modelFetchError: String?
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
    @Published var useScreenshot: Bool {
        didSet { UserDefaults.standard.set(useScreenshot, forKey: "useScreenshot") }
    }
    @Published var useVisionModel: Bool {
        didSet { UserDefaults.standard.set(useVisionModel, forKey: "useVisionModel") }
    }
    @Published var touchIDForClicks: Bool {
        didSet { UserDefaults.standard.set(touchIDForClicks, forKey: "touchIDForClicks") }
    }
    @Published var touchIDForScreenshots: Bool {
        didSet { UserDefaults.standard.set(touchIDForScreenshots, forKey: "touchIDForScreenshots") }
    }
    @Published var touchIDForAXTree: Bool {
        didSet { UserDefaults.standard.set(touchIDForAXTree, forKey: "touchIDForAXTree") }
    }
    @Published var touchIDForAppLaunch: Bool {
        didSet { UserDefaults.standard.set(touchIDForAppLaunch, forKey: "touchIDForAppLaunch") }
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

    var supportedVisionModels: [String] {
        availableModels.filter { ModelFetcher.isVisionModel($0, provider: provider) }
    }

    @MainActor
    func fetchModels() async {
        isLoadingModels = true
        modelFetchError = nil
        let key = provider == "ollama"
            ? KeychainManager.shared.getProviderKey(provider: "ollama") ?? "http://localhost:11434"
            : KeychainManager.shared.getProviderKey(provider: provider)
        let models = await ModelFetcher.fetchModels(provider: provider, apiKey: key)
        if models.isEmpty {
            modelFetchError = "No models returned. Check your API key and network."
        }
        availableModels = models
        isLoadingModels = false
    }

    private init() {
        let defaults = UserDefaults.standard
        provider = defaults.string(forKey: "provider") ?? "anthropic"
        modelName = defaults.string(forKey: "modelName") ?? "claude-3-5-sonnet-20241022"
        visionModelName = defaults.string(forKey: "visionModelName")
            ?? defaults.string(forKey: "modelName") ?? "claude-3-5-sonnet-20241022"
        serverURLString = defaults.string(forKey: "serverURL") ?? "http://localhost:3000/api/agent/step"
        coolDownMs = defaults.object(forKey: "coolDownMs") as? Double ?? 500
        useAXTree = defaults.bool(forKey: "useAXTree")
        maxRetries = defaults.object(forKey: "maxRetries") as? Int ?? 3
        requestTimeout = defaults.object(forKey: "requestTimeout") as? Double ?? 30
        showNotifications = defaults.object(forKey: "showNotifications") as? Bool ?? true
        useScreenshot = defaults.object(forKey: "useScreenshot") as? Bool ?? true
        useVisionModel = defaults.object(forKey: "useVisionModel") as? Bool ?? true
        touchIDForClicks = defaults.object(forKey: "touchIDForClicks") as? Bool ?? true
        touchIDForScreenshots = defaults.object(forKey: "touchIDForScreenshots") as? Bool ?? true
        touchIDForAXTree = defaults.object(forKey: "touchIDForAXTree") as? Bool ?? true
        touchIDForAppLaunch = defaults.object(forKey: "touchIDForAppLaunch") as? Bool ?? true
    }

    @MainActor func applyToOrchestrator() {
        let loop = AgentOrchestrationLoop.shared
        loop.provider = provider
        loop.modelName = modelName
        loop.visionModelName = visionModelName
        loop.serverURL = serverURL
        loop.coolDownMs = UInt64(coolDownMs)
        loop.useAXTree = useAXTree
        loop.useScreenshot = useScreenshot
        loop.useVisionModel = useVisionModel
    }
}

