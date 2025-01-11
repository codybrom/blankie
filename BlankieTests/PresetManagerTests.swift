//
//  PresetManagerTests.swift
//  Blankie
//
//  Created by Cody Bromley on 1/10/25.
//

import XCTest

@testable import Blankie

final class PresetManagerTests: XCTestCase {
  var presetManager: PresetManager!

  override func setUp() {
    super.setUp()
    presetManager = PresetManager.shared
  }

  override func tearDown() async throws {
    // Clean up test presets
    await MainActor.run {
      presetManager.presets
        .filter { !$0.isDefault }
        .forEach { presetManager.deletePreset($0) }
    }
    try await super.tearDown()
  }

  func testCreateNewPreset() async throws {
    let presetName = "Test Preset"

    await MainActor.run {
      presetManager.saveNewPreset(name: presetName)
      XCTAssertTrue(presetManager.presets.contains { $0.name == presetName })
    }
  }

  func testDeletePreset() async throws {
    let presetName = "Test Delete"

    await MainActor.run {
      presetManager.saveNewPreset(name: presetName)

      if let preset = presetManager.presets.first(where: { $0.name == presetName }) {
        presetManager.deletePreset(preset)
        XCTAssertFalse(presetManager.presets.contains { $0.name == presetName })
      } else {
        XCTFail("Failed to create test preset")
      }
    }
  }

  func testUpdatePreset() async throws {
    let originalName = "Original Name"
    let newName = "Updated Name"

    await MainActor.run {
      presetManager.saveNewPreset(name: originalName)

      if let preset = presetManager.presets.first(where: { $0.name == originalName }) {
        presetManager.updatePreset(preset, newName: newName)
        XCTAssertTrue(presetManager.presets.contains { $0.name == newName })
        XCTAssertFalse(presetManager.presets.contains { $0.name == originalName })
      } else {
        XCTFail("Failed to create test preset")
      }
    }
  }
}
