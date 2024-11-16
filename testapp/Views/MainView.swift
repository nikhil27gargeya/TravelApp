import SwiftUI
import FirebaseAuth

struct MainView: View {
    @State private var isSignedIn = Auth.auth().currentUser != nil
    @State private var userId: String? = Auth.auth().currentUser?.uid

    var body: some View {
        VStack {
            if isSignedIn, let unwrappedUserId = userId {
                NavigationStack {
                    GroupView(userId: unwrappedUserId)
                }
            } else {
                NavigationStack {
                    SignInView(onSignIn: handleSignIn)
                }
            }
        }
    }

    private func handleSignIn() {
        // Update state after successful sign-in
        isSignedIn = Auth.auth().currentUser != nil
        userId = Auth.auth().currentUser?.uid
    }
}
