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
