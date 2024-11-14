import Vision
import UIKit
import VisionKit
import SwiftUI

final class TextRecognizer {
    let cameraScan: VNDocumentCameraScan?
    let uploadedImage: UIImage?

    init(cameraScan: VNDocumentCameraScan?, image: UIImage?) {
        self.cameraScan = cameraScan
        self.uploadedImage = image
    }

    private let queue = DispatchQueue(label: "scan-codes", qos: .default)

    func recognizeText(withCompletionHandler completionHandler: @escaping ([String]) -> Void) {
        queue.async {
            let minimumTextHeight: Float = 1

            if let cameraScan = self.cameraScan {
                let images = (0..<cameraScan.pageCount).compactMap { cameraScan.imageOfPage(at: $0).cgImage }
                self.processImages(images: images, minimumTextHeight: minimumTextHeight, completionHandler: completionHandler)
            } else if let image = self.uploadedImage, let cgImage = image.cgImage {
                self.processImages(images: [cgImage], minimumTextHeight: minimumTextHeight, completionHandler: completionHandler)
            } else {
                DispatchQueue.main.async {
                    completionHandler([])
                }
            }
        }
    }

    private func processImages(images: [CGImage], minimumTextHeight: Float, completionHandler: @escaping ([String]) -> Void) {
        var textResults: [String] = []
        let dispatchGroup = DispatchGroup()

        for image in images {
            dispatchGroup.enter()
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    print("Error recognizing text: \(error)")
                    dispatchGroup.leave()
                    return
                }
                let recognizedText = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                
                textResults.append(recognizedText)
                dispatchGroup.leave()
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = minimumTextHeight

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Error performing text recognition: \(error)")
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("Recognized text results: \(textResults)") // Debugging output to see the recognized text
            completionHandler(textResults)
        }
    }
}
