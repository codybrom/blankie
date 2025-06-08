# CarPlay Implementation Guide for Blankie

This guide provides everything needed to implement CarPlay support in Blankie. The app is already approved for CarPlay audio entitlement.

## Resources Created for This Implementation

1. **CarPlayNotes.md** - Comprehensive notes from reviewing all CarPlay documentation, including code examples and implementation details
2. **CarPlayTodo.md** - Tracking document showing which CarPlay docs were reviewed (31 files read, 24 relevant for Blankie)
3. **This Guide** - Step-by-step implementation instructions

## What to Build: 3-Tab CarPlay Interface

### Core Structure

```txt
CPTabBarTemplate (Root)
├── "Presets" Tab → CPListTemplate
├── "Quick Mix" Tab → CPGridTemplate (8 favorite sounds) 
└── "Sounds" Tab → CPListTemplate (all sounds in solo mode)

System Now Playing Button (♫) → CPNowPlayingTemplate.shared
```

### Tab 1: Presets List

- Display all saved presets in a scrollable list
- Show preset name only (keep it simple)
- Currently playing preset shows a checkmark or highlight
- Tapping any preset immediately plays it
- Empty state: "No presets saved - create in iPhone app"
- Consider adding "Recent" section at top with last 3 used presets

### Tab 2: Quick Mix Grid  

- 8-button grid showing most popular sounds
- Each button shows sound icon + name
- Tapping toggles that sound on/off
- Active sounds show highlighted state
- Allows quick mixing without leaving the screen
- Use these 8 sounds: Rain, Waves, Fireplace, White Noise, Wind, Stream, Birds, Coffee Shop

### Tab 3: Sounds List (Solo Mode)

- Scrollable list of ALL available sounds
- Tapping any sound switches to solo mode (only that sound plays)
- Currently playing sound shows with indicator
- Organized alphabetically or by category
- Each row shows sound icon + name

### Now Playing (System Button)

- Users access via the (♫) button in top-right corner
- Update MPNowPlayingInfoCenter with:
  - Title: Current preset name OR "Custom Mix"  
  - Artist: Active sound names (e.g., "Rain + Fireplace")
  - Album: "Blankie"
- Standard play/pause controls work with AudioManager

## Implementation Steps

### Step 1: Configure Entitlements

Add to `Blankie-CarPlay.entitlements`:

```xml
<key>com.apple.developer.carplay-audio</key>
<true/>
```

### Step 2: Update Info.plist

Add to `Blankie-CarPlay.plist`:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>CPTemplateApplicationSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>CPTemplateApplicationScene</string>
                <key>UISceneDelegateClassName</key>
                <string>Blankie.CarPlaySceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

### Step 3: Create File Structure

```txt
Blankie/
├── CarPlay/
│   ├── CarPlaySceneDelegate.swift
│   ├── CarPlayInterfaceController.swift
│   ├── Templates/
│   │   ├── PresetListTemplate.swift
│   │   ├── QuickMixGridTemplate.swift
│   │   └── SoundsListTemplate.swift
│   └── Helpers/
│       └── CarPlayImageProvider.swift
```

### Step 4: Implement CarPlaySceneDelegate

```swift
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ scene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Create tabs
        let presetsTab = createPresetsTemplate()
        let quickMixTab = createQuickMixTemplate()
        let soundsTab = createSoundsTemplate()
        
        // Set root template
        let tabBar = CPTabBarTemplate(templates: [presetsTab, quickMixTab, soundsTab])
        interfaceController.setRootTemplate(tabBar, animated: false)
        
        // Subscribe to AudioManager notifications
        setupAudioManagerObservers()
    }
}
```

### Step 5: Key Integration Points

#### Use Existing Managers

- **AudioManager**: Use directly, don't create CarPlay-specific audio code
- **PresetManager**: Read presets, handle selection
- **Sound**: Use existing sound model and metadata

#### Audio Session Requirements

- Must work when iPhone is locked
- Use `.playback` category (not `.ambient`)
- Deactivate session when not playing
- Handle interruptions (phone calls, Siri, navigation)

#### Image Handling

```swift
// Create light/dark image sets for all sounds
let rainIcon = CPImageSet(
    lightContentImage: UIImage(named: "rain-carplay-light")!,
    darkContentImage: UIImage(named: "rain-carplay-dark")!
)
```

## Testing Checklist

### Simulator Testing

1. Launch CarPlay Simulator (I/O → External Displays → CarPlay)
2. Verify app appears on home screen
3. Test all three tabs load correctly
4. Verify preset selection works
5. Test Quick Mix sound toggling
6. Verify solo mode switching
7. Check Now Playing button shows correct info

### Physical Device Testing  

1. Test with iPhone locked in pocket
2. Verify audio continues during navigation
3. Test Siri interruptions
4. Verify phone call interruptions
5. Test rapid preset switching
6. Check memory usage over time
7. Test on older devices (iPhone 12 or earlier)

## Important Constraints

### Do NOT Include

- Preset creation/editing (too complex while driving)
- Individual volume sliders (use system volume)
- Timer functionality (not safe while driving)
- Custom sound import (built-in sounds only)
- Complex settings or preferences

### Must Handle

- State sync between iPhone and CarPlay
- Proper audio session lifecycle
- High contrast icons for all lighting
- Single-tap interactions only
- Clear visual feedback for all actions

## Success Criteria

1. **3-Second Test**: User can start their favorite preset within 3 seconds
2. **Locked Phone**: Everything works with iPhone locked
3. **Safe Interaction**: All primary actions require only one tap
4. **State Sync**: CarPlay reflects current playback state immediately
5. **Interruption Recovery**: Audio resumes properly after calls/Siri

## Common Pitfalls to Avoid

1. **Don't** create separate data storage for CarPlay
2. **Don't** add complex navigation hierarchies  
3. **Don't** show alerts/errors unless absolutely critical
4. **Don't** require text input anywhere
5. **Don't** animate unnecessarily (distracting while driving)

## Phase 2 Considerations (Future)

- Siri Shortcuts: "Play my Sleep preset"
- Widget in instrument cluster (if supported)
- Seasonal sound suggestions
- Most-used presets bubble to top

## Questions to Answer Before Starting

1. Should Quick Mix remember last state or always start fresh?
2. How many recent presets to show (3, 5, none)?
3. Should sound categories be used in the Sounds list?
4. What happens if a preset references a missing sound?

Remember: The goal is to make Blankie feel like a simple, safe remote control for the iPhone app. When in doubt, choose the simpler option.
