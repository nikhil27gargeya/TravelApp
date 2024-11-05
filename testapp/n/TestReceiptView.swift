//
//  TestReceiptView.swift
//  testapp
//
//  Created by Nikhil Gargeya on 10/31/24.
//

import Foundation
import SwiftUI

struct TestReceiptView: View {
    @State private var items: [(String, Double)] = []
    @State private var tax: Double = 0.0
    @State private var total: Double = 0.0
    
    var body: some View {
        VStack {
            Text("Receipt Parsing Test")
                .font(.headline)
            
            Button("Parse Receipt") {
                let receiptText = """
                44
                Bierhaus
                Bierhaus
                NYC 712 Third Avenue New York, NY 10017
                Server: Tiffany R
                Check #44
                Guest Count: 3
                Ordered:
                1 Lt Delicator
                1L Hofbrau Dunkel
                .5L Hofbrau Original
                Bierhaus Burger
                Well Done Bratwurst
                Spicy Mustard Chicken
                Bratwurst Spicy
                Mustard
                Subtotal
                Tax
                Total
                Table 304
                12/31/23 7:27 PM
                $25.00
                $19.00
                $10.00
                $19.00
                $17.00
                $17.00
                $107.00
                $9.48
                $116.48
                """
                
                let result = parseReceiptData(from: receiptText)
                items = result.items
                tax = result.tax
                total = result.total
                
                print("Parsed Items: \(items)")
                print("Tax: \(tax)")
                print("Total: \(total)")
            }
            
            List(items, id: \.0) { item in
                Text("\(item.0): $\(item.1, specifier: "%.2f")")
            }
            
            Text("Tax: $\(tax, specifier: "%.2f")")
            Text("Total: $\(total, specifier: "%.2f")")
        }
        .padding()
    }
}

struct TestReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        TestReceiptView()
    }
}

