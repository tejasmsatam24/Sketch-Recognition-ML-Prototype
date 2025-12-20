import SwiftUI
import Photos
import CoreML
import UIKit

struct ContentView: View {
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var predictionResult = "Draw something to get a prediction"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("iPad Drawing App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Prediction Result Display
            Text(predictionResult)
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Canvas View
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 256, height: 256)
                    .border(Color.gray, width: 2)
                    .cornerRadius(8)
                
                Canvas { context, size in
                    // Draw all completed paths
                    for path in paths {
                        context.stroke(path, with: .color(.black), lineWidth: 3)
                    }
                    
                    // Draw current path being drawn
                    context.stroke(currentPath, with: .color(.black), lineWidth: 3)
                }
                .frame(width: 256, height: 256)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            if currentPath.isEmpty {
                                currentPath.move(to: point)
                            } else {
                                currentPath.addLine(to: point)
                            }
                        }
                        .onEnded { _ in
                            paths.append(currentPath)
                            currentPath = Path()
                        }
                )
            }
            
            // Buttons
            HStack(spacing: 30) {
                Button("Recognize") {
                    recognizeDrawing()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 140, height: 50)
                .background(Color.blue)
                .cornerRadius(10)
                
                Button("Clear") {
                    clearCanvas()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 140, height: 50)
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding(.bottom)
            
            Text("Draw on the canvas above • Canvas size: 256×256 pixels")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Test the model with tree.jpeg when the app loads
            testModelWithTree()
        }
    }
    
    private func clearCanvas() {
        paths.removeAll()
        currentPath = Path()
        predictionResult = "Draw something to get a prediction"
    }
    
    private func recognizeDrawing() {
        // Convert drawing to UIImage
        let image = generateImage()
        
        // Use ML model to classify the drawing
        classifyImage(image)
        
        // Save to Photos library
        saveImageToPhotos(image)
    }
    
    private func testModelWithTree() {
        // Load tree.jpeg from the app bundle (assumes it's already 256x256)
        guard let image = UIImage(named: "tree.jpeg") else {
            predictionResult = "Error: tree.jpeg not found in bundle"
            return
        }
        
        print("🌳 Testing Tree Image with DrawingClassifier Model 🌳")
        print(String(repeating: "=", count: 50))
        print("Using TensorFlow-compatible preprocessing...")
        
        // Test with TensorFlow-style preprocessing
        classifyImage(image)
    }
    
    private func classifyImage(_ image: UIImage) {
        guard let model = try? DrawingClassifier(configuration: MLModelConfiguration()) else {
            predictionResult = "Error: Could not load DrawingClassifier model"
            return
        }
        
        guard let multiArray = image.toMLMultiArray() else {
            predictionResult = "Error: Could not convert image to MLMultiArray"
            return
        }
        
        do {
            print("Making prediction...")
            let prediction = try model.prediction(input_2: multiArray)
            
            let classLabel = prediction.classLabel
            let probabilities = prediction.Identity
            let confidence = probabilities[classLabel] ?? 0.0
            
            print("\n🎯 PREDICTION RESULTS:")
            print(String(repeating: "-", count: 30))
            print("Predicted Class: \(classLabel)")
            print("Confidence: \(String(format: "%.1%%", confidence * 100))")
            print("Raw confidence: \(String(format: "%.4f", confidence))")
            
            print("\n📊 TOP 10 CLASS PROBABILITIES:")
            print(String(repeating: "-", count: 30))
            let topPredictions = probabilities.sorted(by: { $0.value > $1.value }).prefix(10)
            for (i, (className, probability)) in topPredictions.enumerated() {
                let status = className == classLabel ? "👑" : "  "
                print("\(status) \(i+1). \(className): \(String(format: "%.1%%", probability * 100))")
            }
            
            // Update UI
            var detailedResult = "🎯 \(classLabel) (\(String(format: "%.1%%", confidence * 100)))\n\nTop predictions:\n"
            for (i, (className, probability)) in topPredictions.prefix(5).enumerated() {
                detailedResult += "\(i+1). \(className): \(String(format: "%.1%%", probability * 100))\n"
            }
            predictionResult = detailedResult
            
            // Final verdict
            print("\n" + String(repeating: "=", count: 50))
            if classLabel.lowercased().contains("tree") {
                print("🎉 SUCCESS! Model correctly identified the tree!")
            } else {
                print("🤔 Hmm, model thinks this is a \(classLabel), not a tree.")
            }
            print(String(repeating: "=", count: 50))
            
        } catch {
            predictionResult = "Error: \(error.localizedDescription)"
            print("❌ Prediction error: \(error.localizedDescription)")
        }
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        // Check photo library authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            saveImage(image)
        case .denied, .restricted:
            alertTitle = "Permission Denied"
            alertMessage = "Please enable photo library access in Settings to save your drawing."
            showingAlert = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        saveImage(image)
                    } else {
                        alertTitle = "Permission Denied"
                        alertMessage = "Photo library access is required to save your drawing."
                        showingAlert = true
                    }
                }
            }
        @unknown default:
            alertTitle = "Error"
            alertMessage = "Unknown authorization status."
            showingAlert = true
        }
    }
    
    private func saveImage(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    alertTitle = "Success!"
                    alertMessage = "Your drawing has been saved to Photos."
                    showingAlert = true
                } else {
                    alertTitle = "Error"
                    alertMessage = "Failed to save drawing: \(error?.localizedDescription ?? "Unknown error")"
                    showingAlert = true
                }
            }
        }
    }
    
    private func generateImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Force 1x scale for exact 256x256 pixels
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format)
        
        return renderer.image { context in
            // Fill white background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
            
            // Draw all paths
            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineWidth(3)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            for path in paths {
                cgContext.addPath(path.cgPath)
                cgContext.strokePath()
            }
            
            // Draw current path
            if !currentPath.isEmpty {
                cgContext.addPath(currentPath.cgPath)
                cgContext.strokePath()
            }
        }
    }
}

