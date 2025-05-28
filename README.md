<div align="center">
  <img src="docs/src/assets/icon.png" alt="Blankie logo" width="153" height="128"/>
  
# Blankie

  Ambient sound mixer for macOS
  <p align="center">
    <img src="https://img.shields.io/badge/macOS%2014.6+-111111?style=flat-square&logo=apple&logoColor=white" alt="macOS">
    <img src="https://img.shields.io/badge/Swift%205-F05138?style=flat-square&logo=Swift&logoColor=white" alt="Swift">
    <img src="https://img.shields.io/badge/SwiftUI-0071e3.svg?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI">
    <img src="https://img.shields.io/badge/Xcode%2016-007ACC?style=flat-square&logo=xcode&logoColor=white" alt="Xcode">
    <a href="https://github.com/codybrom/blankie/blob/master/LICENSE"><img src="https://img.shields.io/github/license/codybrom/blankie.svg?style=flat-square" alt="License"></a>
  </p>
  <p align="center"><a href="https://apps.apple.com/us/app/blankie/id6740096581"><img src="docs/src/assets/download-on-mac-app-store.svg" alt="Download on the Mac App Store" width="202"></a></p>
  <p align="center"><img src="docs/src/assets/screenshot.png" alt="Screenshot of Blankie" height="600"></p>
  <p align="center"><a href="https://www.producthunt.com/posts/blankie?embed=true&utm_source=badge-featured&utm_medium=badge&utm_source=badge-blankie"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=968970&theme=neutral&t=1747948853827" alt="Blankie - Open-source ambient sound mixer for macOS | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a></p>
</div>

## Table of Contents

