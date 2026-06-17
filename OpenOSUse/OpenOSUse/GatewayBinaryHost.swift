import Foundation

final class GatewayBinaryHost {
    static let shared = GatewayBinaryHost()
    private var process: Process?

    private init() {}

    func launchLocalGateway() throws {
        guard let url = Bundle.main.url(forResource: "OpenOSUseGateway", withExtension: nil) else {
            throw GatewayError.binaryNotFound
        }

        let proc = Process()
        proc.executableURL = url
        proc.environment = [:]
        proc.terminationHandler = { _ in
            print("[GatewayBinaryHost] Process exited")
        }
        try proc.run()
        process = proc
        print("[GatewayBinaryHost] Launched \(url.path)")
    }

    func terminateLocalGateway() {
        guard let proc = process, proc.isRunning else { return }
        proc.terminate()
        process = nil
        print("[GatewayBinaryHost] Terminated")
    }

    deinit {
        terminateLocalGateway()
    }

    enum GatewayError: Error, LocalizedError {
        case binaryNotFound
        var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                return "OpenOSUseGateway binary not found in app bundle"
            }
        }
    }
}
