// CarPlaySceneDelegate.swift
// Blankie
//
// Created by Cody Bromley on 4/18/25.
//

#if CARPLAY_ENABLED

import CarPlay
import Foundation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

  private var interfaceController: CPInterfaceController?

  // Core required method - must be implemented exactly like this
  func templateApplicationScene(
    _ scene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    print("🚗 CarPlay: Connected!")
    self.interfaceController = interfaceController

    // Use the shared CarPlayInterface
    CarPlayInterface.shared.setInterfaceController(interfaceController)
  }

  // Optional - handle disconnection
  func templateApplicationScene(
    _ scene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    print("🚗 CarPlay: Disconnected!")
    self.interfaceController = nil
    CarPlayInterface.shared.disconnect()
  }
}

#endif
