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
                }
            }
            request.recognitionLevel = .accurate
            try? requestHandler.perform([request])
        }
    }
}
