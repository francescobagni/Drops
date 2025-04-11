/*
 
 ⸻

 🧭 Addendum: Finger Lens Onboarding Animation – Investigation Summary (March 27, 2025)

 🔍 Goal:
 Display a tap-style onboarding animation the first time a user enters fullscreen mode. The animation includes a ring and central circle to nudge the user about the finger lens feature.

 🎯 Desired Behavior:
 - A pulse-style animation shows once when the user enters fullscreen mode.
 - It appears centered (or near-bottom), runs for ~1.5s, then fades.
 - It should not repeat after the user taps the screen once in fullscreen.

 🛠️ Implementation Summary:
 - The view is called `PulseHint`, and is conditionally shown inside `AppUI.swift` when `isZoomed && !hasTappedImageInFullscreen && showPulseHint == true`.
 - Animation trigger logic relies on a `@Binding var trigger: Bool`, toggled by `pulseHintTrigger` from `AppUI`.
 - Internally, `PulseHint` uses `.onChange(of: trigger)` and `.onAppear` to call `startAnimation()` which updates `@State` properties like `scale`, `opacity`, and `centerScale`.

 🧪 Debug History:
 - View appears correctly (`🔥 SHOWING pulse hint` printed).
 - Circle renders faintly — initial `scale = 0.2` and `opacity = 0.55` values are shown.
 - **`startAnimation()` never fires**, as confirmed by missing log outputs.
 - `.onChange(of: trigger)` and `.onAppear` are both in place.
 - Manual toggling of `pulseHintTrigger` to `false → true` is performed inside `onZoomToggle`.

 ❗ Suspected Issue:
 SwiftUI optimizations are preventing `PulseHint` from responding to the trigger change.
 Even with `.onChange` placed on the root `ZStack`, it seems the trigger update is not detected due to how the conditional `if show` affects view lifecycle.

 ⛳ Next Steps for GPT Companion:
 - Confirm and isolate whether the view is rebuilt or just re-rendered.
 - Explore if using a `ViewModel` + `ObservableObject` instead of binding would improve reactivity.
 - Consider whether to separate `PulseHint` into a permanently mounted overlay, shown/hidden with opacity and internal trigger flag.
 - Optionally use `.transaction`
 
 */
