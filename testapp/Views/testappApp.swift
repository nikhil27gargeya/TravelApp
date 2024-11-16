import SwiftUI
import Firebase  // Import the Firebase module

@main
struct testappApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
