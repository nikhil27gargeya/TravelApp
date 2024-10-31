import SwiftUI

struct ContentView: View {
    @StateObject private var balanceManager = BalanceManager()
    @State private var transactions: [UserExpense] = loadTransactions()
    @State private var totalExpense: Double = 0.0
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LogView(balanceManager: balanceManager)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
            BalanceView(balanceManager: balanceManager)
                .tabItem {
                    Label("Calcs", systemImage: "square.and.pencil")
                }
            CalculateReceiptView(balanceManager: balanceManager, transactions: $transactions, totalExpense: $totalExpense, parsedItems: [("Coffee", 4.50), ("Sandwich", 7.25), ("Salad", 6.00)], tax: 1.0, total: 20.0)
                .tabItem {
                    Label("Settings", systemImage: "list.bullet")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
