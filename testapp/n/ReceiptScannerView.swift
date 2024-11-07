import SwiftUI
import VisionKit
import Vision
import UIKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var itemCosts: [(String, Double)] // New binding to hold item names and their costs
    @Binding var totalAmount: Double? // New binding for total amount
    @Binding var taxAmount: Double? // New binding for tax amount

    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedText: $scannedText, itemCosts: $itemCosts, totalAmount: $totalAmount, taxAmount: $taxAmount)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scannedText: String
        @Binding var itemCosts: [(String, Double)]
        @Binding var totalAmount: Double?
        @Binding var taxAmount: Double?
        
        init(scannedText: Binding<String>, itemCosts: Binding<[(String, Double)]>, totalAmount: Binding<Double?>, taxAmount: Binding<Double?>) {
            _scannedText = scannedText
            _itemCosts = itemCosts
            _totalAmount = totalAmount
            _taxAmount = taxAmount
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true, completion: nil)
            
            guard scan.pageCount > 0 else { return }
            let image = scan.imageOfPage(at: 0)
            recognizeText(from: image)
        }
        
        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                self.scannedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                print("Scanned Text After Recognition: \(self.scannedText)")
                
                // Parse the scanned text for items, tax, and total
                let parsedData = self.parseReceiptDetails(from: self.scannedText)
                
                // Update the bindings with the parsed data
                DispatchQueue.main.async {
                    self.itemCosts = parsedData.items
                    self.totalAmount = parsedData.total
                    self.taxAmount = parsedData.tax
                }
            }
            request.recognitionLevel = .accurate
            
            DispatchQueue.global(qos: .userInitiated).async {
                try? requestHandler.perform([request])
            }
        }
        
        private func parseReceiptDetails(from scannedText: String) -> (items: [(String, Double)], tax: Double, total: Double) {
            var parsedItemCosts: [(String, Double)] = []
            var tax: Double = 0.0
            var total: Double = 0.0
            let lines = scannedText.split(separator: "\n").map { String($0) }

            var itemNames: [String] = []
            var itemPrices: [Double] = []

            print("Scanned Text Lines:")
            for line in lines {
                print(line)  // Print each line to understand how it's formatted
            }

            // Loop through the lines and separate items and prices
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Regex to detect if a line contains a price (formatted as "$XX.XX" or "XX.XX")
                let pricePattern = #"(\$?(\d+(\.\d{1,2})?))$"#
                if let priceMatch = line.matchingStrings(for: pricePattern).first,
                   priceMatch.count > 1 {
                    let priceString = priceMatch[1]  // We need to grab group 1 which includes the dollar sign
                    if let price = Double(priceString.replacingOccurrences(of: "$", with: "")) {
                        print("Found Price: \(price)")
                        itemPrices.append(price)
                    }
                } else if !trimmedLine.lowercased().contains("subtotal") &&
                          !trimmedLine.lowercased().contains("tax") &&
                          !trimmedLine.lowercased().contains("total") &&
                          !trimmedLine.isEmpty {
                    // Add line to item names if it doesn't contain keywords and isn't empty
                    print("Found Item Name: \(trimmedLine)")
                    itemNames.append(trimmedLine)
                }

                // Look for tax and total specifically
                if trimmedLine.lowercased().contains("tax") {
                    let taxPattern = #"\$(\d+(\.\d{1,2})?)$"#
                    if let taxMatch = line.matchingStrings(for: taxPattern).first,
                       taxMatch.count > 1 {
                        let taxValueString = taxMatch[1]
                        if let taxValue = Double(taxValueString) {
                            tax = taxValue
                            print("Found Tax: \(tax)")
                        }
                    }
                } else if trimmedLine.lowercased().contains("total") {
                    let totalPattern = #"\$(\d+(\.\d{1,2})?)$"#
                    if let totalMatch = line.matchingStrings(for: totalPattern).first,
                       totalMatch.count > 1 {
                        let totalValueString = totalMatch[1]
                        if let totalValue = Double(totalValueString) {
                            total = totalValue
                            print("Found Total: \(total)")
                        }
                    }
                }
            }

            // Match item names with item prices based on their sequence
            let itemCount = min(itemNames.count, itemPrices.count)
            for i in 0..<itemCount {
                parsedItemCosts.append((itemNames[i], itemPrices[i]))
            }

            print("Parsed Items: \(parsedItemCosts)")
            print("Parsed Tax: \(tax)")
            print("Parsed Total: \(total)")

            return (items: parsedItemCosts, tax: tax, total: total)
        }
    }
}

extension String {
    func matchingStrings(for pattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return matches.map { match in
                (0..<match.numberOfRanges).compactMap {
                    guard let range = Range(match.range(at: $0), in: self) else {
                        return nil
                    }
                    return String(self[range])
                }
            }
        } catch {
            return []
        }
    }
}
