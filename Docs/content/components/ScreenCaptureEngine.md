# ScreenCaptureEngine.swift

**Path:** `OpenOSUse/OpenOSUse/ScreenCaptureEngine.swift`

A singleton that uses `ScreenCaptureKit` (`SCStream`) to capture the main display at ~30 fps and provides a blocking `captureScreenshot()` method for the agent loop.

## Configuration

| Setting | Value |
|---|---|
| Max dimension | 1280 px (width; height scales to maintain aspect ratio) |
| Frame rate | ~30 fps (`CMTime(value: 1, timescale: 30)`) |
| Pixel format | 32BGRA |
| Cursor | Visible (`showsCursor = true`) |
| Output format | JPEG, compression 0.7 |

## Methods

| Method | Behaviour |
|---|---|
| `startCaptureIfNeeded()` | Starts the SCStream if not already running; returns `true` on success |
| `startCapture()` | Configures `SCContentFilter(display:excludingWindows:)`, creates `SCStream`, adds `self` as `SCStreamOutput`, starts capture |
| `stopCapture()` | Stops the stream and clears the last frame buffer |
| `captureScreenshot(timeout:)` | Polls `captureCurrentFrame()` for up to `timeout` seconds, returns JPEG `Data` or `nil` |
| `captureCurrentFrame()` | Returns the most recent frame as JPEG data |

## Stream Output

The class conforms to `SCStreamOutput` and receives frames on a serial dispatch queue (`com.daksh.openosuse.screencapture`). Each frame is stored under `NSLock` protection:

```swift
func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
    guard outputType == .screen, let imageBuffer = sampleBuffer.imageBuffer else { return }
    lock.withLock { lastFrame = imageBuffer }
}
```

## Key Details

- Uses `CIContext` with sRGB working color space for accurate color reproduction
- `captureSize` property returns the logical canvas size (1280 × scaled height) that the vision model "sees"
- The blocking poll in `captureScreenshot(timeout:)` sleeps 50ms between attempts
