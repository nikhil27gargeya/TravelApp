import SwiftUI
import FirebaseFirestore

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
    @State private var scannedText: String = ""
    @State private var parsedItems: [(String, Double)] = []
    @State private var tax: Double? = 0.0
    @State private var total: Double? = 0.0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    enum SplitType: String, CaseIterable {
        case evenly = "Split Evenly"
        case custom = "Custom Split"
    }

    var body: some View {
            NavigationView {
                VStack {
                    Form {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                Text(getFormattedAmount())
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8),
                                alignment: .trailing
                            )
                        
                        // Friend Selection Picker with padding and rounded corners
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Description Field with a bit more padding
                        TextField("Description (optional)", text: $description)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)

                        // Split Type Picker with styled segmented control
                        Picker("Split Type", selection: $splitType) {
                            ForEach(SplitType.allCases, id: \.self) { type in
                                Text(type.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // Custom Split Section with padding and styled text fields
                        if splitType == .custom {
                            Section(header: Text("Custom Split").font(.headline).padding(.vertical)) {
                                ForEach($friends) { $friend in
                                    HStack {
                                        Text(friend.name)
                                            .font(.body)
                                            .padding(.leading)
                                        Spacer()
                                        TextField("Amount", value: $friend.share, format: .currency(code: selectedCurrency))
                                            .keyboardType(.decimalPad)
                                            .frame(width: 100)
                                            .padding()
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        
                        // Show Error Message if Split is Invalid
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top)
                                .font(.subheadline)
                        }
                        
                        // Save Button with a background color, padding, and rounded corners
                        Button("Save") {
                            saveTransaction()
                        }
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                        .overlay(
                            isLoading ? AnyView(ProgressView()) : AnyView(EmptyView())
                        )
                    }
                    .background(Color.white) // Set a background for the entire form
                    .cornerRadius(12)
                    .padding()
                }
                .navigationTitle("Add Transaction")
            }
        }

    private func getFormattedAmount() -> String {
        guard let amountValue = Double(amount) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency
        return formatter.string(from: NSNumber(value: amountValue)) ?? ""
    }

    private func validateSplit() -> Bool {
        guard let totalAmount = Double(amount) else { return false }

        // Only validate for custom split
        if splitType == .custom {
            // Check if any share amount is negative
            for friend in friends {
                if friend.share < 0 {
                    errorMessage = "Share amount cannot be negative."
                    return false
                }
            }

            // Calculate the total of the custom split amounts
            let totalSplitAmount = friends.reduce(0.0) { result, friend in
                result + friend.share
            }

            if totalSplitAmount != totalAmount {
                errorMessage = "The total split does not match the amount paid."
                return false
            }
        }
        
        errorMessage = nil
        return true
    }



    private func saveTransaction() {
        guard let totalAmount = Double(amount), let paidBy = selectedFriend else { return }

        // Validate the split amounts
        if !validateSplit() {
            return
        }

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
                }
        } catch {
            print("Error encoding transaction: \(error)")
            isLoading = false
        }
    }
}
