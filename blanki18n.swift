#!/usr/bin/swift

///
/// blanki18n
/// By Cody Bromley
/// MIT License
///
/// This script is used to update the Localizable.xcstrings file with single-language translations in JSON or CSV format.
/// To learn more, visit blankie.rest/i18n
///
///  Usage: ./blanki18n.swift path/to/translation.[json|csv]
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

// MARK: - Main

func main() {
  print("blanki8n Localization Updater")
  print("===================")

  // Get file path argument
  guard CommandLine.arguments.count > 1 else {
    print("Error: Please provide a translation file path")
    print("Usage: ./blanki8n.swift path/to/translation.[json|csv]")
    exit(1)
  }

  let filePath = CommandLine.arguments[1]

  // Read translation file
  guard let fileData = try? String(contentsOfFile: filePath, encoding: .utf8) else {
    print("Error: Could not read file at \(filePath)")
    exit(1)
  }

  // Parse CSV file
  guard filePath.hasSuffix(".csv") else {
    print("Error: Only CSV files are supported")
    exit(1)
  }

  let translations = parseCSV(data: fileData)

  // Get language code from user
  print("\nEnter the language code for these translations (e.g. de, es, fr):")
  guard let langCode = readLine()?.trimmingCharacters(in: .whitespaces),
    !langCode.isEmpty
  else {
    print("Error: Invalid language code")
    exit(1)
  }

  // Read existing Localizable.xcstrings
  let xcstringsURL = URL(fileURLWithPath: "Blankie/Localizable.xcstrings")

  guard let xcstringsData = try? Data(contentsOf: xcstringsURL) else {
    print("Error: Could not read Localizable.xcstrings")
    exit(1)
  }

  // Parse as JSON to work with the data structure
  guard let json = try? JSONSerialization.jsonObject(with: xcstringsData) as? [String: Any],
    var strings = json["strings"] as? [String: [String: Any]]
  else {
    print("Error: Could not parse Localizable.xcstrings")
    exit(1)
  }

  var updatedCount = 0

  // Go through each translation
  for translation in translations {
    if var entry = strings[translation.key],
      var localizations = entry["localizations"] as? [String: [String: Any]]
    {

      // Add or update the localization for this language
      localizations[langCode] = [
        "stringUnit": [
          "state": translation.state,
          "value": translation.target,
        ]
      ]

      // Update the entry
      entry["localizations"] = localizations
      strings[translation.key] = entry
      updatedCount += 1
    }
  }

  if updatedCount == 0 {
    print("No translations were updated. Check if your keys match the ones in the xcstrings file.")
    exit(1)
  }

  // Update the JSON structure
  var updatedJson = json
  updatedJson["strings"] = strings

  // Write back with formatting preserved
  if let updatedData = try? JSONSerialization.data(
    withJSONObject: updatedJson, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
    let updatedString = String(data: updatedData, encoding: .utf8)
  {
    try? updatedString.write(to: xcstringsURL, atomically: true, encoding: .utf8)
    print("\nSuccess! Updated \(updatedCount) translations for language: \(langCode)")
  } else {
    print("Error: Could not write updated translations")
    exit(1)
  }
}

main()
