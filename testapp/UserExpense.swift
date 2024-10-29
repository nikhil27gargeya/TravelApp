//
//  UserExpense.swift
//  testapp
//
//  Created by Nikhil Gargeya on 10/29/24.
//

import Foundation

public struct UserExpense: Identifiable, Codable {
    public var id = UUID()
    var amount: Double
    var date: Date
    var description: String?
    var splitDetails: [String: Double]
    var participants: [String]
    var payer: String?
}
