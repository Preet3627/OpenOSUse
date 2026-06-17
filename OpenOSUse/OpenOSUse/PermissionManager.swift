import Cocoa
import ApplicationServices
import ScreenCaptureKit

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var accessibilityGranted = false
    @Published var screenRecordingGranted = false

    private init() {
        accessibilityGranted = AXIsProcessTrusted()
        Task { await refreshScreenRecording() }
    }

    func refreshAll() async {
        accessibilityGranted = AXIsProcessTrusted()
        await refreshScreenRecording()
    }

    private func refreshScreenRecording() async {
        screenRecordingGranted = await checkScreenRecordingPermission()
    }

    private func checkScreenRecordingPermission() async -> Bool {
        if #available(macOS 14.0, *) {
            return CGPreflightScreenCaptureAccess()
        }
        do {
            let content = try await SCShareableContent.current
            return !content.displays.isEmpty
        } catch {
            return false
        }
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
    }

    func requestScreenRecordingPermission() {
        if #available(macOS 14.0, *) {
            CGRequestScreenCaptureAccess()
        }
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        )
    }
}
