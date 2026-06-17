import Foundation
import CoreGraphics
import UserNotifications

// ---------------------------------------------------------------------------
// MARK: - TelemetryEntry
// ---------------------------------------------------------------------------

struct TelemetryEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let state: AgentOrchestrationLoop.AgentState
    let step: Int
    let message: String

    init(id: UUID = UUID(), timestamp: Date = Date(), state: AgentOrchestrationLoop.AgentState, step: Int, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.state = state
        self.step = step
        self.message = message
    }
}

// ---------------------------------------------------------------------------
// MARK: - JSONValue — Decode arbitrary JSON tool arguments
// ---------------------------------------------------------------------------

enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    var stringValue: String? { if case .string(let v) = self { v } else { nil } }
    var numberValue: Double? { if case .number(let v) = self { v } else { nil } }
    var arrayValue: [JSONValue]? { if case .array(let v) = self { v } else { nil } }

    var any: Any {
        switch self {
        case .string(let v): v
        case .number(let v): v
        case .bool(let v): v
        case .array(let v): v.map(\.any)
        case .object(let v): v.mapValues(\.any)
        case .null: NSNull()
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode([JSONValue].self) { self = .array(v); return }
        if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
        if c.decodeNil() { self = .null; return }
        throw DecodingError.dataCorrupted(.init(
            codingPath: c.codingPath,
            debugDescription: "Unsupported JSON value"
        ))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - DTOs matching the TypeScript server contract
// ---------------------------------------------------------------------------

struct HistoryEntry: Codable {
    let role: String
    let tool: String
    let arguments: [String: JSONValue]
    let result: String?
}

struct StepRequest: Encodable {
    let provider: String
    let modelName: String
    let screenshot: String
    let axTree: String?
    let objective: String
    let history: [HistoryEntry]
}

struct StepResponse: Decodable {
    let tool: String
    let arguments: [String: JSONValue]
    let thinking: String?

    enum CodingKeys: String, CodingKey {
        case tool, arguments, thinking
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tool = try c.decode(String.self, forKey: .tool)
        thinking = try c.decodeIfPresent(String.self, forKey: .thinking)
        arguments = try c.decode([String: JSONValue].self, forKey: .arguments)
    }
}

// ---------------------------------------------------------------------------
// MARK: - AgentOrchestrationLoop
// ---------------------------------------------------------------------------

@MainActor
final class AgentOrchestrationLoop: ObservableObject {
    static let shared = AgentOrchestrationLoop()

    // MARK: Published state

    @Published var isRunning = false
    @Published private(set) var currentState: AgentState = .idle
    @Published private(set) var currentAction = ""
    @Published private(set) var stepCount = 0
    @Published var lastError: String?
    @Published private(set) var telemetryLogs: [TelemetryEntry] = []
    @Published private(set) var objective = ""

    enum AgentState: String, CaseIterable, Codable {
        case idle = "Idle"
        case observing = "OBSERVE"
        case planning = "PLAN"
        case executing = "EXECUTE"
        case coolingDown = "COOL DOWN"
    }

    // MARK: Configuration (applied from AgentSettings)

    var serverURL = URL(string: "http://localhost:3000/api/agent/step")!
    var provider = "anthropic"
    var modelName = "claude-3-5-sonnet-20241022"
    var coolDownMs: UInt64 = 500
    let captureWidth: CGFloat = 1280
    var useAXTree = false

    private var history: [HistoryEntry] = []
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {}

    // MARK: Public API

    func start(objective: String) {
        guard !isRunning else { return }
        self.objective = objective
        reset()
        isRunning = true
        currentState = .observing
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        Task { await runLoop(objective: objective) }
    }

    func stop() {
        isRunning = false
        currentState = .idle
    }

    // MARK: Loop body

    private func runLoop(objective: String) async {
        guard await ScreenCaptureEngine.shared.startCaptureIfNeeded() else {
            lastError = "Failed to start screen capture"
            await finish()
            return
        }

        log(.observing, "Agent started. Model: \(provider)/\(modelName)")
        log(.observing, "Objective: \(objective)")
        if useAXTree {
            log(.observing, "Accessibility Tree mode enabled")
        }

        while isRunning {
            // ── 1. OBSERVE ────────────────────────────────────────────
            currentState = .observing
            currentAction = "Capturing screenshot…"
            log(.observing, "Capturing screenshot…")

            guard let screenshotData = await ScreenCaptureEngine.shared.captureScreenshot() else {
                lastError = "Failed to capture screenshot"
                await finish()
                return
            }
            let b64 = screenshotData.base64EncodedString()
            guard isRunning else { break }

            // ── 1b. (optional) AX Tree ───────────────────────────────
            var axTreeJSON: String?
            if useAXTree {
                currentAction = "Reading Accessibility Tree…"
                axTreeJSON = AXElementReader.shared.readFrontmostAppTreeJSON()
                log(.observing, "AX Tree captured (\(axTreeJSON?.count ?? 0) chars)")
            }

            // ── 2. PLAN ──────────────────────────────────────────────
            currentState = .planning
            currentAction = "Sending to agent server…"
            log(.planning, "Sending screenshot (\(b64.count) bytes) to \(provider)/\(modelName)…")

            let maxRetries = AgentSettings.shared.maxRetries
            var response: StepResponse? = nil
            for attempt in 1...maxRetries {
                response = await sendStep(screenshot: b64, axTree: axTreeJSON, objective: objective)
                if response != nil { break }
                if attempt < maxRetries {
                    log(.planning, "Retry \(attempt)/\(maxRetries)…")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            guard let finalResponse = response else {
                lastError = "No response from agent server after \(maxRetries) retries"
                log(.planning, "ERROR: \(lastError ?? "")")
                await finish()
                return
            }
            guard isRunning else { break }

            stepCount += 1
            currentAction = "\(finalResponse.tool): \(finalResponse.arguments)"

            // ── 3. EXECUTE ────────────────────────────────────────────
            currentState = .executing
            let result = await execute(finalResponse)
            log(.executing, "\(finalResponse.tool)(\(argDescription(finalResponse.arguments))) → \(result)")

            history.append(HistoryEntry(
                role: "assistant",
                tool: finalResponse.tool,
                arguments: finalResponse.arguments,
                result: result
            ))

            // ── 4. CHECK FINISH ──────────────────────────────────────
            if finalResponse.tool == "finish" {
                await finish()
                return
            }

            // ── 5. COOL DOWN ─────────────────────────────────────────
            currentState = .coolingDown
            currentAction = "Waiting \(coolDownMs) ms…"
            log(.coolingDown, "Waiting \(coolDownMs) ms for UI to settle…")
            try? await Task.sleep(nanoseconds: coolDownMs * 1_000_000)
        }

        await finish()
    }

    // MARK: Server request with timeout

    private func sendStep(screenshot: String, axTree: String?, objective: String) async -> StepResponse? {
        let resolvedKey: String
        if provider == "ollama" {
            resolvedKey = KeychainManager.shared.getProviderKey(provider: "ollama")
                ?? "http://localhost:11434"
        } else {
            guard let k = KeychainManager.shared.getProviderKey(provider: provider) else {
                let msg = "No API key configured for \"\(provider)\". " +
                          "Save one in the GUI and try again."
                lastError = msg
                log(.planning, "ERROR: \(msg)")
                return nil
            }
            resolvedKey = k
        }

        let body = StepRequest(
            provider: provider,
            modelName: modelName,
            screenshot: screenshot,
            axTree: axTree,
            objective: objective,
            history: history
        )

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "X-Provider-API-Key")
        request.setValue(provider, forHTTPHeaderField: "X-Target-Provider")
        request.httpBody = try? encoder.encode(body)
        request.timeoutInterval = AgentSettings.shared.requestTimeout

        log(.planning, "POST \(stepCount+1) to \(provider)/\(modelName) (\(screenshot.count) bytes, timeout: \(Int(request.timeoutInterval))s)")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try decoder.decode(StepResponse.self, from: data)
        } catch {
            lastError = "Server error: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: Action dispatch

    private func execute(_ step: StepResponse) async -> String {
        let engine = SystemAutomationEngine.shared

        switch step.tool {
        case "open_app":
            guard let id = step.arguments["bundleId"]?.stringValue else {
                return "error: missing bundleId"
            }
            engine.openApplication(bundleIdentifier: id)
            return "ok"

        case "click":
            guard let x = step.arguments["x"]?.numberValue,
                  let y = step.arguments["y"]?.numberValue
            else { return "error: missing coordinates" }
            let physical = scaleToPhysical(CGPoint(x: x, y: y))
            engine.mouseClick(at: physical)
            return "ok"

        case "type":
            guard let text = step.arguments["text"]?.stringValue
            else { return "error: missing text" }
            engine.typeText(string: text)
            return "ok"

        case "key_combo":
            guard let keys = step.arguments["keys"]?
                .arrayValue?.compactMap(\.stringValue)
            else { return "error: missing keys" }
            engine.triggerKeyCombination(keys)
            return "ok"

        case "wait":
            guard let ms = step.arguments["durationMs"]?.numberValue
            else { return "error: missing durationMs" }
            try? await Task.sleep(nanoseconds: UInt64(ms * 1_000_000))
            return "ok"

        case "finish":
            return "finished"

        default:
            return "unknown tool: \(step.tool)"
        }
    }

    // MARK: Coordinate scaling

    private func scaleToPhysical(_ modelPoint: CGPoint) -> CGPoint {
        let bounds = CGDisplayBounds(CGMainDisplayID())
        let aspect = bounds.width / bounds.height
        let captureHeight = captureWidth / aspect

        let scaler = SystemAutomationEngine.CoordinateScaler(
            captureWidth: captureWidth,
            captureHeight: captureHeight
        )
        return scaler.mapToPhysical(modelPoint)
    }

    // MARK: Helpers

    private func reset() {
        currentState = .idle
        currentAction = ""
        stepCount = 0
        lastError = nil
        history = []
    }

    func clearLogs() {
        telemetryLogs.removeAll()
    }

    func addTelemetry(message: String) {
        log(.idle, message)
    }

    func exportLogs() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(telemetryLogs)
    }

    // MARK: Notifications

    private func sendNotification(title: String, body: String) {
        guard AgentSettings.shared.showNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: Telemetry

    private func log(_ state: AgentState, _ message: String) {
        let entry = TelemetryEntry(
            timestamp: Date(),
            state: state,
            step: stepCount,
            message: message
        )
        Task { @MainActor in
            telemetryLogs.append(entry)
        }
    }

    private func argDescription(_ args: [String: JSONValue]) -> String {
        args.map { key, val in
            switch val {
            case .string(let s): "\(key): \"\(s)\""
            case .number(let n): "\(key): \(n)"
            case .array(let a): "\(key): [\(a.compactMap(\.stringValue).joined(separator: ", "))]"
            default: "\(key): \(val)"
            }
        }.joined(separator: ", ")
    }

    private func finish() async {
        let steps = stepCount
        let err = lastError

        log(.idle, "Session complete – \(steps) steps executed")
        currentState = .idle
        isRunning = false
        await ScreenCaptureEngine.shared.stopCapture()

        if let err = err {
            sendNotification(title: "Agent Failed", body: err)
        } else if steps > 0 {
            sendNotification(title: "Agent Complete", body: "Finished in \(steps) steps: \(objective.prefix(80))")
        }
    }
}
