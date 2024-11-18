import SwiftUI

public struct UserExpense: Identifiable, Codable {
    public var id = UUID()
    var amount: Double
    var date: Date
    var description: String
    var splitDetails: [String: Double]
    var participants: [String]
    var payer: String
}
