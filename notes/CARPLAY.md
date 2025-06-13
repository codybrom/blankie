# CarPlay Implementation

## Overview

Blankie has a working CarPlay prototype that provides simplified interface to access presets. Building the app with CarPlay to run outside of a simulator, even on your own devices, requires an Apple-approved entitlement granted per developer bundle ID, so the Blankie Xcode project has separate build schemes to support both standard builds (that any contributor can build) and CarPlay-enabled builds (that Blankie's maintainers can use in the future when Blankie's entitlement is approved to build official releases).

## Scheme Details

| Component | Universal | iOS with CarPlay |
|-----------|---------------|---------------|
| **Build Configs** | `Debug`, `Release` | `Debug-CarPlay`, `Release-CarPlay` |
| **Supported Platforms** | All (iOS, macOS, visionOS) | iPhone only |
| **Entitlements** | `Blankie.entitlements` | `Blankie-CarPlay.entitlements` |
| **Info.plist** | `Blankie-Info.plist` | `Blankie-CarPlay.plist` |
| **Scene Generation** | Automatic (`YES`) | Manual (`NO`) |
| **Compiler Flag** | — | `CARPLAY_ENABLED` |

The iOS with CarPlay configuration:

- **Will only allow iOS builds** (CarPlay is not supported on iPad, Mac, or visionOS)
- Uses separate entitlements that include `com.apple.developer.carplay-audio`
- Defines a custom Info.plist with CarPlay scene configuration
- Sets `UIApplicationSceneManifest_Generation` to `NO` for manual scene control
- Defines `CARPLAY_ENABLED` for conditional compilation

## Implementation Files

- **`Blankie-CarPlay.entitlements`** — Adds the CarPlay audio entitlement
- **`Blankie-CarPlay.plist`** — Defines the CarPlay scene configuration
- **`CarPlaySceneDelegate.swift`** — Handles CarPlay scene lifecycle
- **`UI/CarPlayInterface.swift`** — Main CarPlay user interface
- **`UI/CarPlayStatusView.swift`** — CarPlay audio status display

## Development Workflow

To test or build a **non-CarPlay** version of the app for any platform, simply use the default **"Blankie (Universal)"** scheme. Any CarPlay code will be ignored and no special setup is required.

To *test a **CarPlay** version of the app in a simulator*, you can use the **"Blankie (iOS with CarPlay)"** scheme without needing an Apple-approved entitlement. The iOS Simulator includes a CarPlay simulator (via I/O → External Displays → CarPlay).

To **build a CarPlay version of the app for a *non-simulator destination*** you will need to use the **"Blankie (iOS with CarPlay)"** scheme, and you must have an Apple-approved entitlement for your developer bundle ID.

### Conditional Compilation

CarPlay-specific code can be wrapped in compiler directives to ensure it's only included in `Blankie (iOS with CarPlay)` builds:

```swift
#if CARPLAY_ENABLED
// CarPlay-specific implementation
import CarPlay

extension AppDelegate: CPTemplateApplicationSceneDelegate {
    // CarPlay scene delegate methods
}
#endif
```
