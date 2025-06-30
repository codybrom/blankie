//
//  PresetBackgroundSection.swift
//  Blankie
//
//  Created by Cody Bromley on 1/11/25.
//

import PhotosUI
import SwiftUI

struct PresetBackgroundSection: View {
  @Binding var backgroundImageData: Data?
  @Binding var backgroundBlurRadius: Double
  @Binding var backgroundOpacity: Double

  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isProcessingImage = false

  private let defaultBlurRadius: Double = 20.0
  private let defaultOpacity: Double = 0.5

  private var backgroundSectionColor: Color {
    #if os(macOS)
      Color(NSColor.controlBackgroundColor)
    #else
      Color(.systemGroupedBackground)
    #endif
  }

  private var previewHeight: CGFloat {
    #if os(macOS)
      120
    #else
      180
    #endif
  }

  private var cornerRadius: CGFloat {
    #if os(macOS)
      8
    #else
      12
    #endif
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Background Image Picker
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Background Image")
            .font(.headline)
          Text("9:16 aspect ratio recommended")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        if backgroundImageData != nil {
          Button {
            clearBackground()
          } label: {
            Label("Clear", systemImage: "xmark.circle.fill")
              .labelStyle(.iconOnly)
              .foregroundColor(.secondary)
          }
          .buttonStyle(.borderless)
        }

        PhotosPicker(
          selection: $selectedPhotoItem,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Label(
            backgroundImageData != nil ? "Change" : "Choose",
            systemImage: "photo"
          )
        }
        #if os(iOS)
          .buttonStyle(.bordered)
        #else
          .buttonStyle(.borderedProminent)
        #endif
      }

      // Preview and Controls
      if let imageData = backgroundImageData {
        VStack(alignment: .leading, spacing: 16) {
          // Preview
          backgroundPreview(imageData: imageData)
            .frame(height: previewHeight)
            .cornerRadius(cornerRadius)
            .overlay(
              RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

          // Blur Control
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("Blur")
                .font(.subheadline)
              Spacer()
              Text("\(Int(backgroundBlurRadius))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Slider(value: $backgroundBlurRadius, in: 0...100, step: 1)
              #if os(macOS)
                .controlSize(.small)
              #endif
          }

          // Opacity Control
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("Opacity")
                .font(.subheadline)
              Spacer()
              Text("\(Int(backgroundOpacity * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Slider(value: $backgroundOpacity, in: 0...1, step: 0.05)
              #if os(macOS)
                .controlSize(.small)
              #endif
          }

          // Reset Button
          Button {
            resetToDefaults()
          } label: {
            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
              .font(.caption)
          }
          .buttonStyle(.borderless)
          .foregroundColor(.secondary)
        }
      }

      if isProcessingImage {
        ProgressView()
          .controlSize(.small)
          .frame(maxWidth: .infinity)
      }
    }
    .padding()
    .background(backgroundSectionColor)
    .cornerRadius(cornerRadius)
    .onChange(of: selectedPhotoItem) { _, newItem in
      Task {
        await loadImage(from: newItem)
      }
    }
  }

  @ViewBuilder
  private func backgroundPreview(imageData: Data) -> some View {
    #if os(macOS)
      if let nsImage = NSImage(data: imageData) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .blur(radius: backgroundBlurRadius)
          .opacity(backgroundOpacity)
          .background(Color.black)
      }
    #else
      if let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .blur(radius: backgroundBlurRadius)
          .opacity(backgroundOpacity)
          .background(Color.black)
      }
    #endif
  }

  private func clearBackground() {
    print("🖼️ PresetBackgroundSection: Clearing background image")
    backgroundImageData = nil
    backgroundBlurRadius = defaultBlurRadius
    backgroundOpacity = defaultOpacity
    selectedPhotoItem = nil
  }

  private func resetToDefaults() {
    backgroundBlurRadius = defaultBlurRadius
    backgroundOpacity = defaultOpacity
  }

  private func loadImage(from item: PhotosPickerItem?) async {
    guard let item = item else { return }

    await MainActor.run {
      self.isProcessingImage = true
    }

    do {
      // Try loading as Data first
      if let data = try await item.loadTransferable(type: Data.self) {
        await processAndSetImage(data)
      } else {
        // If that fails, try loading the image representation
        #if os(macOS)
          if let image = try await item.loadTransferable(type: Image.self) {
            // Convert SwiftUI Image to NSImage data
            // This is a fallback - the Data method should work
            print("Warning: Had to use fallback image loading method")
          }
        #else
          if let image = try await item.loadTransferable(type: Image.self) {
            // Convert SwiftUI Image to UIImage data
            // This is a fallback - the Data method should work
            print("Warning: Had to use fallback image loading method")
          }
        #endif
      }
    } catch {
      print("Failed to load image: \(error)")
    }

    await MainActor.run {
      self.isProcessingImage = false
    }
  }

  private func processAndSetImage(_ data: Data) async {
    print("🖼️ PresetBackgroundSection: Processing image data of size: \(data.count) bytes")
    if let processedData = processImage(data: data) {
      print(
        "🖼️ PresetBackgroundSection: Image processed successfully, size: \(processedData.count) bytes"
      )
      await MainActor.run {
        self.backgroundImageData = processedData
        // Set default values if not already set
        if self.backgroundBlurRadius == 0 {
          self.backgroundBlurRadius = defaultBlurRadius
        }
        if self.backgroundOpacity == 0 {
          self.backgroundOpacity = defaultOpacity
        }
        // Clear the selection to allow re-selecting the same image
        self.selectedPhotoItem = nil
        print("🖼️ PresetBackgroundSection: Background image set successfully")
      }
    } else {
      print("🖼️ PresetBackgroundSection: Failed to process image")
    }
  }

  private func processImage(data: Data) -> Data? {
    #if os(macOS)
      guard let image = NSImage(data: data) else { return nil }

      // Resize if needed (max 2048x2048)
      let maxSize: CGFloat = 2048
      var targetSize = image.size

      if image.size.width > maxSize || image.size.height > maxSize {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        targetSize = CGSize(
          width: image.size.width * scale,
          height: image.size.height * scale
        )
      }

      let resizedImage = NSImage(size: targetSize)
      resizedImage.lockFocus()
      image.draw(
        in: NSRect(origin: .zero, size: targetSize),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy,
        fraction: 1.0
      )
      resizedImage.unlockFocus()

      // Convert to JPEG with compression
      guard let tiffData = resizedImage.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
      else { return nil }

      return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])

    #else
      guard let image = UIImage(data: data) else { return nil }

      // Resize if needed (max 2048x2048)
      let maxSize: CGFloat = 2048
      var targetSize = image.size

      if image.size.width > maxSize || image.size.height > maxSize {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        targetSize = CGSize(
          width: image.size.width * scale,
          height: image.size.height * scale
        )
      }

      let renderer = UIGraphicsImageRenderer(size: targetSize)
      let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
      }

      return resizedImage.jpegData(compressionQuality: 0.8)
    #endif
  }
}
