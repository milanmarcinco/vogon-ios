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
    if !authManager.initialized || authManager.isError {
      return nil
    }

    if authManager.isAuthenticated {
      return Text("You are currently signed in.")
    } else {
      return Text("You are currently signed out.")
    }
  }

  var body: some View {
    NavigationStack {
      List {
        Section(
          header: Text("Your account"),
          footer: footerText
        ) {
          if !authManager.initialized {
            ProgressView()
          } else {
            if authManager.isError {
              Text("An error occurred while checking your authentication status.")
                .foregroundStyle(.secondary)
            }

            if !authManager.isError {
              if !authManager.isAuthenticated {
                NavigationLink("🔒 Sign in", destination: SignInView())
              }

              if authManager.isAuthenticated {
                Button("🚪 Sign out", action: signOut)
                  .disabled(isPending)
              }
            }
          }
        }
      }
      .navigationTitle("💁‍♂️ Account")
    }
  }
}
