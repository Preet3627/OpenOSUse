import ApplicationServices
import Cocoa

final class AXElementReader {
    static let shared = AXElementReader()

    private init() {}

    struct AXNode: Encodable {
        let role: String
        let title: String
        let description: String
        let value: String
        let isFocused: Bool
        let frame: Frame
        let children: [AXNode]

        struct Frame: Encodable {
            var x: Double = 0
            var y: Double = 0
            var width: Double = 0
            var height: Double = 0
        }
    }

    enum AXError: Error, LocalizedError {
        case notTrusted
        case noFrontmostApp
        case attributeNotFound(String)
        case invalidValue(String)

        var errorDescription: String? {
            switch self {
            case .notTrusted: return "Process is not trusted for Accessibility"
            case .noFrontmostApp: return "No frontmost application found"
            case .attributeNotFound(let a): return "Attribute not found: \(a)"
            case .invalidValue(let a): return "Invalid value for attribute: \(a)"
            }
        }
    }

    func readFrontmostAppTree(maxDepth: Int = 8) throws -> AXNode {
        guard AXIsProcessTrusted() else {
            throw AXError.notTrusted
        }

        let app = NSWorkspace.shared.frontmostApplication
        guard let pid = app?.processIdentifier else {
            throw AXError.noFrontmostApp
        }

        let appElement = AXUIElementCreateApplication(pid)
        return buildTree(element: appElement, depth: 0, maxDepth: maxDepth)
    }

    func readFrontmostAppTreeJSON(maxDepth: Int = 8) -> String {
        do {
            let node = try readFrontmostAppTree(maxDepth: maxDepth)
            let data = try JSONEncoder().encode(node)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"\(error.localizedDescription)\"}"
        }
    }

    private func buildTree(element: AXUIElement, depth: Int, maxDepth: Int) -> AXNode {
        if depth >= maxDepth {
            return AXNode(
                role: "MAX_DEPTH_REACHED", title: "", description: "", value: "",
                isFocused: false, frame: .init(), children: []
            )
        }

        let role = stringAttribute(element: element, attribute: kAXRoleAttribute) ?? ""
        let title = stringAttribute(element: element, attribute: kAXTitleAttribute) ?? ""
        let desc = stringAttribute(element: element, attribute: kAXDescriptionAttribute) ?? ""

        let rawValue = cfTypeAttribute(element: element, attribute: kAXValueAttribute)
        let value: String
        if let str = rawValue as? String {
            value = str
        } else if let num = rawValue as? NSNumber {
            value = num.stringValue
        } else if let url = rawValue as? URL {
            value = url.absoluteString
        } else {
            value = ""
        }

        let focused = boolAttribute(element: element, attribute: kAXFocusedAttribute) ?? false

        var frame = AXNode.Frame()
        if let positionVal = cfTypeAttribute(element: element, attribute: kAXPositionAttribute) {
            var point = CGPoint.zero
            if AXValueGetValue(positionVal as! AXValue, .cgPoint, &point) {
                frame.x = Double(point.x)
                frame.y = Double(point.y)
            }
        }
        if let sizeVal = cfTypeAttribute(element: element, attribute: kAXSizeAttribute) {
            var size = CGSize.zero
            if AXValueGetValue(sizeVal as! AXValue, .cgSize, &size) {
                frame.width = Double(size.width)
                frame.height = Double(size.height)
            }
        }

        var children: [AXNode] = []
        if let childrenRefs = arrayAttribute(element: element, attribute: kAXChildrenAttribute) {
            for child in childrenRefs {
                let childNode = buildTree(element: child, depth: depth + 1, maxDepth: maxDepth)
                children.append(childNode)
            }
        }

        return AXNode(
            role: role,
            title: title,
            description: desc,
            value: value,
            isFocused: focused,
            frame: frame,
            children: children
        )
    }

    private func stringAttribute(element: AXUIElement, attribute: String) -> String? {
        guard let val = cfTypeAttribute(element: element, attribute: attribute) else { return nil }
        return val as? String
    }

    private func boolAttribute(element: AXUIElement, attribute: String) -> Bool? {
        guard let val = cfTypeAttribute(element: element, attribute: attribute) else { return nil }
        return val as? Bool
    }

    private func arrayAttribute(element: AXUIElement, attribute: String) -> [AXUIElement]? {
        guard let val = cfTypeAttribute(element: element, attribute: attribute) else { return nil }
        return val as? [AXUIElement]
    }

    private func cfTypeAttribute(element: AXUIElement, attribute: String) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value
    }
}
