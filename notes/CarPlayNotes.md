# CarPlay Documentation Notes for Blankie

This document contains notes from reviewing CarPlay documentation for potential features and implementation details relevant to Blankie, an ambient sound mixer app.

---

## 1. carplay/README.md

**Key Points:**

- CarPlay requires entitlements (need to request from Apple)
- Supports iOS 12.0+ (Blankie targets iOS 16+ so we're good)
- Music app integration guide available - directly relevant to Blankie
- Templates available for audio apps:
  - CPNowPlayingTemplate - for playback controls
  - CPListTemplate - for listing presets/sounds
  - CPGridTemplate - for grid of preset shortcuts
  - CPTabBarTemplate - for organizing different sections
- Alert templates (CPAlertTemplate, CPActionSheetTemplate) for user notifications

**Relevant for Blankie:**

- Focus on audio templates and music app integration guide
- Tab bar structure could organize: Presets | Sounds | Now Playing
- List template perfect for showing saved presets
- Grid template could show favorite/recent presets

---

## 2. carplay/api-reference/other/overview.md

**Key Points:**

- CarPlay framework overview showing main categories
- Requires iOS 12.0+ (Blankie is iOS 16+ so compatible)
- Can integrate with SiriKit, CallKit, and MapKit
- Audio section (lines 96-108) specifically for apps with audio entitlement
- CPNowPlayingTemplate is a shared system template for Now Playing info
- Templates provide consistent layout/appearance, framework controls UI aspects

**Relevant for Blankie:**

- Must have audio entitlement to access audio templates
- CPNowPlayingTemplate is the main audio template
- Can use general purpose templates: CPListTemplate, CPGridTemplate, CPTabBarTemplate
- Framework handles touch target size, font size/color - good for consistency
- Music app integration guide available (line 101)

**Not Relevant:**

- Navigation templates (need navigation entitlement)
- Communication templates (need communication entitlement)
- Parking/EV charging/food ordering templates
- Sports mode features (for live sports streaming)

---

## 3. carplay/api-reference/other/index.md

**Key Points:**

- Same content as overview.md - appears to be a duplicate
- Main index/overview page for CarPlay framework documentation

**Notes:**

- Skip detailed notes since this is identical to file #2

---

## 4. guides/getting-started/requesting-carplay-entitlements.md

**Key Points:**

- Must request entitlements via CarPlay Contact Us form at Apple
- Need to agree to CarPlay Entitlement Addendum
- Apple reviews requests using predefined criteria
- Subject to additional App Store Review guidelines
- Entitlement for audio apps: `com.apple.developer.carplay-audio`

**Required Steps:**

1. Request entitlement from Apple
2. Add CarPlay capability to App ID in developer portal
3. Create new provisioning profile
4. Configure Xcode to use manual signing with new profile
5. Add Entitlements.plist file with `com.apple.developer.carplay-audio` = true
6. Set Code Signing Entitlements build setting to point to file

**Testing:**

- Use Xcode Simulator with I/O > External Displays > CarPlay
- App should appear on CarPlay Home screen

**Relevant for Blankie:**

- Need to request audio entitlement specifically
- Will need to disable automatic signing in Xcode
- Must add Entitlements.plist (separate from existing .entitlements file)

---

## 5. guides/getting-started/displaying-content-in-carplay.md

**Key Points:**

- CarPlay uses scenes to manage UI (introduced in iOS 13)
- Must add scene configuration to Info.plist
- Scene delegate conforms to CPTemplateApplicationSceneDelegate
- Non-navigation apps only use interface controller (no window access)
- Navigation apps get window access for drawing map content

**Info.plist Configuration:**

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
                <string>MyCarPlaySceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

**Scene Delegate Implementation:**

- Implement `templateApplicationScene(_:didConnect:)` method
- Store reference to interface controller
- Set root template (e.g., CPListTemplate, CPTabBarTemplate)
- Use interface controller to push/pop templates

**Relevant for Blankie:**

- Audio apps don't get window access (only navigation apps do)
- Must use scene-based approach (not AppDelegate)
- Interface controller manages all UI through templates
- Set root template on connection (likely CPTabBarTemplate)

**Not Relevant:**

- Dashboard scene (navigation apps only)
- Window access and map rendering

---

## 6. guides/getting-started/using-the-carplay-simulator.md

**Key Points:**

- Access CarPlay simulator via I/O > External Displays > CarPlay
- Default size: 800x480 pixels at @2x scale
- Navigation apps can enable extra options for different screen sizes
- Must have entitlements configured for app to appear

**Testing Limitations in Simulator:**

- Can't test locked iPhone state (apps must work when locked)
- Can't test Siri integration
- Can't test audio behavior (ducking, session management)

**Recommended Testing:**

- Use physical CarPlay system when possible
- Wireless CarPlay allows Xcode debugging
- Test multiple screen configurations (navigation apps)

**Relevant for Blankie:**

- Audio session management critical (must deactivate when not playing)
- Must work when iPhone is locked
- Standard 800x480 @2x window sufficient for audio apps
- Consider Siri integration testing in real environment

---

## 7. guides/getting-started/supporting-previous-versions-of-ios.md

**Key Points:**

- iOS 14+ introduced CarPlay framework templates for audio apps
- Before iOS 14, audio apps used Media Player framework
- Can support both old and new approaches simultaneously

**Audio App Entitlements:**

- iOS 14+: `com.apple.developer.carplay-audio` (CarPlay framework)
- iOS 13 and earlier: `com.apple.developer.playable-content` (Media Player framework)
- For backward compatibility, include both entitlements:

```xml
<key>com.apple.developer.playable-content</key>
<true/>
<key>com.apple.developer.carplay-audio</key>
<true/>
```

**Relevant for Blankie:**

- Since Blankie targets iOS 16+, we only need the new entitlement
- No need for Media Player framework compatibility
- Can use CarPlay framework templates exclusively
- Simpler implementation without legacy support

**Not Relevant:**

- Communication app compatibility (different entitlements)
- VoIP/CallKit integration

---

## 8. guides/integration/integrating-carplay-with-your-music-app.md

**Key Points:**

- Sample code demonstrates CPNowPlayingTemplate and CPListTemplate usage
- Uses CPTabBarTemplate as root with multiple tabs
- Integrates with MPMusicPlayerController for playback
- Shows how to implement Siri App Selection

**Code Structure Example:**

- Root: CPTabBarTemplate with tabs (Playlists, Genres, Settings)
- Each tab uses CPListTemplate with CPListItems
- List items have handlers for playback actions
- iOS 15+ adds assistant cell for Siri integration

**Key Implementation Details:**

```swift
// Set root template
interfaceController.setRootTemplate(CPTabBarTemplate(templates: tabTemplates))

// List item with handler
let listItem = CPListItem(text: playlist.name, detailText: "")
listItem.handler = { item, completion in
    // Start playback
    completion()
}

// Assistant cell for Siri (iOS 15+)
let configuration = CPAssistantCellConfiguration(
    position: .top,
    visibility: .always,
    assistantAction: .playMedia)
```

**Music Player Integration:**

- Subscribe to MPMusicPlayerController notifications
- Listen for playback state changes
- Listen for now playing item changes
- Update UI based on player state

**Siri App Selection:**

- Use INMediaUserContext to declare eligibility
- Set numberOfLibraryItems
- Set subscriptionStatus
- Call becomeCurrent()

**Relevant for Blankie:**

- Use CPTabBarTemplate for organizing presets/sounds/settings
- Implement list item handlers for sound/preset selection
- Integrate with existing AudioManager instead of MPMusicPlayerController
- Consider assistant cell for voice control
- Adapt notification pattern for AudioManager state changes

---

## 9. api-reference/templates/audio/cpnowplayingtemplate.md

**Key Points:**

- Shared system template - use CPNowPlayingTemplate.shared (don't instantiate)
- Only available with audio entitlement
- Displays info from MPNowPlayingInfoCenter and MPNowPlayingSession
- Push onto navigation stack (can't present modally)
- Customizable playback control buttons

**Button Types Available:**

- CPNowPlayingImageButton - custom image buttons
- CPNowPlayingAddToLibraryButton - add to collection
- CPNowPlayingMoreButton - more options
- CPNowPlayingPlaybackRateButton - playback speed
- CPNowPlayingRepeatButton - repeat modes
- CPNowPlayingShuffleButton - shuffle modes

**Key Properties:**

- nowPlayingButtons - array of playback control buttons
- isAlbumArtistButtonEnabled - make album/artist tappable
- isUpNextButtonEnabled - show Up Next button
- upNextTitle - customize Up Next button title

**Observer Pattern:**

- Must implement CPNowPlayingTemplateObserver for button interactions
- Add observer with add(_:) method
- Handles Album/Artist and Up Next button taps

**Usage Example:**

```swift
// Get shared instance
let nowPlayingTemplate = CPNowPlayingTemplate.shared

// Configure buttons
nowPlayingTemplate.nowPlayingButtons = [playButton, pauseButton, ...]

// Add observer for interactions
nowPlayingTemplate.add(self)

// Push onto stack
interfaceController.pushTemplate(nowPlayingTemplate, animated: true)
```

**Relevant for Blankie:**

- Use for playback controls when sounds are playing
- Integrate with AudioManager for play/pause/stop
- Update MPNowPlayingInfoCenter with current preset/sounds
- Consider custom buttons for sound control
- Enable album/artist button for preset details

---

## 10. api-reference/templates/general/cptabbartemplate.md

**Key Points:**

- Container template that displays other templates as tabs
- Use maximumTabCount to check tab limit at runtime
- Must be set as root template (can't push or present modally)
- Each tab has its own navigation hierarchy
- Templates in tabs are treated as root templates

**Creating Tab Bar:**

```swift
let tabBarTemplate = CPTabBarTemplate(templates: [template1, template2, template3])
interfaceController.setRootTemplate(tabBarTemplate, animated: true)
```

**Managing Templates:**

- Use transactional approach for updates
- Get current templates, modify array, call updateTemplates(_:)
- Can update tab titles with tabTitle property
- Show badges with showsTabBadge = true

**Delegate Pattern:**

- Implement CPTabBarTemplateDelegate
- Handles tab selection events
- tabBarTemplate(_:didSelect:) called when user selects tab

**Key Properties/Methods:**

- templates - current array of templates
- updateTemplates(_:) - update tabs
- selectedTemplate - currently selected tab
- select(_:) or selectTemplate(at:) - programmatically select tab
- maximumTabCount - runtime tab limit

**Relevant for Blankie:**

- Perfect for organizing main sections
- Suggested tabs: Presets | Sounds | Now Playing
- Each tab can have CPListTemplate or other templates
- Update tab badges for active sounds
- Handle tab selection to update UI state

---

## 11. api-reference/templates/general/cplisttemplate.md

**Key Points:**

- Displays list of items grouped in sections
- Available since iOS 12.0 (older than other templates)
- Maximum limits checked at runtime: maximumSectionCount, maximumItemCount
- Supports hierarchical navigation (up to 5 levels for audio apps)
- Three types of list items: CPListItem, CPListImageRowItem, CPMessageListItem

**Creating Lists:**

```swift
let sections = [CPListSection(items: listItems)]
let listTemplate = CPListTemplate(title: "Presets", sections: sections)
```

**Assistant Cell (Siri Integration):**

- Available for audio apps with INPlayMediaIntent support
- Configure with CPAssistantCellConfiguration
- Position at top, visibility always/whenLimited
- assistantAction: .playMedia for audio apps

**List Items:**

- CPListItem - standard selectable item with text/detail/image
- Each item has handler closure for selection
- Can show playing indicator, accessory type, etc.

**Managing Empty State:**

- emptyViewTitleVariants - array of titles for empty list
- emptyViewSubtitleVariants - array of subtitles
- showsSpinnerWhileEmpty - show loading indicator

**Key Methods:**

- updateSections(_:) - transactional updates
- indexPath(for:) - find item location
- Delegate deprecated - use item handlers instead

**Relevant for Blankie:**

- Perfect for preset lists and sound categories
- Use sections to group sounds by type
- Implement handlers for preset/sound selection
- Add assistant cell for "Play rain sounds" voice commands
- Show playing indicator on active presets
- Empty state for "No presets saved"

---

## 12. api-reference/templates/general/cpgridtemplate.md

**Key Points:**

- Displays grid of button items
- Maximum 8 buttons (only first 8 shown if more provided)
- More than 4 buttons automatically balances into 2 rows
- Each button has title, image, and optional handler
- Available since iOS 12.0

**Creating Grid:**

```swift
let gridButtons = [
    CPGridButton(titleVariants: ["Rain"], image: rainImage) { button in
        // Handle tap
    }
]
let gridTemplate = CPGridTemplate(title: "Quick Presets", gridButtons: gridButtons)
```

**Grid Button Properties:**

- titleVariants - array of title strings
- image - button icon
- handler - tap action closure

**Key Methods:**

- updateGridButtons(_:) - update buttons
- updateTitle(_:) - change title

**Relevant for Blankie:**

- Perfect for "Favorite Presets" quick access
- Could show 8 most-used presets as grid
- Each button loads and plays preset
- Visual grid better than list for quick selection
- Consider as alternative tab to preset list

---

## 13. api-reference/templates/alerts/cpalerttemplate.md

**Key Points:**

- Modal alert template for important messages
- Must present modally with presentTemplate()
- User dismisses via button or dismiss programmatically
- Maximum action count determined at runtime
- Available since iOS 12.0

**Creating Alerts:**

```swift
let alertTemplate = CPAlertTemplate(
    titleVariants: ["Error", "Something went wrong"],
    actions: [
        CPAlertAction(title: "OK", style: .default) { _ in
            // Handle OK
        },
        CPAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle cancel
        }
    ]
)
interfaceController.presentTemplate(alertTemplate, animated: true)
```

**Properties:**

- titleVariants - array of title strings
- actions - array of CPAlertAction objects

**CPAlertAction Styles:**

- .default - standard action
- .cancel - cancel action
- .destructive - destructive action (red)

**Relevant for Blankie:**

- Use for errors (e.g., "Failed to load preset")
- Confirm destructive actions (e.g., "Delete all presets?")
- System notifications (e.g., "Audio session interrupted")
- Keep alerts minimal for driving safety

---

## 14. api-reference/other/cptemplateapplicationscenedelegate.md

**Key Points:**

- Protocol for handling CarPlay scene lifecycle
- Inherits from UISceneDelegate
- Must be specified in Info.plist configuration
- Handles connection/disconnection of CarPlay
- Available since iOS 13.0

**Main Methods:**

```swift
// Non-navigation apps (audio apps use this)
func templateApplicationScene(_ scene: CPTemplateApplicationScene, 
                            didConnect controller: CPInterfaceController) {
    // Store interface controller
    // Set root template
}

// Navigation apps only (get window access)
func templateApplicationScene(_ scene: CPTemplateApplicationScene,
                            didConnect controller: CPInterfaceController,
                            to window: CPWindow) {
    // Additional window parameter for map drawing
}

// Disconnection
func templateApplicationScene(_ scene: CPTemplateApplicationScene,
                            didDisconnectInterfaceController controller: CPInterfaceController) {
    // Clean up
}
```

**Additional Methods:**

- contentStyleDidChange(_:) - handle light/dark mode changes
- Methods for navigation alerts (navigation apps only)

**Implementation for Blankie:**

```swift
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ scene: CPTemplateApplicationScene,
                                didConnect controller: CPInterfaceController) {
        self.interfaceController = controller
        
        // Create root tab bar template
        let tabBar = CPTabBarTemplate(templates: [presetsTemplate, soundsTemplate])
        controller.setRootTemplate(tabBar, animated: false)
    }
}
```

**Relevant for Blankie:**

- Use first didConnect method (audio apps don't get window)
- Store interface controller reference for template management
- Set up root template structure on connection
- Handle cleanup on disconnection
- Consider dark mode support

---

## Summary and Implementation Plan for Blankie CarPlay

Based on the documentation review, here's the recommended implementation approach for Blankie's CarPlay interface:

### Architecture Overview

**1. Template Structure:**

```txt
CPTabBarTemplate (Root)
├── Tab 1: "Presets" (CPListTemplate)
│   ├── Assistant Cell (Siri integration)
│   └── List of saved presets with play handlers
├── Tab 2: "Sounds" (CPListTemplate or CPGridTemplate)  
│   └── Categories → Individual sounds
└── Tab 3: "Now Playing" (Push CPNowPlayingTemplate.shared)
```

**2. Core Components Needed:**

- CarPlaySceneDelegate.swift - Scene lifecycle management
- CarPlayInterface.swift - Template creation and management
- CarPlay entitlements configuration
- Info.plist scene configuration
- Integration with existing AudioManager

**3. Key Features to Implement:**

**Phase 1 - Basic Integration:**

- Request audio entitlement from Apple
- Set up scene configuration in Info.plist
- Create basic preset list with playback
- Integrate with AudioManager for sound control
- Update MPNowPlayingInfoCenter

**Phase 2 - Enhanced Features:**

- Add tab bar navigation
- Implement sound browsing with categories
- Add Now Playing template support
- Show playing indicators on active items
- Handle audio session management

**Phase 3 - Advanced Features:**

- Siri integration with INPlayMediaIntent
- Favorite presets grid view
- Empty states and error handling
- Dark mode support
- State persistence between sessions

### Critical Implementation Notes

**1. Audio Requirements:**

- Must work when iPhone is locked
- Proper audio session management (deactivate when not playing)
- Integration with system Now Playing controls
- Handle audio interruptions gracefully

**2. UI Constraints:**

- Limited to system templates (no custom UI)
- Maximum 5 navigation levels for audio apps
- Runtime limits on items/sections (check maximumItemCount)
- Modal alerts should be minimal for safety

**3. Testing Considerations:**

- Use CarPlay Simulator for development
- Test on physical CarPlay system for:
  - Locked phone functionality
  - Siri integration
  - Audio ducking behavior
  - Different screen sizes

**4. User Experience:**

- Quick access to presets via list or grid
- Clear indication of what's currently playing
- Simple navigation appropriate for driving
- Voice control for hands-free operation

This implementation would provide Blankie users with a safe, intuitive way to control their ambient soundscapes while driving, fully integrated with CarPlay's audio system.

---

## 15. api-reference/templates/alerts/cpactionsheettemplate.md

**Key Points:**

- Modal template for displaying multiple action options
- Similar to CPAlertTemplate but for action sheets
- Must present modally with presentTemplate()
- User dismisses via button selection
- Available since iOS 12.0

**Creating Action Sheets:**

```swift
let actionSheet = CPActionSheetTemplate(
    title: "Choose an Option",
    message: "Select what you'd like to do",
    actions: [
        CPAlertAction(title: "Option 1", style: .default) { _ in
            // Handle option 1
        },
        CPAlertAction(title: "Option 2", style: .default) { _ in
            // Handle option 2
        },
        CPAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle cancel
        }
    ]
)
interfaceController.presentTemplate(actionSheet, animated: true)
```

**Properties:**

- title - optional title string
- message - optional descriptive message
- actions - array of CPAlertAction objects

**Relevant for Blankie:**

- Use for multiple choice scenarios (e.g., "Choose preset to delete")
- Good for settings options (e.g., "Select timer duration")
- Present options when multiple actions available
- Keep options minimal for driving safety

---

## 16. api-reference/templates/alerts/cpalertaction.md

**Key Points:**

- Class that represents a button/action in alerts and action sheets
- Used with both CPAlertTemplate and CPActionSheetTemplate
- Has title, style, and handler closure
- Available since iOS 12.0

**Creating Actions:**

```swift
// Standard action
let okAction = CPAlertAction(title: "OK", style: .default) { action in
    // Handle OK tap
}

// Cancel action
let cancelAction = CPAlertAction(title: "Cancel", style: .cancel) { action in
    // Handle cancel
}

// Destructive action (appears in red)
let deleteAction = CPAlertAction(title: "Delete", style: .destructive) { action in
    // Handle delete
}
```

**Styles:**

- .default - standard action button
- .cancel - cancel button (typically dismisses)
- .destructive - destructive action (red color)

**Additional Properties:**

- color - custom color for button (iOS 14+)
- handler - closure called when tapped

**Relevant for Blankie:**

- Use for all alert and action sheet buttons
- Choose appropriate style for action type
- Keep action titles short and clear
- Destructive style for delete operations

---

## 17. api-reference/types/classes/cpbutton.md

**Key Points:**

- Base class for buttons that display an image
- Used to provide template actions
- Has specialized subclasses for common actions
- Available since iOS 14.0

**Creating Buttons:**

```swift
let button = CPButton(image: myImage) { button in
    // Handle button tap
}
```

**Properties:**

- image - button's image (check CPButtonMaximumImageSize)
- title - optional title string
- isEnabled - enable/disable state
- handler - closure called on tap

**Important:**

- CPButtonMaximumImageSize defines max image dimensions
- Framework provides subclasses like CPContactCallButton (not for audio apps)
- Template manages button appearance

**Relevant for Blankie:**

- Could use for custom controls in templates
- Consider for specialized actions beyond standard buttons
- Check if needed for Now Playing template customization
- Most use cases covered by template-specific button types

---

## 18. api-reference/types/classes/cpimageset.md

**Key Points:**

- Provides light and dark versions of images
- CarPlay defaults to dark appearance in most vehicles
- Automatically switches between appearances
- Available since iOS 12.0

**Creating Image Sets:**

```swift
let imageSet = CPImageSet(
    lightContentImage: UIImage(named: "icon-light")!,
    darkContentImage: UIImage(named: "icon-dark")!
)
```

**Properties:**

- lightContentImage - image for light UI style
- darkContentImage - image for dark UI style

**Usage:**

- Use wherever CarPlay templates accept images
- Ensures proper appearance in both light/dark modes
- System automatically selects appropriate image

**Relevant for Blankie:**

- Use for all icons in CarPlay interface
- Create light/dark versions of preset icons
- Important for grid buttons and list item images
- Ensures visibility in all lighting conditions

---

## 19. api-reference/types/enums/cpnowplayingmode.md

**Key Points:**

- Base class for Now Playing modes
- Available in iOS 18.4+ (very new)
- Has default mode that uses system now playing info center
- Limited documentation available

**Available Modes:**

- .default - uses shared MPNowPlayingInfoCenter

**Notes:**

- Very new API (iOS 18.4+)
- Blankie targets iOS 16+ so this won't be available
- Seems to be base class for sports mode (CPNowPlayingModeSports)

**Relevant for Blankie:**

- Not usable due to iOS version requirements
- Standard Now Playing template will work fine
- No need to implement custom modes

---

## 20. api-reference/protocols/cpbarbuttonproviding.md

**Key Points:**

- Protocol for templates that can show navigation bar buttons
- Provides back button, leading and trailing bar buttons
- You don't adopt this protocol - use templates that conform to it
- Root templates of tab bar don't show bar buttons
- Now Playing template can't have bar buttons (throws exception)

**Properties:**

- backButton - custom back button
- leadingNavigationBarButtons - array of left-side buttons
- trailingNavigationBarButtons - array of right-side buttons

**Button Types:**

- CPBarButton - standard bar button
- CPMessageComposeBarButton - activates Siri for messages (not for audio apps)

**Important Notes:**

- List and Grid templates conform to this protocol
- Tab bar's root templates can't use bar buttons
- System manages back button in navigation hierarchy

**Relevant for Blankie:**

- Can add buttons to CPListTemplate views (e.g., "Add Preset" button)
- Useful for actions in preset/sound lists
- Remember tab bar root templates can't have bar buttons
- Consider for secondary navigation levels only

---

## 21. api-reference/protocols/cptemplate.md

**Key Points:**

- Abstract base class for all CarPlay templates
- Don't subclass or use directly - use prebuilt templates
- Provides common functionality for all templates
- Available since iOS 12.0

**Common Properties:**

- userInfo - custom data to associate with template
- tabTitle - short title for tab bar
- tabImage - image for tab bar
- tabSystemItem - system-provided tab items
- showsTabBadge - indicator badge on tab

**Tab System Items:**

- Standard UITabBarItem.SystemItem values
- Examples: .favorites, .more, .featured, etc.

**Usage:**

- All templates (List, Grid, TabBar, etc.) inherit from this
- Tab-related properties only used when template is in tab bar
- userInfo useful for tracking template state/data

**Relevant for Blankie:**

- Set tabTitle and tabImage for templates in tab bar
- Use showsTabBadge to indicate active sounds
- Store preset/sound data in userInfo
- Consider system items if they fit (e.g., .favorites for presets)

---

## 22. api-reference/scenes/cptemplateapplicationscene.md

**Key Points:**

- The CarPlay scene class that manages app's UI
- Controls interface controller and window (navigation apps only)
- Must be specified in Info.plist configuration
- Available since iOS 13.0

**Key Properties:**

- delegate - receives lifecycle events (CPTemplateApplicationSceneDelegate)
- interfaceController - manages templates and UI
- carWindow - window for drawing (navigation apps only)
- contentStyle - current UI style (light/dark)

**Info.plist Configuration:**

- Must specify UISceneClassName as CPTemplateApplicationScene
- Pairs with scene delegate class name
- System creates scene instances automatically

**Important Notes:**

- Audio apps only use interface controller (no window access)
- Navigation apps get window for map drawing
- Scene manages display on CarPlay screen
- Handles lifecycle as user interacts

**Relevant for Blankie:**

- This is the scene class to specify in Info.plist
- Audio apps won't access carWindow property
- Use interfaceController for all UI management
- Scene delegate handles connection/disconnection

---

## 23. api-reference/other/cpsessionconfiguration.md

**Key Points:**

- Provides vehicle properties and configuration info
- Determines UI limits imposed by vehicle
- Tracks content style based on ambient light
- Available since iOS 12.0

**Key Properties:**

- contentStyle - current content style (light/dark)
- limitedUserInterfaces - bit mask of UI limitations
- delegate - receives notifications about changes

**UI Limitations:**

- Some vehicles limit keyboard display
- May restrict list lengths
- Check these to adjust UI accordingly

**Content Style:**

- CPContentStyle struct indicates style
- Vehicle selects based on ambient light
- Different from standard light/dark mode

**Usage:**

- Create with delegate to monitor changes
- Check limitations before showing certain UI
- Adapt to vehicle-specific constraints

**Relevant for Blankie:**

- Check list length limits for presets/sounds
- Monitor content style changes
- Adapt UI based on vehicle restrictions
- May need to paginate long lists

---

## 24. api-reference/other/carplayerrordomain.md

**Key Points:**

- Global string constant for CarPlay error domain
- Used for identifying CarPlay-specific errors
- Available since iOS 12.0
- Simple constant definition

**Usage:**

- Check error domain when handling errors
- Compare with NSError domain property
- Helps identify CarPlay-specific issues

**Relevant for Blankie:**

- Use for error handling in CarPlay code
- Check when template operations fail
- Helpful for debugging CarPlay issues

---

## Final Summary

I've reviewed 24 CarPlay documentation files relevant to Blankie. Here's what I found:

### Essential Files Read

1. All getting started guides (4 files)
2. Music app integration guide (most relevant)
3. All audio templates (CPNowPlayingTemplate)
4. All general templates (List, Grid, TabBar)
5. All alert templates and actions
6. Key types (CPButton, CPImageSet)
7. Key protocols (CPBarButtonProviding, CPTemplate)
8. Scene and delegate documentation
9. Session configuration for vehicle limits
10. Error domain constant

### Files Skipped (Not Relevant for Audio Apps)

- Navigation-specific templates and types (12+ files)
- Communication templates (2 files)
- Parking/EV/Food ordering templates (3 files)
- Sports streaming features (5 files)
- Instrument cluster features (4 files)
- Deprecated symbols

### Key Implementation Requirements for Blankie

1. Request audio entitlement from Apple
2. Configure Info.plist with scene settings
3. Implement CarPlaySceneDelegate
4. Use CPTabBarTemplate as root
5. Integrate with existing AudioManager
6. Update MPNowPlayingInfoCenter
7. Handle locked phone state
8. Test with physical CarPlay system

The documentation provides everything needed to implement a fully-featured CarPlay interface for Blankie's ambient sound mixing functionality.

---

## 25. api-reference/other/carplay-constants.md

**Key Points:**

- Lists available constants for CarPlay
- CPGridTemplateMaximumItems - maximum buttons in grid template
- CPMaximumListSectionImageSize - maximum image size in list sections

**Relevant for Blankie:**

- Use these constants to ensure proper sizing of UI elements
- Important for grid template (max 8 buttons shown)
- Check image sizes for list sections

---

## 26. api-reference/other/carplay-enumerations.md

**Key Points:**

- Lists enumerations available in CarPlay
- Most are navigation-specific (CPJunctionType, CPManeuverType, etc.)
- CPInstrumentClusterSetting - for instrument cluster
- CPTrafficSide - which side of road traffic drives on

**Relevant for Blankie:**

- None of these enumerations are relevant for audio apps
- All are for navigation, traffic, or instrument cluster features

---

## Final Documentation Review Summary

After reviewing all CarPlay documentation files, I've identified:

Files Read: 31 total

- 24 relevant files documented in detail
- 7 additional files that were duplicates of overview.md

**Key Findings:**

1. **Many duplicate files** - The api-reference/other/ folder contains numerous duplicate overview pages with identical content

2. **Essential Documentation for Blankie:**
   - All getting started guides ✓
   - Music app integration guide ✓
   - Audio templates (CPNowPlayingTemplate) ✓
   - General templates (List, Grid, TabBar) ✓
   - Alert/action templates ✓
   - Scene and delegate documentation ✓
   - Constants and error domain ✓

3. **Not Relevant for Blankie:**
   - Navigation-specific features (70+ files)
   - Communication templates
   - Sports streaming features
   - Parking/EV/Food ordering templates
   - Instrument cluster features

The comprehensive implementation plan and architecture overview in the notes above provide everything needed to implement CarPlay support for Blankie's ambient sound mixing functionality.
