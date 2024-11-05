import SwiftUI

struct GroupView: View {
    @StateObject private var groupManager: GroupManager
    @State private var newGroupName: String = ""
    @State private var joinGroupCode: String = ""
    @State private var isShowingCreateAlert = false
    @State private var isShowingJoinAlert = false

    init(userId: String) {
        _groupManager = StateObject(wrappedValue: GroupManager(userId: userId))
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("TravBank")
                    .font(.largeTitle)
                    .padding()

                List {
                    ForEach(groupManager.groups) { group in
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

                HStack {
                    Button("Create Group") {
                        isShowingCreateAlert.toggle()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Join Group") {
                        isShowingJoinAlert.toggle()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Your Groups")
            .alert("Create New Group", isPresented: $isShowingCreateAlert) {
                TextField("Group Name", text: $newGroupName)
                Button("Create", action: createGroup)
                Button("Cancel", role: .cancel) { }
            }
            .alert("Join Group", isPresented: $isShowingJoinAlert) {
                TextField("Enter Group Code", text: $joinGroupCode)
                Button("Join", action: joinGroup)
                Button("Cancel", role: .cancel) { }
            }
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
}
