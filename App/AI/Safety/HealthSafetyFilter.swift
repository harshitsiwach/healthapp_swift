import Foundation

// MARK: - Health Safety Filter

final class HealthSafetyFilter {
    
    enum SafetyResult {
        case safe
        case blocked(category: String)
        case cautionRequired(warning: String)
    }
    
    // MARK: - High-Risk Keywords
    
    private let emergencyPatterns: [(pattern: String, category: String)] = [
        ("chest pain", "emergency symptoms"),
        ("heart attack", "emergency symptoms"),
        ("can't breathe", "emergency symptoms"),
        ("difficulty breathing", "emergency symptoms"),
        ("stroke", "emergency symptoms"),
        ("seizure", "emergency symptoms"),
        ("unconscious", "emergency symptoms"),
        ("suicidal", "mental health crisis"),
        ("want to die", "mental health crisis"),
        ("kill myself", "mental health crisis"),
        ("self harm", "mental health crisis"),
        ("overdose", "medication safety"),
        ("drug dosage", "medication dosing"),
        ("how much medicine", "medication dosing"),
        ("change my medication", "treatment changes"),
        ("stop taking", "treatment changes"),
        ("pregnant and should I", "pregnancy-critical advice"),
        ("baby medication", "pediatric high-risk"),
        ("child dosage", "pediatric high-risk"),
        ("infant treatment", "pediatric high-risk"),
    ]
    
    private let medicalDisclaimerCategories: Set<String> = [
        "medication dosing",
        "treatment changes",
        "pregnancy-critical advice",
        "pediatric high-risk",
    ]
    
    // MARK: - Input Check
    
    func checkInput(_ text: String, task: AITask) async -> SafetyResult {
        let lowered = text.lowercased()
        
        for (pattern, category) in emergencyPatterns {
            if lowered.contains(pattern) {
                if category == "emergency symptoms" || category == "mental health crisis" {
                    return .blocked(category: category)
                }
                if medicalDisclaimerCategories.contains(category) {
                    return .cautionRequired(warning: safetyMessage(for: category))
                }
            }
        }
        
        return .safe
    }
    
    // MARK: - Output Check
    
    func checkOutput(_ text: String, task: AITask) async -> SafetyResult {
        let lowered = text.lowercased()
        
        let dangerousPhrases = [
            "you should take",
            "increase your dosage",
            "decrease your dosage",
            "stop taking your medication",
            "you are diagnosed with",
            "this confirms you have",
            "you definitely have",
        ]
        
        for phrase in dangerousPhrases {
            if lowered.contains(phrase) {
                return .cautionRequired(warning: "This response may contain medical advice that should be verified by a healthcare professional.")
            }
        }
        
        return .safe
    }
    
    // MARK: - Safety Messages
    
    func safetyMessage(for category: String) -> String {
        switch category {
        case "emergency symptoms":
            return "⚠️ If you're experiencing a medical emergency, please call emergency services immediately (112 in India, 911 in US). This app cannot provide emergency medical assistance."
        case "mental health crisis":
            return "💙 If you're in crisis, please reach out for help:\n• Vandrevala Foundation: 1860-2662-345 (India)\n• iCall: 9152987821 (India)\n• Crisis Text Line: Text HOME to 741741\nYou are not alone."
        case "medication dosing":
            return "💊 This app cannot provide medication dosage advice. Please consult your doctor or pharmacist for medication questions."
        case "treatment changes":
            return "⚕️ Never change your treatment plan without consulting your healthcare provider. This app provides educational information only."
        case "pregnancy-critical advice":
            return "🤰 Pregnancy-related health decisions should always be discussed with your OB-GYN or healthcare provider."
        case "pediatric high-risk":
            return "👶 Children's health requires specialized medical guidance. Please consult a pediatrician."
        default:
            return "ℹ️ This information is for educational purposes only. Please consult a healthcare professional for medical advice."
        }
    }
    
    var generalDisclaimer: String {
        "This app provides educational health information only and is not a substitute for professional medical advice, diagnosis, or treatment."
    }
}
