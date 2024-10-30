import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LogView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
            CalculationView()
                .tabItem {
                    Label("Calcs", systemImage: "square.and.pencil")
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
