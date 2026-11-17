import SwiftUI
import Toasts

struct AccountView: View {
  @Environment(\.authManager) private var authManager
  @Environment(\.presentToast) var presentToast

  @State private var isPending = false

  private func signOut() {
    Task {
      isPending = true
      await authManager.signOut()
      isPending = false

      presentToast(
        ToastValue(
          icon: Image(systemName: "checkmark.circle")
            .foregroundStyle(.green),
          message: "Signed out!",
        )
      )
    }
  }

  var footerText: Text? {
    switch authManager.status {
    case .authenticated:
      return Text("You are currently signed in.")
    case .unauthenticated:
      return Text("You are currently signed out.")
    default:
      return nil
    }
  }

  var body: some View {
    NavigationStack {
      List {
        Section(
          header: Text("Your account"),
          footer: footerText
        ) {
          if authManager.status == .pending {
            ProgressView()
          } else {
            if authManager.status == .error {
              Text("An error occurred while checking your authentication status.")
                .foregroundStyle(.secondary)
            }

            if authManager.status == .unauthenticated {
              NavigationLink("🔒 Sign in", destination: SignInView())
            }

            if authManager.status == .authenticated {
              Button("🚪 Sign out", action: signOut)
                .disabled(isPending)
            }
          }
        }
      }
      .navigationTitle("💁‍♂️ Account")
    }
  }
}
