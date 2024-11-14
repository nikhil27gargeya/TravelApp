import SwiftUI
import FirebaseAuth
import SwiftUI
import FirebaseAuth

struct GroupView: View {
    @StateObject private var groupManager: GroupManager
    @State private var newGroupName: String = ""
    @State private var joinGroupCode: String = ""
    @State private var isShowingCreateAlert = false
    @State private var isShowingJoinAlert = false
    @Environment(\.presentationMode) var presentationMode

    init(userId: String) {
        _groupManager = StateObject(wrappedValue: GroupManager(userId: userId))
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("TravBank")
                    .font(.largeTitle)
                    .padding()
                
                List {
                    ForEach(groupManager.groups) { group in
                        // Navigation link to ContentView for each group
                        NavigationLink(destination: ContentView(group: group)) {
                            VStack(alignment: .leading) {
                                Text(group.name)
                                Text("Code: \(group.code)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Group actions
                HStack {
                    Button("Create Group") {
                        isShowingCreateAlert.toggle()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Join Group") {
                        isShowingJoinAlert.toggle()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Create New Group", isPresented: $isShowingCreateAlert, actions: {
                TextField("Group Name", text: $newGroupName)
                Button("Create", action: createGroup)
                Button("Cancel", role: .cancel) { }
            })
            .alert("Join Group", isPresented: $isShowingJoinAlert, actions: {
                TextField("Enter Group Code", text: $joinGroupCode)
                Button("Join", action: joinGroup)
                Button("Cancel", role: .cancel) { }
            })
        }
    }

    private func createGroup() {
        guard !newGroupName.isEmpty else { return }
        groupManager.createGroup(name: newGroupName)
        newGroupName = ""
    }

    private func joinGroup() {
        guard !joinGroupCode.isEmpty else { return }
        groupManager.joinGroup(withCode: joinGroupCode)
        joinGroupCode = ""
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
