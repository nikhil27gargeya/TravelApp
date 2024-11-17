import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @State private var totalExpense: Double = 0.0
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    @StateObject private var friendManager: FriendManager
    var tripName: String
    @ObservedObject var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = []
    @State private var isLoading: Bool = true
    
    @Environment(\.presentationMode) var presentationMode // Correctly access presentationMode

    init(groupId: String, tripName: String, balanceManager: BalanceManager) {
        _friendManager = StateObject(wrappedValue: FriendManager(groupId: groupId))
        self.tripName = tripName
        self.balanceManager = balanceManager
    }

    var body: some View {
        NavigationView { // Wrapping in NavigationStack ensures navigation features
            VStack {
                List {
                    Text("Members")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.top)
                        .frame(alignment: .leading)
                    ForEach(friendManager.friends) { friend in
                        Text(friend.name)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(tripName)  // Display the trip name
                .onAppear {
                    friendManager.loadFriends()
                }
                // Balance Section
                Text("Balances")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                let all = balanceManager.owedStatements
                if all.isEmpty {
                    Text("No outstanding debts.")
                        .foregroundColor(.gray)
                } else {
                    List {
                        Section(header: Text("Who Owes Who")) {
                            ForEach(all, id: \.self) { statement in
                                NavigationLink(destination: TransactionDetailView(statement: statement, transactions: transactions)) {
                                    Text(statement.description)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onAppear {
                loadTransactions() // Fetch transactions when the view appears
            }
            .toolbar {
                // Custom Back Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Dismiss the current view using presentationMode
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text("Trips")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    private func loadTransactions() {
        let db = Firestore.firestore()
        db.collection("groups").document(balanceManager.groupId).collection("transactions").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error)")
                isLoading = false
                return
            }
            guard let documents = snapshot?.documents else {
                print("No transactions found")
                isLoading = false
                return
            }
            self.transactions = documents.compactMap { document in
                try? document.data(as: UserExpense.self)
            }
            isLoading = false
        }
    }

    private func clearAllOweStatements() {
        balanceManager.owedStatements.removeAll()
        transactions.removeAll()
        clearStoredOwedStatements()
    }

    private func clearStoredOwedStatements() {
        UserDefaults.standard.removeObject(forKey: "owedStatements")
    }

    private func getOweStatements() -> [OweStatement] {
        return balanceManager.owedStatements
    }
}
