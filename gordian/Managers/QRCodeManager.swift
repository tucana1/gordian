import Foundation
import AVFoundation
import CoreImage
import UIKit

class QRCodeManager: ObservableObject {
    static let shared = QRCodeManager()

    private init() {}

    /// Generate a QR code image from a string
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let scaleX = 200.0 / outputImage.extent.size.width
        let scaleY = 200.0 / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Generate a unique QR code identifier
    func generateIdentifier() -> String {
        "gordian-\(UUID().uuidString)"
    }
}
