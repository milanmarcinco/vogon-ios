import SwiftUI
import Toasts

struct SignInView: View {
  @Environment(\.authManager) private var authManager
  @Environment(\.presentToast) var presentToast
  @Environment(\.dismiss) private var dismiss

  @State private var email: String = "milan@marcinco.xyz"
  @State private var password: String = "milanmarcinco123"

  @State private var isPending = false

  func signIn() {
    Task {
      do {
        isPending = true

        try await authManager.signIn(
          email: email,
          password: password
        )

        presentToast(
          ToastValue(
            icon: Image(systemName: "checkmark.circle")
              .foregroundStyle(.green),
            message: "Signed in!",
          ))

        isPending = false
        dismiss()
      } catch {
        presentToast(
          ToastValue(
            icon: Image(systemName: "xmark.octagon")
              .foregroundStyle(.red),
            message: "Sign in failed.",
          ))

        isPending = false
      }
    }
  }

  var body: some View {
    List {
      Section {
        TextField("Email", text: $email)
        SecureField("Password", text: $password)

        Button("Sign In", action: signIn)
          .disabled(isPending)
      }
    }
    .navigationTitle("🔒 Sign in")
  }
}
