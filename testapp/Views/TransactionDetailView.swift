import SwiftUI

// This is the view that comes from a balance view card to show the breakdown of how the owe statement was calculated
struct TransactionDetailView: View {
    let statement: OweStatement
    let transactions: [UserExpense]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack {
            Text("Transactions for \(statement.debtor) and \(statement.creditor)")
                .font(.headline)
                .padding()

            List {
                ForEach(filteredTransactions(), id: \.id) { transaction in
                    VStack(alignment: .leading) {
                        Text(transaction.description ?? "No Description")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        Text("Amount: \(String(format: "%.2f", transaction.splitDetails[statement.debtor] ?? 0.0))")
                            .padding(.bottom, 1)
                        
                        Text("Paid by: \(transaction.payer)")
                            .padding(.bottom, 1)
                        
                        Text("Date: \(transaction.date, formatter: dateFormatter)")
                            .padding(.bottom, 2)
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Transaction Details")
    }

    private func filteredTransactions() -> [UserExpense] {
        return transactions.filter { transaction in
            // Make sure both the debtor and creditor are part of the transaction
            transaction.participants.contains(statement.debtor) &&
            transaction.participants.contains(statement.creditor) &&
            (transaction.splitDetails[statement.debtor] != nil || transaction.splitDetails[statement.creditor] != nil)
        }
    }
}
