import Cocoa
import CoreGraphics
import ApplicationServices

@MainActor
class SystemAutomationEngine {
    static let shared = SystemAutomationEngine()

    private let eventSource: CGEventSource

    private init() {
        eventSource = CGEventSource(stateID: .hidSystemState)!
    }

    // MARK: - Application Management

    func openApplication(bundleIdentifier: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier
        }) {
            app.activate(options: .activateIgnoringOtherApps)
            return
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        else { return }
        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    // MARK: - Mouse Control

    func mouseMove(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    func mouseMoveSmooth(to target: CGPoint, duration: TimeInterval = 0.15) {
        let start = currentMouseLocationCG()
        let steps = max(Int(duration * 60), 1)
        let deltaX = (target.x - start.x) / CGFloat(steps)
        let deltaY = (target.y - start.y) / CGFloat(steps)
        let sleepUS = useconds_t(duration / Double(steps) * 1_000_000)

        for i in 1...steps {
            let point = CGPoint(
                x: start.x + deltaX * CGFloat(i),
                y: start.y + deltaY * CGFloat(i)
            )
            CGWarpMouseCursorPosition(point)
            CGAssociateMouseAndMouseCursorPosition(1)
            usleep(sleepUS)
        }
    }

    func mouseClick(at point: CGPoint, button: CGMouseButton = .left) {
        mouseMove(to: point)

        let downType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp

        guard let down = CGEvent(
            mouseEventSource: eventSource,
            mouseType: downType,
            mouseCursorPosition: point,
            mouseButton: button
        ), let up = CGEvent(
            mouseEventSource: eventSource,
            mouseType: upType,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    // MARK: - AX Element Clicking

    func clickElement(label: String, role: String?) -> String {
        do {
            let tree = try AXElementReader.shared.readFrontmostAppTree(maxDepth: 12)
            let found = findNode(in: tree, label: label, role: role)
            guard let node = found else {
                return "error: no element found with label \"\(label)\"\(role.map { " and role \"\($0)\"" } ?? "")"
            }
            let center = CGPoint(
                x: node.frame.x + node.frame.width / 2,
                y: node.frame.y + node.frame.height / 2
            )
            mouseClick(at: center)
            return "ok (clicked \"\(node.title.isEmpty ? node.description : node.title)\" at \(Int(center.x)),\(Int(center.y)))"
        } catch {
            return "error: \(error.localizedDescription)"
        }
    }

    private func findNode(in node: AXElementReader.AXNode, label: String, role: String?) -> AXElementReader.AXNode? {
        let labelLower = label.lowercased()
        let matchesLabel = node.title.lowercased() == labelLower
            || node.description.lowercased() == labelLower
            || node.value.lowercased() == labelLower
        let matchesRole = role == nil || node.role == role
        if matchesLabel && matchesRole {
            return node
        }
        for child in node.children {
            if let found = findNode(in: child, label: label, role: role) {
                return found
            }
        }
        return nil
    }

    // MARK: - Keyboard Control

    func typeText(string: String) {
        for char in string {
            let s = String(char)
            guard let mapping = charToKey[s] ?? charToKey[s.lowercased()]
            else { continue }
            let flags: CGEventFlags = mapping.needsShift ? .maskShift : []

            guard let down = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: mapping.keyCode,
                keyDown: true
            ), let up = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: mapping.keyCode,
                keyDown: false
            ) else { continue }

            down.flags = flags
            up.flags = flags
            down.post(tap: CGEventTapLocation.cghidEventTap)
            up.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }

    func triggerKeyCombination(_ keys: [String]) {
        let parsed = parseCombination(keys)
        guard let mainKey = parsed.keyCode else { return }

        guard let down = CGEvent(
            keyboardEventSource: eventSource,
            virtualKey: mainKey,
            keyDown: true
        ), let up = CGEvent(
            keyboardEventSource: eventSource,
            virtualKey: mainKey,
            keyDown: false
        ) else { return }

        down.flags = parsed.flags
        up.flags = parsed.flags
        down.post(tap: CGEventTapLocation.cghidEventTap)
        up.post(tap: CGEventTapLocation.cghidEventTap)
    }

    // MARK: - Coordinate Scaling

    struct CoordinateScaler {
        let captureWidth: CGFloat
        let captureHeight: CGFloat

        private var screenSize: CGSize {
            NSScreen.main?.frame.size ?? .zero
        }

        var scaleX: CGFloat {
            let w = screenSize.width
            return w > 0 ? w / captureWidth : 1
        }

        var scaleY: CGFloat {
            let h = screenSize.height
            return h > 0 ? h / captureHeight : 1
        }

        func mapToPhysical(_ modelPoint: CGPoint) -> CGPoint {
            CGPoint(x: modelPoint.x * scaleX, y: modelPoint.y * scaleY)
        }
    }

    // MARK: - Private

    private func currentMouseLocationCG() -> CGPoint {
        let ns = NSEvent.mouseLocation
        let h = NSScreen.screens[0].frame.maxY
        return CGPoint(x: ns.x, y: h - ns.y)
    }

    // MARK: - Key Parsing

    private struct KeyMapping {
        let keyCode: CGKeyCode
        let needsShift: Bool
    }

    private struct ParsedCombination {
        let flags: CGEventFlags
        let keyCode: CGKeyCode?
    }

    private func parseCombination(_ keys: [String]) -> ParsedCombination {
        var flags: CGEventFlags = []
        var mainKey: CGKeyCode?

        for key in keys {
            let lower = key.lowercased()
            if let flag = modifierFlag(for: lower) {
                flags.insert(flag)
            } else if let code = namedKey[lower] ?? singleCharKey[lower] {
                mainKey = code
            }
        }

        return ParsedCombination(flags: flags, keyCode: mainKey)
    }

    private func modifierFlag(for key: String) -> CGEventFlags? {
        switch key {
        case "cmd", "command": .maskCommand
        case "shift": .maskShift
        case "opt", "option", "alt": .maskAlternate
        case "ctrl", "control": .maskControl
        case "fn", "function": .maskSecondaryFn
        case "caps", "capslock": .maskAlphaShift
        default: nil
        }
    }

    private let singleCharKey: [String: CGKeyCode] = {
        var m = [String: CGKeyCode]()
        for (char, code) in SystemAutomationEngine.keys_letters { m[char] = code }
        for (char, code, _) in SystemAutomationEngine.keys_numbers { m[char] = code }
        for (char, code, _) in SystemAutomationEngine.keys_symbols { m[char] = code }
        return m
    }()

    private let namedKey: [String: CGKeyCode] = {
        var m = [String: CGKeyCode]()
        m["space"] = 0x31; m["return"] = 0x24; m["enter"] = 0x4C
        m["tab"] = 0x30; m["escape"] = 0x35; m["esc"] = 0x35
        m["delete"] = 0x33; m["backspace"] = 0x33; m["forwarddelete"] = 0x2F
        m["up"] = 0x7E; m["down"] = 0x7D; m["left"] = 0x7B; m["right"] = 0x7C
        m["home"] = 0x73; m["end"] = 0x77; m["pageup"] = 0x74; m["pagedown"] = 0x79
        for i in 1...12 { m["f\(i)"] = CGKeyCode(0x7A + i - 1) }
        return m
    }()

    // MARK: - Character → KeyCode Maps

    private static let keys_letters: [(String, CGKeyCode)] = [
        ("a", 0x00), ("s", 0x01), ("d", 0x02), ("f", 0x03), ("h", 0x04),
        ("g", 0x05), ("z", 0x06), ("x", 0x07), ("c", 0x08), ("v", 0x09),
        ("b", 0x0B), ("q", 0x0C), ("w", 0x0D), ("e", 0x0E), ("r", 0x0F),
        ("y", 0x10), ("t", 0x11), ("o", 0x1F), ("u", 0x20), ("i", 0x22),
        ("p", 0x23), ("l", 0x25), ("j", 0x26), ("k", 0x28), ("n", 0x2D),
        ("m", 0x2E),
    ]

    private static let keys_numbers: [(String, CGKeyCode, Bool)] = [
        ("1", 0x12, false), ("!", 0x12, true),
        ("2", 0x13, false), ("@", 0x13, true),
        ("3", 0x14, false), ("#", 0x14, true),
        ("4", 0x15, false), ("$", 0x15, true),
        ("5", 0x17, false), ("%", 0x17, true),
        ("6", 0x16, false), ("^", 0x16, true),
        ("7", 0x1A, false), ("&", 0x1A, true),
        ("8", 0x1C, false), ("*", 0x1C, true),
        ("9", 0x19, false), ("(", 0x19, true),
        ("0", 0x1D, false), (")", 0x1D, true),
    ]

    private static let keys_symbols: [(String, CGKeyCode, Bool)] = [
        ("-", 0x1B, false), ("_", 0x1B, true),
        ("=", 0x18, false), ("+", 0x18, true),
        ("[", 0x21, false), ("{", 0x21, true),
        ("]", 0x1E, false), ("}", 0x1E, true),
        ("\\", 0x2A, false), ("|", 0x2A, true),
        (";", 0x29, false), (":", 0x29, true),
        ("'", 0x27, false), ("\"", 0x27, true),
        (",", 0x2B, false), ("<", 0x2B, true),
        (".", 0x2F, false), (">", 0x2F, true),
        ("/", 0x2C, false), ("?", 0x2C, true),
        ("`", 0x32, false), ("~", 0x32, true),
    ]

    private let charToKey: [String: KeyMapping] = {
        var m = [String: KeyMapping]()

        for (char, code) in SystemAutomationEngine.keys_letters {
            m[char] = KeyMapping(keyCode: code, needsShift: false)
            m[char.uppercased()] = KeyMapping(keyCode: code, needsShift: true)
        }
        for (char, code, shift) in SystemAutomationEngine.keys_numbers {
            m[char] = KeyMapping(keyCode: code, needsShift: shift)
        }
        for (char, code, shift) in SystemAutomationEngine.keys_symbols {
            m[char] = KeyMapping(keyCode: code, needsShift: shift)
        }

        m[" "] = KeyMapping(keyCode: 0x31, needsShift: false)
        m["\t"] = KeyMapping(keyCode: 0x30, needsShift: false)
        m["\n"] = KeyMapping(keyCode: 0x24, needsShift: false)
        m["\r"] = KeyMapping(keyCode: 0x24, needsShift: false)

        return m
    }()
}
