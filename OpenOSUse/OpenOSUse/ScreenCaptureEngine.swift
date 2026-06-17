import ScreenCaptureKit
import CoreImage
import AppKit

enum CaptureError: Error {
    case noDisplay
}

class ScreenCaptureEngine: NSObject, ObservableObject {
    static let shared = ScreenCaptureEngine()

    private var stream: SCStream?
    private let maxDimension: CGFloat = 1280

    private let lock = NSLock()
    private var lastFrame: CVImageBuffer?

    private lazy var ciContext = CIContext(
        options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!]
    )

    private override init() {
        super.init()
    }

    var isRunning: Bool { stream != nil }

    var captureSize: CGSize {
        let bounds = CGDisplayBounds(CGMainDisplayID())
        let aspect = bounds.width / bounds.height
        return CGSize(width: maxDimension, height: maxDimension / aspect)
    }

    func startCaptureIfNeeded() async -> Bool {
        guard !isRunning else { return true }
        do {
            try await startCapture()
            return true
        } catch {
            return false
        }
    }

    func captureScreenshot(timeout: TimeInterval = 3.0) async -> Data? {
        let deadline = Date(timeIntervalSinceNow: timeout)
        repeat {
            if let data = await captureCurrentFrame() { return data }
            try? await Task.sleep(nanoseconds: 50_000_000)
        } while Date() < deadline
        return nil
    }

    func startCapture() async throws {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(
            display: display,
            excludingWindows: []
        )

        let displayBounds = CGDisplayBounds(display.displayID)
        let aspectRatio = displayBounds.width / displayBounds.height

        let config = SCStreamConfiguration()
        config.width = Int(maxDimension)
        config.height = Int(maxDimension / aspectRatio)
        config.showsCursor = true
        config.scalesToFit = true
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)

        stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream!.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: DispatchQueue(
                label: "com.daksh.openosuse.screencapture"
            )
        )
        try await stream!.startCapture()
    }

    func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
        lock.withLock { lastFrame = nil }
    }

    func captureCurrentFrame() async -> Data? {
        let imageBuffer: CVImageBuffer? = lock.withLock { lastFrame }
        guard let buffer = imageBuffer else { return nil }
        return convertToJPEG(buffer)
    }

    private func convertToJPEG(_ imageBuffer: CVImageBuffer) -> Data? {
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { return nil }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.7]
        )
    }
}

extension ScreenCaptureEngine: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen,
              let imageBuffer = sampleBuffer.imageBuffer
        else { return }
        lock.withLock { lastFrame = imageBuffer }
    }
}
