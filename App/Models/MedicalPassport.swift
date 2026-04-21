import Foundation
import SwiftData

// MARK: - Medical Passport

@Model
final class MedicalPassport {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // Personal Info
    var bloodType: String // A+, A-, B+, B-, AB+, AB-, O+, O-, Unknown
    var heightCm: Double
    var weightKg: Double
    var dateOfBirth: String? // YYYY-MM-DD
    
    // Medical Info (stored as JSON strings for SwiftData compatibility)
    var allergiesJSON: String // ["Peanuts", "Penicillin"]
    var conditionsJSON: String // ["Diabetes Type 2", "Asthma"]
    var medicationsJSON: String // [{"name": "Metformin", "dosage": "500mg", "frequency": "Twice daily"}]
    var emergencyContactsJSON: String // [{"name": "Mom", "phone": "+1234", "relation": "Mother"}]
    var vaccinationsJSON: String // [{"name": "COVID-19", "date": "2024-01-15", "dose": "Booster"}]
    var insuranceJSON: String // {"provider": "Blue Cross", "policyNumber": "123", "groupNumber": "456"}
    var doctorJSON: String // {"name": "Dr. Smith", "phone": "+1234", "specialty": "General"}
    
    // Privacy
    var isQRSharingEnabled: Bool
    var qrShareLevel: String // "critical" = allergies + blood type + emergency, "full" = everything
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.bloodType = "Unknown"
        self.heightCm = 0
        self.weightKg = 0
        self.dateOfBirth = nil
        self.allergiesJSON = "[]"
        self.conditionsJSON = "[]"
        self.medicationsJSON = "[]"
        self.emergencyContactsJSON = "[]"
        self.vaccinationsJSON = "[]"
        self.insuranceJSON = "{}"
        self.doctorJSON = "{}"
        self.isQRSharingEnabled = true
        self.qrShareLevel = "critical"
    }
    
    // MARK: - Computed Properties
    
    var allergies: [String] {
        get { decodeJSON(allergiesJSON, defaultValue: []) }
        set { allergiesJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var conditions: [String] {
        get { decodeJSON(conditionsJSON, defaultValue: []) }
        set { conditionsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var medications: [Medication] {
        get { decodeJSON(medicationsJSON, defaultValue: []) }
        set { medicationsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var emergencyContacts: [EmergencyContact] {
        get { decodeJSON(emergencyContactsJSON, defaultValue: []) }
        set { emergencyContactsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var vaccinations: [Vaccination] {
        get { decodeJSON(vaccinationsJSON, defaultValue: []) }
        set { vaccinationsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var insurance: InsuranceInfo {
        get { decodeJSON(insuranceJSON, defaultValue: InsuranceInfo()) }
        set { insuranceJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var doctor: DoctorInfo {
        get { decodeJSON(doctorJSON, defaultValue: DoctorInfo()) }
        set { doctorJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var bmi: Double {
        guard heightCm > 0, weightKg > 0 else { return 0 }
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    var bmiCategory: String {
        if bmi <= 0 { return "Not set" }
        if bmi < 18.5 { return "Underweight" }
        if bmi < 25 { return "Normal" }
        if bmi < 30 { return "Overweight" }
        return "Obese"
    }
    
    var completionPercentage: Double {
        var filled = 0.0
        let total = 8.0
        if bloodType != "Unknown" { filled += 1 }
        if heightCm > 0 { filled += 1 }
        if weightKg > 0 { filled += 1 }
        if !allergies.isEmpty { filled += 1 }
        if !conditions.isEmpty { filled += 1 }
        if !medications.isEmpty { filled += 1 }
        if !emergencyContacts.isEmpty { filled += 1 }
        if !vaccinations.isEmpty { filled += 1 }
        return filled / total
    }
    
    // MARK: - QR Data
    
    var qrCriticalData: String {
        """
        {
            "blood_type": "\(bloodType)",
            "allergies": \(allergiesJSON),
            "conditions": \(conditionsJSON),
            "medications": \(medications.map { "\($0.name) \($0.dosage)" }),
            "emergency_contacts": \(emergencyContactsJSON)
        }
        """
    }
    
    var qrFullData: String {
        """
        {
            "blood_type": "\(bloodType)",
            "allergies": \(allergiesJSON),
            "conditions": \(conditionsJSON),
            "medications": \(medications.map { "\($0.name) \($0.dosage) \($0.frequency)" }),
            "emergency_contacts": \(emergencyContactsJSON),
            "vaccinations": \(vaccinationsJSON),
            "bmi": \(bmi),
            "insurance": "\(insurance.provider)",
            "doctor": "\(doctor.name)"
        }
        """
    }
    
    var qrPayload: String {
        qrShareLevel == "full" ? qrFullData : qrCriticalData
    }
    
    // MARK: - Helpers
    
    private func decodeJSON<T: Decodable>(_ json: String, defaultValue: T) -> T {
        guard let data = json.data(using: .utf8) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }
    
    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

// MARK: - Supporting Models

struct Medication: Codable, Identifiable {
    var id = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var notes: String
    
    init(name: String = "", dosage: String = "", frequency: String = "", notes: String = "") {
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.notes = notes
    }
}

struct EmergencyContact: Codable, Identifiable {
    var id = UUID()
    var name: String
    var phone: String
    var relation: String
    
    init(name: String = "", phone: String = "", relation: String = "") {
        self.name = name
        self.phone = phone
        self.relation = relation
    }
}

struct Vaccination: Codable, Identifiable {
    var id = UUID()
    var name: String
    var date: String
    var dose: String
    var provider: String
    
    init(name: String = "", date: String = "", dose: String = "", provider: String = "") {
        self.name = name
        self.date = date
        self.dose = dose
        self.provider = provider
    }
}

struct InsuranceInfo: Codable {
    var provider: String
    var policyNumber: String
    var groupNumber: String
    var memberID: String
    
    init(provider: String = "", policyNumber: String = "", groupNumber: String = "", memberID: String = "") {
        self.provider = provider
        self.policyNumber = policyNumber
        self.groupNumber = groupNumber
        self.memberID = memberID
    }
}

struct DoctorInfo: Codable {
    var name: String
    var phone: String
    var specialty: String
    var clinic: String
    
    init(name: String = "", phone: String = "", specialty: String = "", clinic: String = "") {
        self.name = name
        self.phone = phone
        self.specialty = specialty
        self.clinic = clinic
    }
}
