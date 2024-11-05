import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var userName = ""
    @State private var errorMessage: String?
    var onSignUp: (() -> Void)?

    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding()

            TextField("Name", text: $userName)
                .padding()
                .background(Color.gray.opacity(0.2).cornerRadius(5))

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

            Button("Sign Up") {
                signUp()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }

    private func signUp() {
        guard !userName.isEmpty else {
            errorMessage = "Name cannot be empty."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            } else if let userId = result?.user.uid {
                self.saveUserToFirestore(userId: userId)
            }
        }
    }

    private func saveUserToFirestore(userId: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": userName,
            "email": email,
            "groupIds": [],
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                self.errorMessage = "Error saving user data: \(error.localizedDescription)"
            } else {
                self.errorMessage = nil
                onSignUp?()
            }
        }
    }
}
