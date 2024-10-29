import SwiftUI

struct SettingsView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    private let currencies = ["USD", "EUR", "GBP", "INR", "JPY", "AUD", "CAD"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Currency")) {
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedCurrency) { newValue in
                        saveCurrency(newValue)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    func saveCurrency(_ currency: String) {
        UserDefaults.standard.set(currency, forKey: "currency")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