// Extension to convert UIImage to MLMultiArray (matching TensorFlow preprocessing)
extension UIImage {
    /// Convert a 256×256 grayscale UIImage to MLMultiArray matching [1, 256, 256, 1]
    /// ✅ NO pixel scaling — matches your training if you did not rescale
    func toMLMultiArray() -> MLMultiArray? {
        let width = 256
        let height = 256

        // Check size
        guard Int(self.size.width) == width, Int(self.size.height) == height else {
            print("❌ Image must be 256×256. Got: \(self.size)")
            return nil
        }

        // Create MLMultiArray [1, 256, 256, 1]
        guard let multiArray = try? MLMultiArray(
            shape: [1, NSNumber(value: height), NSNumber(value: width), 1],
            dataType: .float32
        ) else {
            print("❌ Could not create MLMultiArray")
            return nil
        }

        // Convert to grayscale CGImage
        guard let cgImage = self.cgImage else {
            print("❌ Could not get CGImage")
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("❌ Could not create CGContext")
            return nil
        }

        // Draw image into context → get raw grayscale pixel data
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            print("❌ Could not get pixel data")
            return nil
        }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height)

        // Fill MLMultiArray with **RAW pixel values [0–255]**
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let pixelValue = Float(data[pixelIndex]) // ✅ RAW — NO /255!
                multiArray[[0, NSNumber(value: y), NSNumber(value: x), 0]] = NSNumber(value: pixelValue)
            }
        }

        // Debug sample pixels
        print("✅ Converted image to MLMultiArray [1, 256, 256, 1] (no scaling)")
        print("Sample pixels:")
        print("  Top-left: \(multiArray[[0, 0, 0, 0]])")
        print("  Center: \(multiArray[[0, NSNumber(value: height/2), NSNumber(value: width/2), 0]])")
        print("  Bottom-right: \(multiArray[[0, NSNumber(value: height-1), NSNumber(value: width-1), 0]])")

        return multiArray
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}

// MARK: - App Entry Point
// Remove this if you already have @main in your App.swift file
/*
@main
struct DrawingApp: App {
 var body: some Scene {
     WindowGroup {
         ContentView()
     }
 }
}
*/
