import SwiftUI
import Vision
import VisionKit
import UIKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var parsedItems: [(String, Double)]
    @Binding var tax: Double
    @Binding var total: Double

    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedText: $scannedText, parsedItems: $parsedItems, tax: $tax, total: $total)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scannedText: String
        @Binding var parsedItems: [(String, Double)]
        @Binding var tax: Double
        @Binding var total: Double

        init(scannedText: Binding<String>, parsedItems: Binding<[(String, Double)]>, tax: Binding<Double>, total: Binding<Double>) {
            _scannedText = scannedText
            _parsedItems = parsedItems
            _tax = tax
            _total = total
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
            let request = VNRecognizeTextRequest { [weak self] (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("No text found")
                    return
                }
                let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                DispatchQueue.main.async {
                    print("Recognized Text: \(recognizedText)") // Debug print
                    self?.scannedText = recognizedText
                    
                    // Parse the recognized text
//                    if let parsedData = self?.parseReceiptData(from: recognizedText) {
//                        print("Parsed Items: \(parsedData.items)")  // Debug print for parsed items
//                        print("Parsed Tax: \(parsedData.tax)")      // Debug print for tax
//                        print("Parsed Total: \(parsedData.total)")  // Debug print for total
//
//                        // Update bindings
//                        self?.parsedItems = parsedData.items
//                        self?.tax = parsedData.tax
//                        self?.total = parsedData.total
//                    } else {
//                        print("Parsing failed")
//                    }
                }
            }
            request.recognitionLevel = .accurate
            try? requestHandler.perform([request])
        }

        private func parseReceiptData(from text: String) -> (items: [(String, Double)], tax: Double, total: Double) {
            var itemCosts: [(String, Double)] = []
            var tax: Double = 0.0
            var total: Double = 0.0
            
            // Split the text into lines
            let lines = text.components(separatedBy: .newlines)
            
            for line in lines {
                // Match item lines with a format of "Item Name $XX.XX"
                if let itemMatch = line.range(of: #"(.+?)\s+\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
                    let itemName = String(line[itemMatch.lowerBound..<itemMatch.upperBound]).components(separatedBy: "$")[0]
                    if let priceString = line[itemMatch.lowerBound..<itemMatch.upperBound].components(separatedBy: "$").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                       let price = Double(priceString) {
                        itemCosts.append((itemName.trimmingCharacters(in: .whitespacesAndNewlines), price))
                    }
                }
                // Check for tax line
                else if line.lowercased().contains("tax") {
                    if let taxMatch = line.range(of: #"\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
                        let taxString = String(line[taxMatch.lowerBound..<taxMatch.upperBound]).replacingOccurrences(of: "$", with: "")
                        tax = Double(taxString) ?? 0.0
                    }
                }
                // Check for total line
                else if line.lowercased().contains("total") {
                    if let totalMatch = line.range(of: #"\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
                        let totalString = String(line[totalMatch.lowerBound..<totalMatch.upperBound]).replacingOccurrences(of: "$", with: "")
                        total = Double(totalString) ?? 0.0
                    }
                }
            }
            // Return parsed items, tax, and total
            return (items: itemCosts, tax: tax, total: total)
        }


    }
}
