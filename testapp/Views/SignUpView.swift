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
            Text("Create an Account")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            TextField("Name", text: $userName)
                .padding()
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
                
            TextField("Email", text: $email)
                .padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )

            SecureField("Password", text: $password)
                .padding()
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
            Spacer()

            Button("Sign Up") {
                signUp()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)
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
