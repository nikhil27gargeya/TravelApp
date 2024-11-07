import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    var group: Group
    @StateObject private var friendManager: FriendManager
    @StateObject private var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = []
    @State private var totalExpense: Double = 0.0
    @State private var scannedReceiptText: String = ""
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
                
                BalanceView(balanceManager: balanceManager)
                    .tabItem {
                        Label("Balances", systemImage: "chart.bar")
                    }
                CalculateReceiptView(
                    balanceManager: balanceManager,
                    transactions: $transactions,
                    totalExpense: $totalExpense,
                    friends: $friendManager.friends,
                    parsedItems: itemCosts,
                    tax: taxAmount ?? 0.0,
                    total: totalAmount ?? 0.0
                )
                .tabItem {
                    Label("Balances", systemImage: "gear")
                }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .onAppear {
                loadTransactions()
            }
            
            Button(action: {
                isShowingReceiptScanner = true
            }) {
                Text("Scan Receipt")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .sheet(isPresented: $isShowingReceiptScanner) {
                ReceiptScannerView(
                    scannedText: $scannedReceiptText,
                    itemCosts: $itemCosts,
                    totalAmount: $totalAmount,
                    taxAmount: $taxAmount
                )
            }
            .onChange(of: scannedReceiptText) { newValue in
                let parsedData = parseReceiptDetails(from: newValue)
                itemCosts = parsedData.items
                totalAmount = parsedData.total
                taxAmount = parsedData.tax
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
