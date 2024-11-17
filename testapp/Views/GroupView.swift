import SwiftUI
import FirebaseAuth
import SwiftUI

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
            VStack {
                List {
                    Text("Current Trips")
                        .font(.title)
                        .padding()
                    ForEach(groupManager.groups) { group in
                        // Navigation link to ContentView for each group
                        NavigationLink(destination: ContentView(group: group)
                            .navigationBarBackButtonHidden(true)
                        ) {
                            VStack(alignment: .leading) {
                                Text(group.name)
                                Text("Code: \(group.code)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Group actions
                HStack {
                    Button("Create Group") {
                        isShowingCreateAlert.toggle()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 20)
                    
                    Button("Join Group") {
                        isShowingJoinAlert.toggle()
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
