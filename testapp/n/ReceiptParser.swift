import Foundation
import SwiftUI

public func parseReceiptDetails(from scannedText: String) -> (items: [(String, Double)], tax: Double, total: Double) {
    var parsedItemCosts: [(String, Double)] = []
    var tax: Double = 0.0
    var total: Double = 0.0
    let lines = scannedText.split(separator: "\n").map { String($0) }

    for line in lines {
        let itemPattern = "(.*)\\s+\\$([\\d.]+)"
        if let itemMatch = line.matchingStrings(for: itemPattern).first, itemMatch.count > 2 {
            let itemName = itemMatch[1]
            let itemPriceString = itemMatch[2]
            if let itemPrice = Double(itemPriceString) {
                parsedItemCosts.append((itemName.trimmingCharacters(in: .whitespacesAndNewlines), itemPrice))
            }
        }

        if line.contains("Tax:") {
            let taxPattern = "Tax:\\s*\\$([\\d.]+)"
            if let taxMatch = line.matchingStrings(for: taxPattern).first, taxMatch.count > 1 {
                if let taxValue = Double(taxMatch[1]) {
                    tax = taxValue
                }
            }
        }

        if line.contains("Total:") {
            let totalPattern = "Total:\\s*\\$([\\d.]+)"
            if let totalMatch = line.matchingStrings(for: totalPattern).first, totalMatch.count > 1 {
                if let totalValue = Double(totalMatch[1]) {
                    total = totalValue
                }
            }
        }
    }

    return (items: parsedItemCosts, tax: tax, total: total)
}

extension String {
    func matchingStrings(for pattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return matches.map { match in
                (0..<match.numberOfRanges).map {
                    String(self[Range(match.range(at: $0), in: self)!])
                }
            }
        } catch {
            return []
        }
    }
}
