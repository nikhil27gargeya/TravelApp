import SwiftUI
import FirebaseAuth
import AuthenticationServices
// MARK: - Sign In View
struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    var onSignIn: (() -> Void)?

    var body: some View {
        VStack {
            Text("Sign In")
                .font(.largeTitle)
                .padding()

            TextField("Email", text: $email)
                .padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .background(Color.gray.opacity(0.2).cornerRadius(5))

            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2).cornerRadius(5))

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign In") {
                signIn()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)

            NavigationLink(destination: SignUpView(onSignUp: onSignIn)) {
                Text("Don't have an account? Sign Up")
                    .padding()
            }

            Spacer()
        }
        .padding()
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            } else {
                self.errorMessage = nil
                onSignIn?()
            }
        }
    }
}
