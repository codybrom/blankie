//
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

    func templateApplicationScene(
      _ scene: CPTemplateApplicationScene,
      didConnect interfaceController: CPInterfaceController
    ) {
      print("🚗 CarPlay: Connected!")
      self.interfaceController = interfaceController

      CarPlayInterfaceController.shared.setInterfaceController(interfaceController)
    }

    func templateApplicationScene(
      _ scene: CPTemplateApplicationScene,
      didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
      print("🚗 CarPlay: Disconnected!")
      self.interfaceController = nil
      CarPlayInterfaceController.shared.disconnect()
    }
  }

#endif
