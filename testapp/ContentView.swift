import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    var group: Group
    @StateObject private var friendManager: FriendManager
    @StateObject private var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = []
    @State private var totalExpense: Double = 0.0

    init(group: Group) {
        self.group = group
        if let groupId = group.id {
            _friendManager = StateObject(wrappedValue: FriendManager(groupId: groupId))
            _balanceManager = StateObject(wrappedValue: BalanceManager(groupId: groupId))
        } else {
            fatalError("Group ID is required")
        }
    }

    var body: some View {
        TabView {
            HomeView(groupId: group.id ?? "default")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            LogView(balanceManager: balanceManager, transactions: $transactions)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
            
            BalanceView(balanceManager: balanceManager)
                .tabItem {
                    Label("Balances", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            
        }
        .onAppear {
            loadTransactions()
        }
    }
    
    private func loadTransactions() {
        guard let groupId = group.id else {
            print("Error: Group ID is missing")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("groups").document(groupId).collection("transactions").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error)")
                return
            }
            self.transactions = snapshot?.documents.compactMap { document in
                try? document.data(as: UserExpense.self)
            } ?? []
        }
    }
}
