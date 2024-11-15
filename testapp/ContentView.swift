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
        VStack {
            TabView {
                    HomeView(groupId: group.id ?? "default")
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                    
                LogView(balanceManager: balanceManager, friendManager: friendManager, transactions: $transactions)
                    .tabItem {
                        Label("Log", systemImage: "list.bullet")
                    }
                    .navigationBarBackButtonHidden(true)
                BalanceView(balanceManager: balanceManager)
                    .tabItem {
                        Label("Balances", systemImage: "creditcard")
                        //arrow.left.arrow.right
                    }
                    .navigationBarBackButtonHidden(true)
                GroqView(scannedText: $scannedText,
                         balanceManager: balanceManager,  // Pass balanceManager
                         totalExpense: $totalExpense,    // Pass totalExpense
                         transactions: $transactions,    // Pass transactions
                         friends: $friendManager.friends, // Pass friends from FriendManager
                         friendManager: friendManager)   // Pass friendManager
                .tabItem {
                    Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                }
                .navigationBarBackButtonHidden(true)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .navigationBarBackButtonHidden(true)
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
