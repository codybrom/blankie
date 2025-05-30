#!/usr/bin/swift

///
/// blanki18n
/// By Cody Bromley
/// MIT License
///
/// This script is used to update the Localizable.xcstrings file with single-language translations in JSON or CSV format
/// To learn more, visit blankie.rest/i18n
///
///  Usage: ./blanki18n.swift path/to/translation.[json|csv] [language_code]
///

import Foundation

// MARK: - CSV Parser

struct CSVRow {
  let key: String
  let target: String
  let state: String
}

func parseCSV(data: String) -> [CSVRow] {
  var rows: [CSVRow] = []
  let lines = data.components(separatedBy: .newlines)

  // Skip header
  for line in lines.dropFirst() where !line.isEmpty {
    let columns = line.components(separatedBy: ",")
      .map { $0.trimmingCharacters(in: .init(charactersIn: "\"")) }

    if columns.count >= 4 {
      rows.append(
        CSVRow(
          key: columns[0],
          target: columns[2],
          state: columns[3]
        ))
    }
  }

  return rows
}

// MARK: - Utilities

func getFilePath() -> String {
  guard CommandLine.arguments.count > 1 else {
    print("Error: Please provide a translation file path")
    print("Usage: ./blanki8n.swift path/to/translation.[json|csv]")
    exit(1)
  }

  return CommandLine.arguments[1]
}

func getLanguageCode() -> String {
  if CommandLine.arguments.count > 2 {
    return CommandLine.arguments[2]
  } else {
    print("\nEnter the language code for these translations (e.g. de, es, fr):")
    guard let inputLangCode = readLine()?.trimmingCharacters(in: .whitespaces),
      !inputLangCode.isEmpty
    else {
      print("Error: Invalid language code")
      exit(1)
    }
    return inputLangCode
  }
}

func readTranslationFile(at path: String) -> [CSVRow] {
  guard let fileData = try? String(contentsOfFile: path, encoding: .utf8) else {
    print("Error: Could not read file at \(path)")
    exit(1)
  }

  guard path.hasSuffix(".csv") else {
    print("Error: Only CSV files are supported")
    exit(1)
  }

  return parseCSV(data: fileData)
}

func readXCStringsFile() -> (json: [String: Any], strings: [String: [String: Any]]) {
  let xcstringsURL = URL(fileURLWithPath: "Blankie/Localizable.xcstrings")

  guard let xcstringsData = try? Data(contentsOf: xcstringsURL) else {
    print("Error: Could not read Localizable.xcstrings")
    exit(1)
  }

  guard let json = try? JSONSerialization.jsonObject(with: xcstringsData) as? [String: Any],
    let strings = json["strings"] as? [String: [String: Any]]
  else {
    print("Error: Could not parse Localizable.xcstrings")
    exit(1)
  }

  return (json: json, strings: strings)
}

func updateTranslations(
  in strings: [String: [String: Any]], with translations: [CSVRow], for langCode: String
) -> ([String: [String: Any]], Int) {
  var updatedStrings = strings
  var updatedCount = 0

  for translation in translations {
    if var entry = strings[translation.key],
      var localizations = entry["localizations"] as? [String: [String: Any]] {

      // Check if the translation has a meaningful value
      let targetValue = translation.target.trimmingCharacters(in: .whitespacesAndNewlines)
      let hasValidTranslation = !targetValue.isEmpty && targetValue != translation.key

      // Add or update the localization for this language
      localizations[langCode] = [
        "stringUnit": [
          "state": hasValidTranslation ? "translated" : "needs_review",
          "value": translation.target,
        ]
      ]

      // Update the entry
      entry["localizations"] = localizations
      updatedStrings[translation.key] = entry
      updatedCount += 1
    }
  }

  return (updatedStrings, updatedCount)
}

func writeUpdatedStrings(
  json: [String: Any], strings: [String: [String: Any]], updatedCount: Int, langCode: String
) {
  let xcstringsURL = URL(fileURLWithPath: "Blankie/Localizable.xcstrings")
  var updatedJson = json
  updatedJson["strings"] = strings

  if let updatedData = try? JSONSerialization.data(
    withJSONObject: updatedJson, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
    let updatedString = String(data: updatedData, encoding: .utf8) {
    try? updatedString.write(to: xcstringsURL, atomically: true, encoding: .utf8)
    print("\nSuccess! Updated \(updatedCount) translations for language: \(langCode)")
  } else {
    print("Error: Could not write updated translations")
    exit(1)
  }
}

// MARK: - Main

func main() {
  print("blanki8n Localization Updater")
  print("===================")

  let filePath = getFilePath()
  let translations = readTranslationFile(at: filePath)
  let langCode = getLanguageCode()

  let (json, strings) = readXCStringsFile()
  let (updatedStrings, updatedCount) = updateTranslations(
    in: strings, with: translations, for: langCode)

  if updatedCount == 0 {
    print("No translations were updated. Check if your keys match the ones in the xcstrings file.")
    exit(1)
  }

  writeUpdatedStrings(
    json: json, strings: updatedStrings, updatedCount: updatedCount, langCode: langCode)
}

main()
