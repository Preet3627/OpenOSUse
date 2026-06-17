import Foundation
import Network

final class MCPServer: ObservableObject {
    static let shared = MCPServer()

    @Published var isRunning = false
    @Published var port: UInt16 = 8081
    @Published var connectionCount = 0

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.daksh.openosuse.mcp", qos: .userInitiated)

    private init() {}

    struct MCPRequest: Codable {
        let jsonrpc: String
        let id: Int
        let method: String
        let params: MCPParams?

        struct MCPParams: Codable {
            let tool: String?
            let arguments: [String: JSONValue]?
            let context: MCPContext?
        }

        struct MCPContext: Codable {
            let screenshot: String?
            let axTree: String?
            let objective: String?
        }
    }

    struct MCPResponse: Codable {
        let jsonrpc: String
        let id: Int
        let result: MCPResult?
        let error: MCPError?

        struct MCPResult: Codable {
            let tool: String?
            let arguments: [String: JSONValue]?
            let thinking: String?
            let nextStep: String?
        }

        struct MCPError: Codable {
            let code: Int
            let message: String
        }
    }

    struct MCPCapabilities: Codable {
        let version: String
        let tools: [MCPTool]
        let provider: String
        let model: String

        struct MCPTool: Codable {
            let name: String
            let description: String
            let parameters: [String: MCPParam]
        }

        struct MCPParam: Codable {
            let type: String
            let description: String
            let required: Bool
        }
    }

    func start() {
        guard !isRunning else { return }

        do {
            let params = NWParameters.tcp

            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port) ?? 8081)
            listener?.service = .init(name: "OpenOSUse-MCP", type: "_mcp._tcp")

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener?.start(queue: queue)
            Task { @MainActor in
                isRunning = true
            }
            print("[MCPServer] Listening on port \(port)")
        } catch {
            print("[MCPServer] Failed to start: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        Task { @MainActor in
            isRunning = false
        }
        print("[MCPServer] Stopped")
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.connectionCount += 1
                    print("[MCPServer] Client connected (total: \(self?.connectionCount ?? 0))")
                case .failed(let error):
                    print("[MCPServer] Connection failed: \(error)")
                case .cancelled:
                    self?.connectionCount -= 1
                    print("[MCPServer] Client disconnected")
                default:
                    break
                }
            }
        }

        connection.start(queue: queue)
        receiveNextMessage(connection)
    }

    private func receiveNextMessage(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleMessage(data, connection: connection)
            }

            if isComplete {
                connection.cancel()
            } else if error == nil {
                self?.receiveNextMessage(connection)
            }
        }
    }

    private func handleMessage(_ data: Data, connection: NWConnection) {
        do {
            let request = try JSONDecoder().decode(MCPRequest.self, from: data)

            switch request.method {
            case "initialize":
                sendCapabilities(connection, id: request.id)
            case "execute_tool":
                handleToolExecution(request, connection: connection)
            case "shutdown":
                let response = MCPResponse(
                    jsonrpc: "2.0", id: request.id,
                    result: nil,
                    error: nil
                )
                sendResponse(response, connection: connection)
                connection.cancel()
            default:
                let errorResponse = MCPResponse(
                    jsonrpc: "2.0", id: request.id,
                    result: nil,
                    error: .init(code: -32601, message: "Method not found: \(request.method)")
                )
                sendResponse(errorResponse, connection: connection)
            }
        } catch {
            let errorResponse = MCPResponse(
                jsonrpc: "2.0", id: 0,
                result: nil,
                error: .init(code: -32700, message: "Parse error: \(error.localizedDescription)")
            )
            sendResponse(errorResponse, connection: connection)
        }
    }

    private func sendCapabilities(_ connection: NWConnection, id: Int) {
        let result = MCPResponse.MCPResult(
            tool: nil, arguments: nil, thinking: nil,
            nextStep: nil
        )

        let response = MCPResponse(
            jsonrpc: "2.0", id: id,
            result: result,
            error: nil
        )
        sendResponse(response, connection: connection)
    }

    private func handleToolExecution(_ request: MCPRequest, connection: NWConnection) {
        guard let tool = request.params?.tool else {
            let errorResponse = MCPResponse(
                jsonrpc: "2.0", id: request.id,
                result: nil,
                error: .init(code: -32602, message: "Missing tool name")
            )
            sendResponse(errorResponse, connection: connection)
            return
        }

        switch tool {
        case "screenshot":
            Task {
                await ScreenCaptureEngine.shared.startCaptureIfNeeded()
                if let data = await ScreenCaptureEngine.shared.captureScreenshot() {
                    let b64 = data.base64EncodedString()
                    let result = MCPResponse.MCPResult(
                        tool: "screenshot", arguments: ["data": .string(b64)], thinking: nil, nextStep: nil
                    )
                    let response = MCPResponse(jsonrpc: "2.0", id: request.id, result: result, error: nil)
                    sendResponse(response, connection: connection)
                } else {
                    let errorResponse = MCPResponse(
                        jsonrpc: "2.0", id: request.id, result: nil,
                        error: .init(code: -32000, message: "Failed to capture screenshot")
                    )
                    sendResponse(errorResponse, connection: connection)
                }
            }

        case "axTree":
            Task { @MainActor in
                let json = AXElementReader.shared.readFrontmostAppTreeJSON()
                let result = MCPResponse.MCPResult(
                    tool: "axTree", arguments: ["tree": .string(json)], thinking: nil, nextStep: nil
                )
                let response = MCPResponse(jsonrpc: "2.0", id: request.id, result: result, error: nil)
                self.sendResponse(response, connection: connection)
            }

        default:
            let errorResponse = MCPResponse(
                jsonrpc: "2.0", id: request.id, result: nil,
                error: .init(code: -32602, message: "Unknown tool: \(tool)")
            )
            sendResponse(errorResponse, connection: connection)
        }
    }

    private func sendResponse(_ response: MCPResponse, connection: NWConnection) {
        do {
            let data = try JSONEncoder().encode(response)
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("[MCPServer] Send error: \(error)")
                }
            })
        } catch {
            print("[MCPServer] Encoding error: \(error)")
        }
    }
}