- [Why Blankie?](#why-blankie)
- [Features](#features)
- [Installation](#installation)
- [Contributing](#contributing)
- [Development Setup](#development-setup)
- [Credits](#credits)
- [License](#license--copyright)

## Why Blankie?

In our increasingly noisy world, finding focus and calm can be challenging. Blankie was created to provide a simple, beautiful, and native solution for anyone who wants to:

- 🎯 **Focus deeply** on work or studying
- 😴 **Sleep better** by masking disruptive environmental sounds
- 🧘 **Stay calm** during stressful moments with soothing soundscapes
- 🎨 **Create** an ideal ambient environment for any activity

Inspired by the excellent [Blanket](https://github.com/rafaelmardojai/blanket) for Linux, Blankie brings the same simplicity and effectiveness to Apple's ecosystem.

## Installation

### Mac App Store (Recommended)

The recommended installation method is through the [Mac App Store](https://apps.apple.com/us/app/blankie/id6740096581), which provides automatic updates.

### Direct Download

You can also download the Apple-notarized binary directly from [GitHub Releases](https://github.com/codybrom/blankie/releases/latest/download/Blankie.zip).

### Homebrew

Blankie is also available using Homebrew:

```bash
brew install --cask blankie
```

Visit the [Blankie cask page on brew.sh](https://formulae.brew.sh/cask/blankie) for more information.

### TestFlight Beta Versions

Occasionally, some early macOS releases of Blankie are also available on TestFlight. Join the TestFlight beta to help test new features and provide feedback.

Additionally, Blankie is coming to iOS, iPadOS, and visionOS! You can join the TestFlight beta for these platforms from the same link.

[Join the Blankie TestFlight Beta](https://testflight.apple.com/join/XgpBpWv8)

## Features

- **Includes 14 high-quality ambient sounds**
- Individual volume sliders for each sound
- Save unlimited custom presets for quick preset switching
- Beautiful SwiftUI interface with automatic light/dark mode support and custom accent colors
- System media key and Control Center support

### 🌍 Internationalization & Localization

Blankie automatically uses your system language when available and has support for 7+ languages:

- 🇺🇸 English (US) [default]
- 🇬🇧 English (Great Britain)
- 🇪🇸 Español (Spain) - *Thanks to **Chuskas***
- 🇩🇪 Deutsch\*
- 🇫🇷 Français - *Thanks to **Richard_M***
- 🇮🇹 Italiano (Italian) - *Thanks to **davnr***
- 🇹🇷 Türkçe (Turkish) - *Thanks to **aybarsnazlica***
- 🇨🇳 简体中文 (Chinese, Simplified) – *Thanks to **kur1k0***

\* Currently seeking translators to verify and improve these translations. If you can help, please reach out!

[Help translate Blankie to your language!](https://github.com/codybrom/blankie/blob/main/CONTRIBUTING.md#translation-contributions)

## Contributing

Blankie was built to be shared by the community and we'd love your help!

### Ways to Contribute

- ⭐ **Star this repo** to show your support
- 📱 [Rate on the App Store](https://apps.apple.com/us/app/blankie/id6740096581)
- 🐛 [Report bugs](https://github.com/codybrom/blankie/issues/new?assignees=&labels=bug&projects=&template=bug_report.yml&title=%5BBug%5D%3A+) and help us improve stability
- 💡 [Suggest features](https://github.com/codybrom/blankie/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.yml&title=%5BFeature%5D%3A+) to make Blankie even better
- 🌍 [Translate](https://blankie.rest/contributing/#translation-contributions) Blankie into your language
- 💻 [Write code](https://blankie.rest/contributing/#code-contributions) to fix issues or add features

### Current Priorities

- 🎧 [Custom sound support](https://github.com/codybrom/blankie/issues/1)
- 🌐 [More language translations](https://github.com/codybrom/blankie/blob/main/CONTRIBUTING.md#translation-contributions)
- 🧪 Cross-platform testing of the Universal App beta

See our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) to get started.

## Development Setup

1. **Fork the repository and clone it to your local machine.**

2. **Copy `Configuration.example.xcconfig` to `Configuration.xcconfig`.**
    - Configuration.xcconfig is ignored by git to keep Bundle IDs and Team IDs private. Do not commit this file publicly to protect your work from impersonation, account misuse, and distribution conflicts.

3. **Add your development team to `Configuration.xcconfig`.**

      ```plaintext
      DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
      ```

    - **Apple Developer Program Members:**
        - Retrieve your **Team ID**:
            1. Open Xcode and go to **Xcode > Preferences > Accounts**.
            2. Sign in with your Apple ID if you haven’t already.
            3. Select your account, click **Manage Certificates** or **View Details**, and find your **Team ID** under your account name.
        - Add your Team ID to `Configuration.xcconfig`:

    - **If You Are Not a Member of the Apple Developer Program:**
        - You can still test the app on your devices for free by creating an Xcode **Personal Team**. Follow these steps:
            1. Open Xcode and go to **Xcode > Preferences > Accounts**.
            2. Click the "+" button to add your Apple ID (if not already added).
            3. After signing in, Xcode will automatically create a **Personal Team** associated with your Apple ID.
            4. Go to **Xcode > Preferences > Accounts**, select your account, and click **View Details**. The Team ID for your Personal Team will be listed.
        - Use the Team ID from your Personal Team in `Configuration.xcconfig`:

4. **Set the Bundle Identifier:**

      ```plaintext
      PRODUCT_BUNDLE_IDENTIFIER = com.yournamehere.blankie
      ```

    - In `Configuration.xcconfig`, set `PRODUCT_BUNDLE_IDENTIFIER` to a unique identifier. You can use any reverse domain name format for the bundle identifier, but it must be unique. You **cannot** use the same bundle identifier as the main Blankie app.

5. **Open `Blankie.xcodeproj` in Xcode**

6. **Build and run the project!**

## Documentation

Additional information about Blankie, including an FAQ and more credits, are available on the [Blankie website](https://blankie.rest). The website is created using Astro and hosted on GitHub Pages. The source code is available in the `docs` directory with more info in its own [README](docs/README.md) file.

## Credits

### Special Thanks

An incredibly special thanks to [Rafael Mardojai CM](https://github.com/rafaelmardojai) and all the contributors to the [Blanket](https://github.com/rafaelmardojai/blanket) project which inspired me to build this app when I couldn't find a free, simple and open-source Mac app like it. Please give them a star and support their work!

### Contributors

Thanks to everyone who has contributed to making Blankie better! ✨

<a href="https://github.com/codybrom/blankie/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=codybrom/blankie" alt="Contributors" title="Made with https://contrib.rocks" />
</a>

### Sounds

The sounds in Blankie are used under various open licenses. Full attribution information about sounds and licensing can be found on the Blankie website at [blankie.rest/credits](https://blankie.rest/credits) or on the About screen of the app.

### App Logo / Icon

The Blankie logo and app icon were created by [Cody Bromley](https://github.com/codybrom) and are licensed under a <a href="https://creativecommons.org/licenses/by/4.0/?ref=chooser-v1" target="_blank" rel="license noopener noreferrer">Creative Commons Attribution 4.0 International license <img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1" alt=""></a>

You may share, copy, and adapt the Blankie logo/icon, but you must give appropriate credit, link to the license, and indicate if changes were made.

Press and media may use the Blankie app icon and logo without modification to reference the Blankie app, provided proper attribution is given.

### Sound Icons

Blankie uses [SF Symbols](https://developer.apple.com/sf-symbols/) for sound icons. SF Symbols are provided by Apple as a system resource, with usage governed by the [Xcode and Apple SDKs Agreement](https://www.apple.com/legal/sla/docs/xcode.pdf). They are not stored in this repository and are not covered by Blankie's license.

## License & Copyright

© 2025 Cody Bromley and contributors. All rights reserved.

The Blankie name and trademark rights are reserved. The Blankie logo and app icon are licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

The Blankie source code and website code are copyright Cody Bromley and licensed under the MIT License. Please read Blankie's [LICENSE](LICENSE) for full details. Contributions to Blankie are welcome and will be released under the same license.

Different components of Blankie (such as sounds, icons, or others) may be covered by different licenses. Full attribution information about sounds and licensing for included items is available on the Blankie website at [blankie.rest/credits](https://blankie.rest/credits) and on the About screen of the app.

## Support Development

Blankie is made with love and caffeine and will always be free and open-source. You can support Blankie's ongoing development via [GitHub Sponsors](https://github.com/sponsors/codybrom), [Ko-fi](https://ko-fi.com/codybrom), or [Buy Me a Coffee](https://buymeacoffee.com/codybrom)

---

<div align="center">
  <sub>
    Blankie is an independent macOS application inspired by <a href="https://github.com/rafaelmardojai/blanket">Blanket</a>.<br>
    Built with ❤️ by <a href="https://github.com/codybrom">Cody Bromley</a> and contributors.
  </sub>
</div>
