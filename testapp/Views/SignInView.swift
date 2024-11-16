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
            Image("landingpageimage")  // Example image, you can replace with your own
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 300)
                .padding(.top, 50)
            
            Text("Welcome to Travbank 👋")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Email TextField with outlined style
            TextField("Email", text: $email)
                .padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )

            // Password SecureField with outlined style
            SecureField("Password", text: $password)
                .padding()
            
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            // Sign In Button
            Button("Sign In") {
                signIn()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)

            // Sign Up Navigation Link
            NavigationLink(destination: SignUpView(onSignUp: onSignIn)) {
                Text("Don't have an account? Sign Up")
                    .padding()
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Please enter valid email and password"
            } else {
                self.errorMessage = nil
                onSignIn?()
            }
        }
    }
}
