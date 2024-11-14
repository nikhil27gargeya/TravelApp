import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AddTransactionView: View {
    let groupId: String
    @Binding var totalExpense: Double
    @Binding var transactions: [UserExpense]
    @Binding var friends: [Friend]
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var balanceManager: BalanceManager
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var splitType: SplitType = .evenly
    @State private var selectedFriend: Friend?
    @State private var showReceiptScanner = false
    @State private var navigationPath = [String]() // New state for managing navigation path
    @State private var scannedText: String = ""
    @State private var parsedItems: [(String, Double)] = []
    @State private var tax: Double? = 0.0
    @State private var total: Double? = 0.0
    @State private var isLoading: Bool = false

    enum SplitType: String, CaseIterable {
        case evenly = "Split Evenly"
        case custom = "Custom Split"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Form {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .overlay(
                            Text(getFormattedAmount())
                                .foregroundColor(.gray)
                                .padding(.trailing, 8),
                            alignment: .trailing
                        )

                    // Friend Selection Picker
                    Picker("Who Paid", selection: $selectedFriend) {
                        ForEach(friends) { friend in
                            Text(friend.name).tag(friend as Friend?)
                        }
                    }
                    .onAppear {
                        if selectedFriend == nil {
                            selectedFriend = friends.first
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Description Field
                    TextField("Description (optional)", text: $description)

                    // Split Type Picker
                    Picker("Split Type", selection: $splitType) {
                        ForEach(SplitType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Custom Split Section
                    if splitType == .custom {
                        Section(header: Text("Custom Split")) {
                            ForEach($friends) { $friend in
                                HStack {
                                    Text(friend.name)
                                    Spacer()
                                    TextField("Amount", value: $friend.share, format: .currency(code: selectedCurrency))
                                        .keyboardType(.decimalPad)
                                        .frame(width: 100)
                                }
                            }
                        }
                    }

                    // Save Button
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(isLoading)
                    .overlay(
                        isLoading ? AnyView(ProgressView()) : AnyView(EmptyView())
                    )
                }
                .navigationTitle("Add Transaction")
                .onChange(of: amount) { _ in
                    if splitType == .evenly {
                        distributeAmountEvenly()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                        }
                    }
                }
                
                // Scan Receipt Button
                Button("Scan Receipt") {
                    showReceiptScanner.toggle()
                }
                .foregroundColor(.green)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

                
            }
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScannerView(
                    scannedText: $scannedText,
                    itemCosts: $parsedItems,
                    totalAmount: $total,
                    taxAmount: $tax
                )
            }
        }
    }

    private func getFormattedAmount() -> String {
        guard let amountValue = Double(amount) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency
        return formatter.string(from: NSNumber(value: amountValue)) ?? ""
    }

    private func distributeAmountEvenly() {
        guard let total = Double(amount), friends.count > 0 else { return }
        let share = total / Double(friends.count)
        friends = friends.map { Friend(name: $0.name, share: share) }
    }

    private func saveTransaction() {
        guard let totalAmount = Double(amount), let paidBy = selectedFriend else { return }

        var splitDetails: [String: Double] = [:]

        if splitType == .evenly {
            let share = totalAmount / Double(friends.count)
            for friend in friends {
                splitDetails[friend.name] = share
            }
        } else {
            for friend in friends {
                splitDetails[friend.name] = friend.share
            }
        }

        // Create a new expense, including the payer
        let newExpense = UserExpense(
            amount: totalAmount,
            date: Date(),
            description: description.isEmpty ? nil : description,
            splitDetails: splitDetails,
            participants: friends.map { $0.name },
            payer: paidBy.name
        )
        
        isLoading = true // Start loading

        // Save the new expense to Firestore within the specific group
        let db = Firestore.firestore()
        do {
            let documentId = newExpense.id.uuidString // Set document ID to UUID
            try db.collection("groups")
                .document(groupId)
                .collection("transactions")
                .document(documentId)
                .setData(from: newExpense) { error in
                    if let error = error {
                        print("Error saving transaction: \(error)")
                    } else {
                        print("Transaction saved successfully!")
                        transactions.append(newExpense)
                        totalExpense += totalAmount
                        DispatchQueue.main.async {
                            balanceManager.updateBalances(with: splitDetails, payer: paidBy.name)
                        }
                    }
                    isLoading = false // End loading
                    presentationMode.wrappedValue.dismiss()
                }
        } catch {
            print("Error encoding transaction: \(error)")
            isLoading = false
        }
    }
}
