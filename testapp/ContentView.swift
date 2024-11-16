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
    @Environment(\.dismiss) private var dismiss
    
    init(group: Group) {
        self.group = group
        _friendManager = StateObject(wrappedValue: FriendManager(groupId: group.id ?? ""))
        _balanceManager = StateObject(wrappedValue: BalanceManager(groupId: group.id ?? ""))
    }

    var body: some View {
        NavigationStack {
            TabView {
                HomeView(groupId: group.id ?? "default", tripName: group.name ?? "default")
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                            }
                        }
                    }
                    .navigationBarBackButtonHidden(false)  // Hide back button for HomeView only
                
                LogView(balanceManager: balanceManager, friendManager: friendManager, transactions: $transactions)
                    .tabItem {
                        Label("Log", systemImage: "list.bullet")
                    }
                    .navigationBarBackButtonHidden(true)  // Hide back button for LogView
                
                BalanceView(balanceManager: balanceManager)
                    .tabItem {
                        Label("Balances", systemImage: "creditcard")
                    }
                    .navigationBarBackButtonHidden(true)  // Hide back button for BalanceView
                
                GroqView(scannedText: $scannedText,
                         balanceManager: balanceManager,  // Pass balanceManager
                         totalExpense: $totalExpense,    // Pass totalExpense
                         transactions: $transactions,    // Pass transactions
                         friends: $friendManager.friends, // Pass friends from FriendManager
                         friendManager: friendManager)   // Pass friendManager
                    .tabItem {
                        Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                    }
                    .navigationBarBackButtonHidden(true)  // Hide back button for GroqView
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .navigationBarBackButtonHidden(true)  // Hide back button for SettingsView
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
