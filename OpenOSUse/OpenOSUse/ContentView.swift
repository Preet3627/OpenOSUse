import UniformTypeIdentifiers
import SwiftUI

struct ContentView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var orchestrator = AgentOrchestrationLoop.shared
    @StateObject private var mcpServer = MCPServer.shared
    @StateObject private var settings = AgentSettings.shared
    @State private var objectiveText = ""
    @State private var selectedTab: Tab = .dashboard
    @State private var useAXTree = false
    @State private var showMCPInfo = false
    @State private var showingExporter = false
    @State private var exportedJSON: Data?

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case permissions = "Permissions"
        case mcp = "MCP Server"
        case telemetry = "Telemetry"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: "square.grid.2x2"
            case .permissions: "lock.shield"
            case .mcp: "link"
            case .telemetry: "chart.bar"
            case .settings: "gearshape"
            }
        }
    }

    var body: some View {
        HSplitView {
            sidebar
            mainContent
        }
        .frame(minWidth: 720, minHeight: 520)
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )) { _ in
            Task { await permissionManager.refreshAll() }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportedJSON.map { TelemetryDocument($0) },
            contentType: .json,
            defaultFilename: "telemetry-\(ISO8601DateFormatter().string(from: Date()))"
        ) { _ in }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Image(systemName: "diamond.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        .linearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("OpenOSUse")
                    .font(Font.system(.title3, design: .rounded).weight(.bold))
                Text(orchestrator.isRunning ? orchestrator.currentState.rawValue : "Ready")
                    .font(.caption2)
                    .foregroundColor(orchestrator.isRunning ? .green : .secondary)
            }
            .padding(.vertical, 20)

            Divider()

            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20)
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                        Color.accentColor.opacity(0.15) : Color.clear
                    )
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }

            Spacer()
        }
        .frame(width: 180)
        .background(.ultraThinMaterial)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .dashboard: dashboardView
        case .permissions: permissionsView
        case .mcp: mcpView
        case .telemetry: telemetryView
        case .settings: settingsView
        }
    }

    // MARK: - Dashboard

    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                if !orchestrator.isRunning {
                    controlCard
                } else {
                    agentStatusCard
                }
                if let err = orchestrator.lastError {
                    errorCard(err)
                }
                quickActionsCard
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agent Control")
                        .font(Font.system(.title, design: .rounded).weight(.bold))
                    Text("Describe a task and let the AI handle it")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if orchestrator.isRunning {
                    shimmerBadge
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var shimmerBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .modifier(ShimmerEffect())
            Text("Step \(orchestrator.stepCount)")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.green.opacity(0.12))
        .cornerRadius(12)
    }

    private var controlCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                TextField("What should I do? (e.g. \"Open Safari and go to github.com\")", text: $objectiveText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(.thinMaterial)
                    .cornerRadius(10)
            }

            HStack {
                Toggle(isOn: $useAXTree) {
                    HStack(spacing: 6) {
                        Image(systemName: "tree")
                            .font(.caption)
                        Text("Accessibility Tree")
                            .font(.caption)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                Button {
                    guard !objectiveText.trimmingCharacters(in: .whitespaces).isEmpty
                    else { return }
                    orchestrator.useAXTree = useAXTree
                    orchestrator.start(objective: objectiveText)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Launch Agent")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(objectiveText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(objectiveText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var agentStatusCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Agent Running")
                            .font(.headline)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                            .modifier(PulseEffect())
                    }
                    Text(orchestrator.currentAction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    orchestrator.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            stateProgressBar
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var stateProgressBar: some View {
        HStack(spacing: 0) {
            ForEach(AgentOrchestrationLoop.AgentState.allCases, id: \.self) { state in
                let isActive = orchestrator.currentState == state
                let isPast = pastState(state)

                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            isActive ? Color.cyan :
                            isPast ? Color.green : Color.gray.opacity(0.25)
                        )
                        .frame(width: 10, height: 10)
                    Text(state.rawValue)
                        .font(.system(size: 8, weight: isActive ? .bold : .regular))
                        .foregroundColor(isActive ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if state != AgentOrchestrationLoop.AgentState.allCases.last {
                    Rectangle()
                        .fill(
                            isPast ? Color.green : Color.gray.opacity(0.15)
                        )
                        .frame(height: 2)
                        .frame(maxWidth: 20)
                }
            }
        }
    }

    private func pastState(_ state: AgentOrchestrationLoop.AgentState) -> Bool {
        let all = AgentOrchestrationLoop.AgentState.allCases
        guard let currentIdx = all.firstIndex(of: orchestrator.currentState),
              let stateIdx = all.firstIndex(of: state)
        else { return false }
        return stateIdx < currentIdx
    }

    private func errorCard(_ err: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(err)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                orchestrator.lastError = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.08))
        .cornerRadius(10)
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(Font.system(.headline, design: .rounded))

            HStack(spacing: 12) {
                quickActionButton(
                    icon: "target",
                    label: "Test Coords",
                    action: { CoordinateAccuracyTest.runAll() }
                )
                quickActionButton(
                    icon: "arrow.clockwise",
                    label: "Refresh Status",
                    action: { Task { await permissionManager.refreshAll() } }
                )
                quickActionButton(
                    icon: "tree",
                    label: "Read AX Tree",
                    action: { readAXTree() }
                )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func readAXTree() {
        let json = AXElementReader.shared.readFrontmostAppTreeJSON()
        orchestrator.addTelemetry(message: "AX Tree: \(json.prefix(200))...")
    }

    // MARK: - Permissions

    private var permissionsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions")
                        .font(Font.system(.title, design: .rounded).weight(.bold))
                    Text("Required system permissions for agent operation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                permissionCard(
                    icon: "figure.accessibility",
                    title: "Accessibility",
                    description: "Control other apps via Accessibility APIs",
                    isGranted: permissionManager.accessibilityGranted,
                    action: permissionManager.requestAccessibilityPermission
                )

                permissionCard(
                    icon: "rectangle.dashed",
                    title: "Screen Recording",
                    description: "Observe and capture screen content",
                    isGranted: permissionManager.screenRecordingGranted,
                    action: permissionManager.requestScreenRecordingPermission
                )
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func permissionCard(icon: String, title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isGranted ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Button("Grant Access") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - MCP Server

    private var mcpView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MCP Server")
                        .font(Font.system(.title, design: .rounded).weight(.bold))
                    Text("Model Context Protocol — drive the agent remotely")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.headline)
                            Text(mcpServer.isRunning ? "Listening on port \(mcpServer.port)" : "Stopped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle(isOn: Binding(
                            get: { mcpServer.isRunning },
                            set: { if $0 { mcpServer.start() } else { mcpServer.stop() } }
                        )) {
                            EmptyView()
                        }
                        .toggleStyle(.switch)
                    }

                    if mcpServer.isRunning {
                        Divider()
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.secondary)
                            Text("Connections: \(mcpServer.connectionCount)")
                                .font(.caption)
                            Spacer()
                            Text("TCP :\(mcpServer.port)")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                if mcpServer.isRunning {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Available Tools")
                            .font(.headline)
                        mcpToolRow("screenshot", "Capture current screen as base64 JPEG")
                        mcpToolRow("axTree", "Read Accessibility element tree of frontmost app")
                        mcpToolRow("click", "Click at screen coordinates (x, y)")
                        mcpToolRow("type", "Type text at current focus")
                        mcpToolRow("open_app", "Open an app by bundle ID")
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func mcpToolRow(_ name: String, _ description: String) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(Font.system(.caption, design: .monospaced).weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.cyan.opacity(0.1))
                .cornerRadius(6)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Telemetry

    private var telemetryView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Telemetry")
                        .font(Font.system(.title, design: .rounded).weight(.bold))
                    Text("\(orchestrator.telemetryLogs.count) entries — live agent log")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !orchestrator.telemetryLogs.isEmpty {
                    Button("Clear") {
                        orchestrator.clearLogs()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(16)

            Divider()

            if orchestrator.telemetryLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No telemetry yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Run an agent to see step-by-step logs")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(orchestrator.telemetryLogs) { entry in
                                HStack(spacing: 8) {
                                    Text(entry.timestampFormatted)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    Text("[\(entry.state.rawValue)]")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(entry.stateColor)
                                        .frame(width: 60, alignment: .leading)
                                    Text(entry.message)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 3)
                                .background(entry.id == orchestrator.telemetryLogs.last?.id ? Color.accentColor.opacity(0.05) : Color.clear)
                                .id(entry.id)
                            }
                        }
                    }
                    .background(.ultraThinMaterial)
                    .onChange(of: orchestrator.telemetryLogs.count) { _ in
                        withAnimation(.none) {
                            proxy.scrollTo(orchestrator.telemetryLogs.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Settings

    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(Font.system(.title, design: .rounded).weight(.bold))
                    Text("Agent configuration — persisted across launches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Provider & Model
                VStack(spacing: 14) {
                    LabeledContent("Provider") {
                        Picker("", selection: $settings.provider) {
                            ForEach(settings.supportedProviders, id: \.0) { key, label in
                                Text(label).tag(key)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }

                    LabeledContent("Chat Model") {
                        HStack(spacing: 6) {
                            if settings.isLoadingModels {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16)
                            }
                            if settings.availableModels.isEmpty {
                                TextField("claude-3-5-sonnet-20241022", text: $settings.modelName)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .cornerRadius(8)
                                    .frame(width: 160)
                            } else {
                                Picker("", selection: $settings.modelName) {
                                    ForEach(settings.availableModels, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)
                            }
                            Button {
                                Task { await settings.fetchModels() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .disabled(settings.isLoadingModels)
                        }
                    }

                    LabeledContent("Vision Model") {
                        HStack(spacing: 6) {
                            if settings.isLoadingModels {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16)
                            }
                            if settings.supportedVisionModels.isEmpty {
                                TextField(text: $settings.visionModelName) {
                                    Text(settings.modelName)
                                }
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                                .frame(width: 160)
                            } else {
                                Picker("", selection: $settings.visionModelName) {
                                    ForEach(settings.supportedVisionModels, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)
                            }
                            Button {
                                Task { await settings.fetchModels() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .disabled(settings.isLoadingModels)
                        }
                    }

                    if let err = settings.modelFetchError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    LabeledContent("Server URL") {
                        TextField("http://localhost:3000/api/agent/step", text: $settings.serverURLString)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .frame(width: 200)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                // Tuning
                VStack(spacing: 14) {
                    LabeledContent("Cooldown") {
                        HStack {
                            Slider(value: $settings.coolDownMs, in: 0...3000, step: 100)
                            Text("\(Int(settings.coolDownMs)) ms")
                                .font(.caption.monospaced())
                                .frame(width: 60)
                        }
                    }

                    LabeledContent("Max Retries") {
                        HStack {
                            Stepper(value: $settings.maxRetries, in: 0...10) {
                                Text("\(settings.maxRetries)")
                                    .font(.caption.monospaced())
                            }
                            Text("attempts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    LabeledContent("Request Timeout") {
                        HStack {
                            Slider(value: $settings.requestTimeout, in: 5...120, step: 5)
                            Text("\(Int(settings.requestTimeout))s")
                                .font(.caption.monospaced())
                                .frame(width: 40)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                // Toggles
                VStack(spacing: 14) {
                    Toggle(isOn: $settings.useAXTree) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Tree")
                                .font(.headline)
                            Text("Capture element tree alongside screenshots")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.showNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Notifications")
                                .font(.headline)
                            Text("Show notification on agent finish or error")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.useScreenshot) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshots")
                                .font(.headline)
                            Text("Capture screen for visual context (requires Screen Recording permission)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.useVisionModel) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vision Model")
                                .font(.headline)
                            Text("Use a separate vision model to describe screenshots")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!settings.useScreenshot)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                // Touch ID Permissions
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "touchid")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                        Text("Touch ID Permissions")
                            .font(.headline)
                    }
                    Text("Require biometric verification before each action type — once per session, not per click")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle(isOn: $settings.touchIDForClicks) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clicks")
                                .font(.subheadline.weight(.medium))
                            Text("click / click_element actions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.touchIDForScreenshots) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshots")
                                .font(.subheadline.weight(.medium))
                            Text("Screen capture via SCStream")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!settings.useScreenshot)

                    Toggle(isOn: $settings.touchIDForAXTree) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Tree")
                                .font(.subheadline.weight(.medium))
                            Text("Reading UI element tree via AX API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!settings.useAXTree)

                    Toggle(isOn: $settings.touchIDForAppLaunch) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Launch")
                                .font(.subheadline.weight(.medium))
                            Text("Opening or activating applications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                // Actions
                VStack(spacing: 12) {
                    Button {
                        settings.applyToOrchestrator()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Settings")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    if !orchestrator.telemetryLogs.isEmpty {
                        Button {
                            if let data = orchestrator.exportLogs() {
                                exportedJSON = data
                                showingExporter = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Telemetry")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .fileExporter(
            isPresented: $showingExporter,
            document: exportedJSON.map { TelemetryDocument($0) },
            contentType: .json,
            defaultFilename: "telemetry-\(ISO8601DateFormatter().string(from: Date()))"
        ) { _ in }
    }
}

// MARK: - Effects

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.5), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 200)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct PulseEffect: ViewModifier {
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.3
                }
            }
    }
}

// MARK: - TelemetryDocument for export

struct TelemetryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(_ data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - TelemetryEntry formatting

extension TelemetryEntry {
    var timestampFormatted: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df.string(from: timestamp)
    }

    var stateColor: Color {
        switch state {
        case .idle: .green
        case .observing: .blue
        case .planning: .orange
        case .executing: .purple
        case .coolingDown: .cyan
        }
    }
}
