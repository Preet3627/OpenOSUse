import SwiftUI

struct ContentView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var orchestrator = AgentOrchestrationLoop.shared
    @State private var objectiveText = ""
    @State private var apiKeyText = ""

    var body: some View {
        VStack(spacing: 16) {
            // ── Header ────────────────────────────────────────────
            VStack(spacing: 4) {
                Text("OpenOSUse")
                    .font(.largeTitle).fontWeight(.bold)
                Text("Permission Status")
                    .font(.title2).foregroundColor(.secondary)
            }

            // ── Permission rows ───────────────────────────────────
            VStack(spacing: 8) {
                PermissionRow(
                    title: "Accessibility",
                    description: "Control other apps via Accessibility APIs",
                    isGranted: permissionManager.accessibilityGranted,
                    action: permissionManager.requestAccessibilityPermission
                )
                PermissionRow(
                    title: "Screen Recording",
                    description: "Observe and capture screen content",
                    isGranted: permissionManager.screenRecordingGranted,
                    action: permissionManager.requestScreenRecordingPermission
                )
            }

            Divider()

            // ── Agent controls ────────────────────────────────────
            if !orchestrator.isRunning {
                HStack {
                    TextField("Objective…", text: $objectiveText)
                        .textFieldStyle(.roundedBorder)
                    Button("Go") {
                        guard !objectiveText.trimmingCharacters(in: .whitespaces).isEmpty
                        else { return }
                        orchestrator.start(objective: objectiveText)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(objectiveText.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                HStack(spacing: 12) {
                    Button("Test Coordinates") { CoordinateAccuracyTest.runAll() }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Refresh Status") {
                        Task { await permissionManager.refreshAll() }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Step \(orchestrator.stepCount) • \(orchestrator.currentState.rawValue)")
                            .font(.headline)
                        Text(orchestrator.currentAction)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Stop") { orchestrator.stop() }
                        .buttonStyle(.bordered).tint(.red).controlSize(.small)
                }
            }

            if let err = orchestrator.lastError {
                Text("⚠ \(err)").font(.caption).foregroundColor(.red)
            }

            // ── Telemetry log ─────────────────────────────────────
            if !orchestrator.telemetryLogs.isEmpty {
                Divider()
                Text("Telemetry Log")
                    .font(.caption).fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(orchestrator.telemetryLogs) { entry in
                                Text(entry.formatted)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(entry.state == .idle ? .green : .secondary)
                                    .id(entry.id)
                            }
                        }
                    }
                    .frame(height: 160)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                    .onChange(of: orchestrator.telemetryLogs.count) { _ in
                        withAnimation(.none) {
                            proxy.scrollTo(orchestrator.telemetryLogs.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 520)
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )) { _ in
            Task { await permissionManager.refreshAll() }
        }
    }
}

// MARK: - PermissionRow

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if isGranted {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Grant Access") { action() }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - TelemetryEntry formatting

extension TelemetryEntry {
    var formatted: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return "[\(df.string(from: timestamp))] [\(state.rawValue)] \(message)"
    }
}
