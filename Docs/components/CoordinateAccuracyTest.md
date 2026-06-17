# CoordinateAccuracyTest.swift

**Path:** `OpenOSUse/OpenOSUse/CoordinateAccuracyTest.swift`

A diagnostic utility that validates the vision-canvas → physical-Retina coordinate transform. It is triggered by the **Test Coordinates** button in the dashboard.

## What It Does

1. **Prints a mapping table** — for each of the four screen corners (top-left, top-right, bottom-right, bottom-left), it computes:
   - The canvas coordinate (0,0 or 1280,0 or 1280,captureHeight or 0,captureHeight)
   - The scaled physical coordinate via `CoordinateScaler.mapToPhysical()`
   - The expected physical coordinate from the display bounds
   - The delta between computed and expected

2. **Visually clicks each corner** — after a 3-second delay, the cursor moves to each corner and clicks, allowing the operator to watch where the cursor lands and verify alignment

## Why It Exists

When the LLM says "click at (640, 360)", that coordinate is in the 1280px canvas space. The `CoordinateScaler` must map it to the actual display's Retina points (e.g., 1728×972 on a 14" MacBook Pro). Any scaling error causes the click to miss its target.

## Expected Output

```
========== Coordinate Accuracy Test ==========
[top-left]     canvas:(0, 0)     → physical:(0.0, 0.0)      expected:(0.0, 0.0)      Δ:(0.0, 0.0)
[top-right]    canvas:(1280, 0)  → physical:(1512.0, 0.0)   expected:(1512.0, 0.0)   Δ:(0.0, 0.0)
[bottom-right] canvas:(1280, 853)→ physical:(1512.0, 983.0) expected:(1512.0, 983.0) Δ:(0.0, 0.0)
[bottom-left]  canvas:(0, 853)   → physical:(0.0, 983.0)    expected:(0.0, 983.0)    Δ:(0.0, 0.0)

Clicking corners in 3 seconds – watch the cursor…
Clicking top-left at (0, 0)
Clicking top-right at (1512, 0)
Clicking bottom-right at (1512, 983)
Clicking bottom-left at (0, 983)
========== Test complete ==========
```
