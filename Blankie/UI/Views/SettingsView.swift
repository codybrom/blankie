import SwiftUI

struct SettingsView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section(
          header: Text("Sounds", comment: "Settings section header for sound management")
        ) {
          NavigationLink(destination: SoundManagementView()) {
            HStack {
              Text("Manage Sounds", comment: "Sound management label")
              Spacer()
              let hiddenCount = AudioManager.shared.sounds.filter { $0.isHidden }.count
              if hiddenCount > 0 {
                Text("\(hiddenCount) hidden")
                  .font(.caption)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(.secondary.opacity(0.3))
                  .foregroundColor(.secondary)
                  .clipShape(Capsule())
              }
            }
          }
        }

      }
      .navigationTitle("Settings")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            dismiss()
          } label: {
            Text("Done", comment: "Settings done button")
          }
        }
      }
    }
  }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
