import Foundation
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

public enum ImageUtilities {
    public static func getCGImage(from image: NSImage) -> CGImage? {
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return cg
        }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return rep.cgImage
    }
    
    public static func resize(
        image: NSImage,
        targetWidth: Int,
        targetHeight: Int?,
        preserveAspectRatio: Bool,
        allowUpscale: Bool = false
    ) throws -> NSImage {
        guard let cgImage = getCGImage(from: image) else {
            throw ActionError.imageDecodeFailed
        }
        
        let originalWidth = cgImage.width
        let originalHeight = cgImage.height
        
        var newWidth = targetWidth
        var newHeight: Int
        
        if preserveAspectRatio {
            let aspectRatio = Double(originalWidth) / Double(originalHeight)
            if let targetHeight = targetHeight, targetHeight > 0 {
                newHeight = targetHeight
                newWidth = Int(round(Double(newHeight) * aspectRatio))
            } else {
                newHeight = max(1, Int(round(Double(newWidth) / aspectRatio)))
            }
        } else {
            newHeight = targetHeight ?? originalHeight
        }
        
        if !allowUpscale {
            if newWidth > originalWidth && (targetHeight == nil || newHeight > originalHeight) {
                newWidth = originalWidth
                newHeight = originalHeight
            }
        }
        
        guard newWidth > 0, newHeight > 0 else {
            throw ActionError.actionFailed("Invalid image dimensions.")
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ActionError.imageEncodeFailed("Could not create drawing context.")
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        guard let resizedCG = context.makeImage() else {
            throw ActionError.imageEncodeFailed("Failed to render resized image.")
        }
        
        return NSImage(cgImage: resizedCG, size: NSSize(width: newWidth, height: newHeight))
    }
    
    public static func convertToPNG(image: NSImage) throws -> (NSImage, Data) {
        guard let cgImage = getCGImage(from: image) else {
            throw ActionError.imageDecodeFailed
        }
        
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw ActionError.imageEncodeFailed("Could not encode PNG data.")
        }
        
        guard let outputImage = NSImage(data: pngData) else {
            throw ActionError.imageEncodeFailed("Could not instantiate converted PNG.")
        }
        return (outputImage, pngData)
    }
    
    public static func convertToJPEG(image: NSImage, quality: Double = 0.85) throws -> (NSImage, Data) {
        guard let cgImage = getCGImage(from: image) else {
            throw ActionError.imageDecodeFailed
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Composite onto neutral white background in case of transparency
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ActionError.imageEncodeFailed("Could not create context for JPEG composite.")
        }
        
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let flattenedCG = context.makeImage() else {
            throw ActionError.imageEncodeFailed("Failed to composite image on white background.")
        }
        
        let rep = NSBitmapImageRep(cgImage: flattenedCG)
        let clampedQuality = min(max(quality, 0.05), 1.0)
        guard let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: clampedQuality]) else {
            throw ActionError.imageEncodeFailed("Could not encode JPEG data.")
        }
        
        guard let outputImage = NSImage(data: jpegData) else {
            throw ActionError.imageEncodeFailed("Could not instantiate converted JPEG.")
        }
        return (outputImage, jpegData)
    }
    
    public static func generateQRCode(from string: String, targetSize: CGFloat = 512) throws -> (NSImage, Data) {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw ActionError.actionFailed("CoreImage QR generator unavailable.")
        }
        
        guard let data = string.data(using: .utf8) else {
            throw ActionError.actionFailed("Could not encode string as UTF-8.")
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputCIImage = filter.outputImage else {
            throw ActionError.actionFailed("Failed to generate QR code.")
        }
        
        let extent = outputCIImage.extent
        let scale = targetSize / extent.width
        let scaledImage = outputCIImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: NSSize(width: targetSize, height: targetSize))
        nsImage.addRepresentation(rep)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw ActionError.actionFailed("Could not render QR code.")
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ActionError.actionFailed("Could not encode QR code PNG.")
        }
        
        return (nsImage, pngData)
    }
    
    public static func performOCR(on image: NSImage) async throws -> String {
        guard let cgImage = getCGImage(from: image) else {
            throw ActionError.imageDecodeFailed
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw ActionError.actionFailed("Vision request failed: \(error.localizedDescription)")
        }
        
        guard let observations = request.results else {
            return ""
        }
        
        let sorted = observations.sorted { a, b in
            let yDiff = abs(a.boundingBox.origin.y - b.boundingBox.origin.y)
            if yDiff > 0.02 {
                return a.boundingBox.origin.y > b.boundingBox.origin.y
            }
            return a.boundingBox.origin.x < b.boundingBox.origin.x
        }
        
        let lines = sorted.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        return lines.joined(separator: "\n")
    }
}
