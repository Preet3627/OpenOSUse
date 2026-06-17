import Cocoa
import CoreGraphics

// ---------------------------------------------------------------------------
// Run from the SwiftUI dashboard or a unit test to verify that the
// vision-canvas → physical-Retina coordinate transform is exact.
// ---------------------------------------------------------------------------

@MainActor
struct CoordinateAccuracyTest {

    /// The capture width used by ScreenCaptureEngine (must match).
    static let captureWidth: CGFloat = 1280

    // MARK: - Public entry point

    /// Prints every corner mapping, then visually clicks each of the four
    /// screen corners so you can confirm they landed where expected.
    static func runAll() {
        print("========== Coordinate Accuracy Test ==========")

        let bounds = CGDisplayBounds(CGMainDisplayID())
        let aspect = bounds.width / bounds.height
        let captureHeight = captureWidth / aspect

        let scaler = SystemAutomationEngine.CoordinateScaler(
            captureWidth: captureWidth,
            captureHeight: captureHeight
        )

        let canvasCorners: [(label: String, canvas: CGPoint)] = [
            ("top-left",     CGPoint(x: 0,             y: 0)),
            ("top-right",    CGPoint(x: captureWidth,  y: 0)),
            ("bottom-right", CGPoint(x: captureWidth,  y: captureHeight)),
            ("bottom-left",  CGPoint(x: 0,             y: captureHeight)),
        ]

        // 1 — Print mapping table
        for (label, canvas) in canvasCorners {
            let physical = scaler.mapToPhysical(canvas)
            let expected = expectedPhysicalCorner(label, bounds: bounds)
            let delta = CGPoint(
                x: physical.x - expected.x,
                y: physical.y - expected.y
            )
            print(String(
                format: "[%@] canvas:(%.0f,%.0f) → physical:(%.1f,%.1f)  expected:(%.1f,%.1f)  Δ:(%.1f,%.1f)",
                label, canvas.x, canvas.y,
                physical.x, physical.y,
                expected.x, expected.y,
                delta.x, delta.y
            ))
        }

        // 2 — Visually click each corner (the user can watch where the
        //     cursor lands and verify alignment).  A short delay between
        //     clicks gives you time to see each one.
        print("\nClicking corners in 3 seconds – watch the cursor…")
        Thread.sleep(forTimeInterval: 3)
        for (label, canvas) in canvasCorners {
            let physical = scaler.mapToPhysical(canvas)
            print("Clicking \(label) at (\(Int(physical.x)), \(Int(physical.y)))")
            SystemAutomationEngine.shared.mouseMove(to: physical)
            SystemAutomationEngine.shared.mouseClick(at: physical)
            Thread.sleep(forTimeInterval: 0.6)
        }
        print("========== Test complete ==========\n")
    }

    // MARK: - Private helpers

    /// The "perfect" physical coordinate the scaler *should* produce.
    private static func expectedPhysicalCorner(
        _ label: String,
        bounds: CGRect
    ) -> CGPoint {
        switch label {
        case "top-left":     return CGPoint(x: bounds.minX, y: bounds.minY)
        case "top-right":    return CGPoint(x: bounds.maxX, y: bounds.minY)
        case "bottom-right": return CGPoint(x: bounds.maxX, y: bounds.maxY)
        case "bottom-left":  return CGPoint(x: bounds.minX, y: bounds.maxY)
        default: return .zero
        }
    }
}
