import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    var group: Group
    @StateObject private var friendManager: FriendManager
    @StateObject private var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = []
    @State private var totalExpense: Double = 0.0
    @State private var scannedText: String = ""
    @State private var itemCosts: [(String, Double)] = []
    @State private var totalAmount: Double?
    @State private var taxAmount: Double?
    @State private var isShowingReceiptScanner = false
    
    init(group: Group) {
        self.group = group
        _friendManager = StateObject(wrappedValue: FriendManager(groupId: group.id ?? ""))
        _balanceManager = StateObject(wrappedValue: BalanceManager(groupId: group.id ?? ""))
    }

    var body: some View {
        NavigationStack {
            TabView {
                // Home Tab (No "Add Transaction" button here anymore)
                HomeView(groupId: group.id ?? "default", tripName: group.name ?? "default")
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                // Log Tab (Just lists transactions, no Add Transaction button here anymore)
                LogView(balanceManager: balanceManager, friendManager: friendManager, transactions: $transactions)
                    .tabItem {
                        Label("Log", systemImage: "list.bullet")
                    }

                // Add Transaction Tab (New tab with button to add transactions)
                AddTransactionView(
                    groupId: group.id ?? "default",
                    totalExpense: $totalExpense,
                    transactions: $transactions,
                    friends: $friendManager.friends,
                    balanceManager: balanceManager
                )
                .tabItem {
                    Label("Add Transaction", systemImage: "plus")
                }
                
                // Balance View
                BalanceView(balanceManager: balanceManager)
                    .tabItem {
                        Label("Balances", systemImage: "creditcard")
                    }
                
                // Settings View
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .onAppear {
                loadTransactions()
            }
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
