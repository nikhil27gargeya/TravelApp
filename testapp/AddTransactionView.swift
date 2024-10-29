import SwiftUI

struct AddTransactionView: View {
    @Binding var totalExpense: Double
    @Binding var transactions: [UserExpense]
    @Binding var friends: [Friend]
    @Binding var selectedCurrency: String // New binding for selected currency
    @Environment(\.presentationMode) var presentationMode
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var splitType: SplitType = .evenly
    @State private var selectedFriend: Friend?

    enum SplitType: String, CaseIterable {
        case evenly = "Split Evenly"
        case custom = "Custom Split"
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                    }
                    .padding()
                    Spacer()
                }

                Form {
                    // Amount Field
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .overlay(
                            Text(getFormattedAmount())
                                .foregroundColor(.gray)
                                .padding(.trailing, 8),
                            alignment: .trailing
                        )

                    // Friend Selection Picker
                    Section(header: Text("Who Paid?")) {
                        Picker("Select Friend", selection: $selectedFriend) {
                            ForEach(friends, id: \.id) { friend in
                                Text(friend.name).tag(friend as Friend?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

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
                                    TextField("Amount", value: $friend.share, format: .currency(code: selectedCurrency)) // Use the selected currency
                                        .keyboardType(.decimalPad)
                                        .frame(width: 100)
                                }
                            }
                        }
                    }

                    // Save Button
                    Button("Save") {
                        saveTransaction()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .navigationTitle("Add Transaction")
                .onChange(of: amount) { newValue in
                    if splitType == .evenly {
                        distributeAmountEvenly()
                    }
                }
            }
        }
    }

    private func getFormattedAmount() -> String {
        guard let amountValue = Double(amount) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency // Set the currency code based on the user's selection
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

        let newExpense = UserExpense(amount: totalAmount, date: Date(), description: description.isEmpty ? nil : description, splitDetails: splitDetails)
        transactions.append(newExpense)
        saveTransactions(transactions)
        totalExpense += newExpense.amount
    }
}
