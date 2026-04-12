import Foundation
import Vision
import UIKit

// MARK: - Medical Report OCR Service

final class MedicalReportOCR {
    
    static let shared = MedicalReportOCR()
    private init() {}
    
    // MARK: - Extract Text from Image
    
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.customWords = MedicalTerminology.commonTerms
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Parse Lab Report
    
    func parseLabReport(from text: String) -> LabReport {
        let lines = text.components(separatedBy: .newlines)
        
        var tests: [LabTest] = []
        var reportDate: Date?
        
        // Try to find report date using basic date patterns
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_IN")
        
        let dateFormats = ["dd/MM/yyyy", "dd-MM-yyyy", "MM/dd/yyyy", "dd MMM yyyy", "MMM dd, yyyy"]
        
        for line in lines {
            for format in dateFormats {
                dateFormatter.dateFormat = format
                let words = line.components(separatedBy: .whitespaces)
                for word in words {
                    if let date = dateFormatter.date(from: word.trimmingCharacters(in: .punctuationCharacters)) {
                        reportDate = date
                        break
                    }
                }
                if reportDate != nil { break }
            }
            if reportDate != nil { break }
        }
        
        // Parse lab tests
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.count > 5 else { continue }
            
            if let test = parseTestLine(trimmed) {
                tests.append(test)
            }
        }
        
        return LabReport(
            date: reportDate ?? Date(),
            patientName: nil,
            labName: nil,
            tests: tests,
            rawText: text
        )
    }
    
    // MARK: - Parse Single Test Line
    
    private func parseTestLine(_ line: String) -> LabTest? {
        // Split by common delimiters
        let components = line.components(separatedBy: CharacterSet(charactersIn: ":"))
        
        var testName = ""
        var valueStr = ""
        var unit = ""
        var flag: String?
        var normalRange: ClosedRange<Double>?
        
        if components.count >= 2 {
            // Format: "Test Name: Value Unit" or "Test Name: Value Unit (Range) Flag"
            testName = components[0].trimmingCharacters(in: .whitespaces)
            let rest = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            
            // Extract value, unit, range, and flag from rest
            let parts = rest.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            if let firstNum = parts.first, let value = Double(firstNum) {
                valueStr = firstNum
                
                // Check for unit
                if parts.count > 1 {
                    let possibleUnit = parts[1]
                    if possibleUnit.rangeOfCharacter(from: .letters) != nil && possibleUnit.count <= 10 {
                        unit = possibleUnit
                    }
                }
                
                // Check for flag
                let flagWords = ["LOW", "HIGH", "NORMAL", "ABNORMAL", "Borderline"]
                for part in parts {
                    if flagWords.contains(part.uppercased()) {
                        flag = part.uppercased()
                        break
                    }
                }
                
                // Check for range like (12.0-16.0) or 12.0-16.0
                for part in parts {
                    let cleaned = part.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    let rangeParts = cleaned.components(separatedBy: "-")
                    if rangeParts.count == 2,
                       let low = Double(rangeParts[0]),
                       let high = Double(rangeParts[1]),
                       low < high {
                        normalRange = low...high
                        break
                    }
                }
            }
        } else {
            // Try to parse: "Test Name Value Unit"
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Find the first number in the parts
            var valueIndex = -1
            for (index, part) in parts.enumerated() {
                if Double(part) != nil {
                    valueIndex = index
                    break
                }
            }
            
            if valueIndex > 0 {
                testName = parts[0..<valueIndex].joined(separator: " ")
                valueStr = parts[valueIndex]
                
                if valueIndex + 1 < parts.count {
                    let possibleUnit = parts[valueIndex + 1]
                    if possibleUnit.rangeOfCharacter(from: .letters) != nil {
                        unit = possibleUnit
                    }
                }
                
                let flagWords = ["LOW", "HIGH", "NORMAL", "ABNORMAL"]
                for part in parts[(valueIndex + 1)...] {
                    if flagWords.contains(part.uppercased()) {
                        flag = part.uppercased()
                        break
                    }
                }
            }
        }
        
        guard let value = Double(valueStr), !testName.isEmpty, testName.count > 2 else {
            return nil
        }
        
        // Determine status
        var status: LabTest.TestStatus = .normal
        if let flag = flag {
            if flag == "HIGH" || flag == "ABNORMAL" {
                status = .high
            } else if flag == "LOW" {
                status = .low
            } else if flag == "BORDERLINE" {
                status = .borderline
            }
        } else if let range = normalRange {
            if value < range.lowerBound {
                status = .low
            } else if value > range.upperBound {
                status = .high
            }
        }
        
        return LabTest(
            name: normalizeTestName(testName),
            value: value,
            unit: unit,
            normalRange: normalRange,
            status: status
        )
    }
    
    // MARK: - Helpers
    
    private func normalizeTestName(_ name: String) -> String {
        let normalizations: [String: String] = [
            "haemoglobin": "Hemoglobin",
            "hb": "Hemoglobin",
            "rbc": "Red Blood Cells",
            "wbc": "White Blood Cells",
            "plt": "Platelets",
            "hba1c": "HbA1c",
            "tsh": "TSH (Thyroid)",
            "t3": "T3 (Thyroid)",
            "t4": "T4 (Thyroid)",
            "ldl": "LDL Cholesterol",
            "hdl": "HDL Cholesterol",
            "vldl": "VLDL Cholesterol",
            "sgpt": "SGPT/ALT",
            "sgot": "SGOT/AST",
            "bun": "Blood Urea Nitrogen",
            "rbs": "Random Blood Sugar",
            "fbs": "Fasting Blood Sugar",
            "ppbs": "Post-Prandial Blood Sugar"
        ]
        
        let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
        return normalizations[lower] ?? name.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Supporting Types

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .noTextFound: return "No text found in the image. Try a clearer photo."
        case .processingFailed: return "Failed to process the document."
        }
    }
}

struct LabReport: Identifiable {
    let id = UUID()
    let date: Date
    let patientName: String?
    let labName: String?
    let tests: [LabTest]
    let rawText: String
    
    var abnormalTests: [LabTest] {
        tests.filter { $0.status != .normal }
    }
    
    var summary: String {
        if abnormalTests.isEmpty {
            return "All tests within normal range"
        }
        let names = abnormalTests.map { $0.name }.joined(separator: ", ")
        return "Abnormal values: \(names)"
    }
}

struct LabTest: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let unit: String
    let normalRange: ClosedRange<Double>?
    let status: TestStatus
    
    enum TestStatus: String {
        case normal = "Normal"
        case high = "High"
        case low = "Low"
        case borderline = "Borderline"
        
        var color: String {
            switch self {
            case .normal: return "green"
            case .high: return "red"
            case .low: return "orange"
            case .borderline: return "yellow"
            }
        }
    }
}

// MARK: - Medical Terminology Helper

enum MedicalTerminology {
    static let commonTerms = [
        "Hemoglobin", "Glucose", "Cholesterol", "Triglycerides",
        "Creatinine", "Urea", "Bilirubin", "Albumin",
        "HbA1c", "TSH", "Calcium", "Sodium", "Potassium",
        "Platelets", "WBC", "RBC", "ESR", "CRP",
        "LDL", "HDL", "VLDL", "SGPT", "SGOT",
        "Vitamin D", "Vitamin B12", "Iron", "Ferritin",
        "Uric Acid", "Amylase", "Lipase", "ALT", "AST"
    ]
}
