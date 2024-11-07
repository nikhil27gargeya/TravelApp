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

                let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                // Print recognized text for debugging purposes
                print("Scanned Text After Recognition: \(recognizedText)")

                // Parse the scanned text for items, tax, and total on the main thread
                DispatchQueue.main.async {
                    self.scannedText = recognizedText
                    self.parseReceiptDetails(from: recognizedText)
                }
            }
            request.recognitionLevel = .accurate

            DispatchQueue.global(qos: .userInitiated).async {
                try? requestHandler.perform([request])
            }
        }

        public func parseReceiptDetails(from scannedText: String) {
            let lines = scannedText.split(separator: "\n").map { String($0) }
            var parsedItemCosts: [(String, Double)] = []
            var total: Double?
            var tax: Double?

            for line in lines {
                // Regex to match line items, assuming the format "Item Name    $XX.XX"
                let itemPattern = "(.*)\\s+\\$([\\d.]+)"
                if let itemMatch = line.matchingStrings(for: itemPattern).first {
                    if itemMatch.count > 2 {
                        let itemName = itemMatch[1] // Capture group 1: Item Name
                        let itemPriceString = itemMatch[2] // Capture group 2: Price
                        if let itemPrice = Double(itemPriceString) {
                            parsedItemCosts.append((itemName.trimmingCharacters(in: .whitespacesAndNewlines), itemPrice))
                        }
                    }
                }

                // Regex for tax and total assuming the format "Tax: $XX.XX" and "Total: $XX.XX"
                if line.contains("Tax:") {
                    let taxPattern = "Tax:\\s*\\$([\\d.]+)"
                    if let taxMatch = line.matchingStrings(for: taxPattern).first,
                       taxMatch.count > 1,
                       let taxValue = Double(taxMatch[1]) {
                        tax = taxValue
                    }
                }

                if line.contains("Total:") {
                    let totalPattern = "Total:\\s*\\$([\\d.]+)"
                    if let totalMatch = line.matchingStrings(for: totalPattern).first,
                       totalMatch.count > 1,
                       let totalValue = Double(totalMatch[1]) {
                        total = totalValue
                    }
                }
            }

            // Update bindings on the main thread to ensure UI updates correctly
            DispatchQueue.main.async {
                self.itemCosts = parsedItemCosts
                self.totalAmount = total
                self.taxAmount = tax

                // Debugging output
                print("Parsed Items: \(self.itemCosts)")
                print("Parsed Total: \(self.totalAmount ?? 0.0)")
                print("Parsed Tax: \(self.taxAmount ?? 0.0)")
            }
        }
    }
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
