#!/usr/bin/env swift

import Foundation

// Credits data structure
struct Credits: Codable {
  var contributors: [String]
  var translators: [String: [String]]
}

// Sound data structures
struct Sound: Codable {
  var title: String
  var soundName: String
  var author: String
  var authorUrl: String?
  var license: String
  var editor: String?
  var editorUrl: String?
  var soundUrl: String
  var description: String
  var note: String?
  var defaultOrder: Int?
  var systemIconName: String?
  var fileName: String?
}

struct SoundsContainer: Codable {
  var sounds: [Sound]
}

// Generate contributor and translator credits table
func generateTranslatorCredits(from credits: Credits) -> String {
  var markdown = ""

  // Add contributor credits if there are any
  if !credits.contributors.isEmpty {
    markdown += "| Contributors |\n"
    markdown += "| ------------ |\n"
    markdown += "| " + credits.contributors.joined(separator: ", ") + " |\n\n"
  }

  // Add translator credits
  markdown += "| Language | Translators |\n"
  markdown += "| -------- | ----------- |\n"

  let sortedLanguages = credits.translators.keys.sorted()

  for language in sortedLanguages {
    let translators = credits.translators[language] ?? []
    markdown += "| \(language) | "

    if translators.isEmpty {
      markdown += "*Contributions welcome!*"
    } else {
      markdown += translators.joined(separator: ", ")
    }

    markdown += " |\n"
  }

  return markdown
}

// Generate sound credits table - kept for potential future use
func generateSoundCredits(from sounds: [Sound]) -> String {
  var markdown = "| Sound | Author | License | Source |\n"
  markdown += "| ----- | ------ | ------- | ------ |\n"

  // Sort sounds by defaultOrder
  let sortedSounds = sounds.sorted { ($0.defaultOrder ?? 999) < ($1.defaultOrder ?? 999) }

  for sound in sortedSounds {
    // Format license nicely
    let licenseDisplay: String
    switch sound.license.lowercased() {
    case "cc0":
      licenseDisplay = "CC0 (Public Domain)"
    case "ccby3":
      licenseDisplay = "CC BY 3.0"
    case "ccby4":
      licenseDisplay = "CC BY 4.0"
    case "publicdomain":
      licenseDisplay = "Public Domain"
    default:
      licenseDisplay = sound.license
    }

    // Create author with optional URL
    let authorDisplay: String
    if let authorUrl = sound.authorUrl, !authorUrl.isEmpty {
      authorDisplay = "[\(sound.author)](\(authorUrl))"
    } else {
      authorDisplay = sound.author
    }

    // Create source with URL
    let sourceDisplay = "[\(sound.soundName)](\(sound.soundUrl))"

    markdown += "| \(sound.title) | \(authorDisplay) | \(licenseDisplay) | \(sourceDisplay) |\n"
  }

  return markdown
}

// Helper function to find file in possible paths
func findFile(in possiblePaths: [String]) -> String? {
  let fileManager = FileManager.default

  for path in possiblePaths where fileManager.fileExists(atPath: path) {
    return path
  }

  return nil
}

// Helper function to write content to file or print to stdout
func outputContent(_ content: String, to outputPath: String?) throws {
  if let outputPath = outputPath {
    try content.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
    print("Credits block written to \(outputPath)")
  } else {
    print(content)
  }
}

// Generate translator and contributor credits
func generateTranslatorCreditsBlock(outputPath: String?) {
  let possibleCreditsFiles = [
    "./Blankie/credits.json",
    "../Blankie/credits.json"
  ]

  guard let creditsPath = findFile(in: possibleCreditsFiles) else {
    print("Error: Cannot find credits.json file")
    exit(1)
  }

  do {
    let creditsData = try Data(contentsOf: URL(fileURLWithPath: creditsPath))
    let credits = try JSONDecoder().decode(Credits.self, from: creditsData)

    // Generate markdown
    let creditsBlock = generateTranslatorCredits(from: credits)

    // Output to stdout or file
    try outputContent(creditsBlock, to: outputPath)
  } catch {
    print("Error generating credits: \(error.localizedDescription)")
    exit(1)
  }
}

// Generate sound credits
func generateSoundCreditsBlock(outputPath: String?) {
  let possibleSoundsFiles = [
    "./Blankie/Resources/sounds.json",
    "../Blankie/Resources/sounds.json"
  ]

  guard let soundsPath = findFile(in: possibleSoundsFiles) else {
    print("Error: Cannot find sounds.json file")
    exit(1)
  }

  do {
    let soundsData = try Data(contentsOf: URL(fileURLWithPath: soundsPath))
    let soundsContainer = try JSONDecoder().decode(SoundsContainer.self, from: soundsData)

    // Generate markdown
    let soundsBlock = generateSoundCredits(from: soundsContainer.sounds)

    // Output to stdout or file
    let soundsOutputPath = outputPath != nil ? outputPath! + ".sounds" : nil
    try outputContent(soundsBlock, to: soundsOutputPath)

    if soundsOutputPath != nil {
      print("Sound credits block written to \(soundsOutputPath!)")
    }
  } catch {
    print("Error generating sound credits: \(error.localizedDescription)")
    exit(1)
  }
}

// Main function
func main() {
  // Parse command line arguments
  let arguments = CommandLine.arguments
  let outputPath = arguments.count > 1 ? arguments[1] : nil
  let generateType = arguments.count > 2 ? arguments[2] : "translators"

  // Generate translator and contributor credits (default)
  if generateType == "translators" || generateType == "all" {
    generateTranslatorCreditsBlock(outputPath: outputPath)
  }

  // Generate sound credits (only if explicitly requested)
  if generateType == "sounds" || generateType == "all" {
    generateSoundCreditsBlock(outputPath: outputPath)
  }
}

main()
