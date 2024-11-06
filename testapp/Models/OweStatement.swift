// OweStatement.swift
import Foundation
import SwiftUI

struct OweStatement: Hashable, Identifiable, Codable {
    let id = UUID()
    let debtor: String
    let creditor: String
    var amount: Double

    var description: String {
        "\(debtor) owes \(creditor) \(String(format: "%.2f", amount))"
    }
}
