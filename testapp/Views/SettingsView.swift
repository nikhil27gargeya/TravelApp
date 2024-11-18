import SwiftUI
import FirebaseAuth
import Firebase

struct SettingsView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    private let currencies = ["USD", "EUR", "GBP", "INR", "JPY", "AUD", "CAD"]
    
    @State private var userName: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                    Form {
                        Section(header: Text("Default Currency")) {
                            Picker("Currency", selection: $selectedCurrency) {
                                ForEach(currencies, id: \.self) { currency in
                                    Text(currency)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: selectedCurrency) { newValue in
                                saveCurrency(newValue)
                            }
                        }
                        
                        Section(header: Text("User Information")) {
                            TextField("Name", text: $userName)
                                .onAppear {
                                    loadUserName()
                                }
                            
                            Button("Save Name") {
                                saveUserName()
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // Logout Button
                        Section {
                            Button("Logout") {
                                logout()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .navigationTitle("Settings")
                }
        }
    }

    func saveCurrency(_ currency: String) {
        UserDefaults.standard.set(currency, forKey: "currency")
    }
    
    func loadUserName() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data(), let name = data["name"] as? String {
                self.userName = name
            } else {
                self.errorMessage = "Could not load user name."
            }
        }
    }

    func saveUserName() {
        guard let currentUser = Auth.auth().currentUser else {
            self.errorMessage = "No user signed in."
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        userRef.updateData(["name": userName]) { error in
            if let error = error {
                self.errorMessage = "Error updating name: \(error.localizedDescription)"
            } else {
                self.errorMessage = "Name updated successfully."
            }
        }
    }
    
    // Logout Function
    func logout() {
        do {
            try Auth.auth().signOut()  // Sign the user out
            
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
