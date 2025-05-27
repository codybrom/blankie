//
//  Language.swift
//  Blankie
//
//  Created by Cody Bromley on 5/21/25.
//

import Foundation
import SwiftUI

struct Language: Hashable, Identifiable, Equatable {
  let id: String
  let code: String
  let displayName: String
  let icon: String

  init(code: String, displayName: String, icon: String = "flag.fill") {
    self.id = code
    self.code = code
    self.displayName = displayName
    self.icon = icon
  }

  static var system: Language {
    Language(
      code: "system",
      displayName: NSLocalizedString("System", comment: "System default language option"),
      icon: "globe")
  }

  static func == (lhs: Language, rhs: Language) -> Bool {
    lhs.code == rhs.code
  }

  static func getAvailableLanguages() -> [Language] {
    var languages = [Language.system]

    print("🔍 Detecting available app localizations using Bundle.main.localizations")

    // Get all localizations from the app bundle
    let bundleLocalizations = Bundle.main.localizations
    print(
      "📄 Found \(bundleLocalizations.count) localizations in bundle: \(bundleLocalizations.joined(separator: ", "))"
    )

    // Parse the language codes and create Language objects
    for code in bundleLocalizations {
      // Skip development language code (usually "Base")
      if code == "Base" {
        continue
      }

      // Create and add Language object if not already present
      if !languages.contains(where: { $0.code == code }) {
        languages.append(createLanguage(for: code))
      }
    }

    // If we still don't have any languages, try reading from Localizable.xcstrings
    if languages.count <= 1 {
      print("⚠️ No localizations found in bundle, trying Localizable.xcstrings")
      tryReadXCStringsFile(into: &languages)
    }

    // Log the final language list
    print("🔢 Final language list:")
    for lang in languages {
      print("- \(lang.code): \(lang.displayName)")
    }

    // Sort languages by display name but keep system first
    languages.sort {
      if $0.code == "system" { return true }
      if $1.code == "system" { return false }
      return $0.displayName < $1.displayName
    }

    return languages
  }

  private static func tryReadXCStringsFile(into languages: inout [Language]) {
    guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") else {
      print("❌ Localizable.xcstrings not found in bundle")
      return
    }

    print("📄 Found Localizable.xcstrings at: \(url.path)")

    // Extract and process language codes from the file
    let langCodes = extractLanguagesFromXCStrings(at: url)

    // Add the language codes to our list
    addLanguagesToList(codes: langCodes, languages: &languages)
  }

  private static func extractLanguagesFromXCStrings(at url: URL) -> Set<String> {
    var languageCodes = Set<String>()

    do {
      let data = try Data(contentsOf: url)
      print("📊 Read \(data.count) bytes from file")

      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        print("⚠️ Failed to parse JSON from xcstrings file")
        return languageCodes
      }

      // Get source language
      if let sourceLanguage = json["sourceLanguage"] as? String {
        print("🌐 Source language: \(sourceLanguage)")
        languageCodes.insert(sourceLanguage)
      }

      // Extract language codes from strings
      if let strings = json["strings"] as? [String: [String: Any]] {
        // Look through strings to collect language codes
        for (_, stringData) in strings {
          if let localizations = stringData["localizations"] as? [String: Any],
            !localizations.isEmpty
          {
            for langCode in localizations.keys {
              languageCodes.insert(langCode)
            }
          }
        }
      }

      print("🌐 Found language codes in xcstrings: \(languageCodes.joined(separator: ", "))")
    } catch {
      print("❌ Error reading .xcstrings file: \(error)")
    }

    return languageCodes
  }

  private static func addLanguagesToList(codes: Set<String>, languages: inout [Language]) {
    // Add each language code if not already in our list
    for code in codes where !languages.contains(where: { $0.code == code }) {
      languages.append(createLanguage(for: code))
    }
  }

  private static func createLanguage(for code: String) -> Language {
    // Get the display name in the language's own locale
    let locale = Locale(identifier: code)
    let displayName = locale.localizedString(forIdentifier: code) ?? code
    return Language(code: code, displayName: displayName)
  }

  static func applyLanguage(_ language: Language) {
    print("🌐 Changing language to: \(language.code)")

    // Store the language preference
    if language.code == "system" {
      print("🌐 Removing AppleLanguages key to use system default")
      UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    } else {
      print("🌐 Setting AppleLanguages to: [\(language.code)]")
      UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
    }

    UserDefaults.standard.synchronize()
    resetBundleLocalization()
    NotificationCenter.default.post(name: Notification.Name("LanguageDidChange"), object: nil)

  }

  private static func resetBundleLocalization() {
    // This is a partial solution - it will refresh some text but not all UI elements
    let value = UserDefaults.standard.object(forKey: "AppleLanguages")
    let languages = value as? [String] ?? Locale.preferredLanguages

    print("🌐 Attempting to refresh localization with languages: \(languages)")

    // Try to force UI refresh
    // This is a hack and only works partially
    _ = Bundle.main.localizations  // Use discard pattern to silence warning
    NotificationCenter.default.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
  }

  static func restartApp() {
    let url = Bundle.main.bundleURL
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-n", url.path]

    // Store a flag to indicate we're restarting
    UserDefaults.standard.set(true, forKey: "AppIsRestarting")
    UserDefaults.standard.synchronize()

    // Allow some time for UserDefaults to sync before quitting
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      task.launch()
      NSApplication.shared.terminate(nil)
    }
  }
}
