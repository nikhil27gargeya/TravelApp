import SwiftUI

struct TransactionDetailView: View {
    let statement: OweStatement
    let transactions: [UserExpense]
    
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
                        Text("Amount: \(String(format: "%.2f", transaction.splitDetails[statement.debtor] ?? 0.0))")
                        Text("Paid by: \(transaction.payer)")
                        Text("Date: \(transaction.date, formatter: DateFormatter.shortDate)")
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Details")
    }

    private func filteredTransactions() -> [UserExpense] {
        return transactions.filter { transaction in
            transaction.participants.contains(statement.debtor) &&
            transaction.participants.contains(statement.creditor) &&
            (transaction.splitDetails[statement.debtor] != nil || transaction.splitDetails[statement.creditor] != nil)
        }
    }
}
