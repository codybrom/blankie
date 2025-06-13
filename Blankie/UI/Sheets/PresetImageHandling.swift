//
//  PresetImageHandling.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  import PhotosUI
#elseif os(macOS)
  import AppKit

  extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
      guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
      }
      let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
      return bitmapRep.representation(
        using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
  }
#endif

// MARK: - macOS Image Handling
#if os(macOS)
  extension EditPresetSheet {
    func handleMacOSImageImport(_ result: Result<[URL], Error>) {
      switch result {
      case .success(let urls):
        guard let url = urls.first else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
          if accessing {
            url.stopAccessingSecurityScopedResource()
          }
        }

        do {
          let data = try Data(contentsOf: url)
          if let nsImage = NSImage(data: data) {
            if abs(nsImage.size.width - nsImage.size.height) < 1 {
              artworkData = nsImage.jpegData(compressionQuality: 0.8)
            } else {
              let squareImage = cropToSquareMacOS(image: nsImage)
              artworkData = squareImage.jpegData(compressionQuality: 0.8)
            }
          } else {
            artworkData = data
          }
        } catch {
          print("❌ macOS Image Picker: Failed to load image: \(error)")
        }
      case .failure(let error):
        print("❌ macOS Image Picker: Image picker error: \(error)")
      }
    }

    private func cropToSquareMacOS(image: NSImage) -> NSImage {
      let size = min(image.size.width, image.size.height)
      let offsetX = (image.size.width - size) / 2
      let offsetY = (image.size.height - size) / 2
      let cropRect = NSRect(x: offsetX, y: offsetY, width: size, height: size)

      guard
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(
          to: cropRect)
      else {
        return image
      }

      return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
  }
#endif

#if os(iOS) || os(visionOS)
  struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
      let picker = UIImagePickerController()
      picker.delegate = context.coordinator
      picker.sourceType = .photoLibrary
      picker.allowsEditing = false
      return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
      let parent: ImagePicker

      init(_ parent: ImagePicker) {
        self.parent = parent
      }

      func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
      ) {
        if let image = info[.originalImage] as? UIImage {
          parent.selectedImage = image
        }
        parent.dismiss()
      }

      func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.dismiss()
      }
    }
  }

  struct ImageCropperView: View {
    @Binding var originalImage: UIImage?
    @Binding var croppedImageData: Data?
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    private let cropSize: CGFloat = 300

    var body: some View {
      NavigationView {
        GeometryReader { geometry in
          let imageSize = originalImage?.size ?? CGSize(width: 1, height: 1)
          let aspectRatio = imageSize.width / imageSize.height

          let fitWidth = min(geometry.size.width * 0.8, cropSize * 3)
          let fitHeight = fitWidth / aspectRatio

          ZStack {
            Color.black.ignoresSafeArea()

            if let image = originalImage {
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: fitWidth, height: fitHeight)
                .scaleEffect(scale)
                .offset(dragOffset)
                .gesture(
                  SimultaneousGesture(
                    DragGesture()
                      .onChanged { value in
                        dragOffset = value.translation
                      },
                    MagnificationGesture()
                      .onChanged { value in
                        scale = lastScale * value
                      }
                      .onEnded { _ in
                        lastScale = scale
                      }
                  )
                )
            }

            Rectangle()
              .stroke(Color.white, lineWidth: 2)
              .frame(width: cropSize, height: cropSize)
              .allowsHitTesting(false)
          }
        }
        .navigationTitle("Crop Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
              dismiss()
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              cropImage()
            }
          }
        }
      }
    }

    private func cropImage() {
      guard let image = originalImage else { return }

      let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
      let croppedImage = renderer.image { _ in
        image.draw(in: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
      }

      croppedImageData = croppedImage.jpegData(compressionQuality: 0.8)
      dismiss()
    }
  }
#endif
