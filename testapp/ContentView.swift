import SwiftUI

struct ContentView: View {
    @StateObject private var balanceManager = BalanceManager()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LogView()
                .environmentObject(balanceManager)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
            BalanceView()
                .environmentObject(balanceManager)
                .tabItem {
                    Label("Calcs", systemImage: "square.and.pencil")
                }
            CalculateReceiptView(parsedItems: [("Coffee", 4.50), ("Sandwich", 7.25), ("Salad", 6.00)], tax: 1.0, total: 20.0)
                .environmentObject(balanceManager)
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
