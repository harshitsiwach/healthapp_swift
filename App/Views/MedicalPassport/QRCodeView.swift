import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QR Code View

struct QRCodeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let passport: MedicalPassport
    
    @State private var selectedLevel: String
    @State private var showPulse = false
    
    init(passport: MedicalPassport) {
        self.passport = passport
        self._selectedLevel = State(initialValue: passport.qrShareLevel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Title
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 40))
                        .foregroundStyle(colors.neonPurple)
                        .neonGlow(colors.neonPurple, intensity: 0.5)
                    
                    Text("Medical QR Code")
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("Scan to view your medical info")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                
                // QR Code
                ZStack {
                    // Pulse rings
                    if showPulse {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(colors.neonPurple.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                                .frame(width: 260 + CGFloat(i) * 30, height: 260 + CGFloat(i) * 30)
                                .scaleEffect(showPulse ? 1.1 : 0.9)
                                .opacity(showPulse ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 2)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.5),
                                    value: showPulse
                                )
                        }
                    }
                    
                    // QR Code image
                    if let qrImage = generateQRCode() {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.white)
                                    .padding(-12)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(colors.backgroundCard)
                                    .overlay(RoundedRectangle(cornerRadius: 24)
                                        .strokeBorder(colors.neonPurple.opacity(0.3), lineWidth: 2))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colors.backgroundElevated)
                            .frame(width: 220, height: 220)
                            .overlay(
                                Text("Add medical data\nto generate QR")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(colors.textTertiary)
                                    .multilineTextAlignment(.center)
                            )
                    }
                }
                .onAppear { showPulse = true }
                
                // Share Level Picker
                Picker("Share Level", selection: $selectedLevel) {
                    Text("Critical").tag("critical")
                    Text("Full").tag("full")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // What's shared
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Shared Information:")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.textPrimary)
                    
                    let items = selectedLevel == "critical" ? criticalItems : fullItems
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(colors.neonGreen)
                            Text(item)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).fill(colors.backgroundElevated))
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                Spacer()
                
                // Info
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(colors.neonPurple)
                    Text("Data is encoded locally. Nothing is sent to servers.")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonPurple)
                }
            }
        }
    }
    
    private var criticalItems: [String] {
        var items: [String] = []
        if passport.bloodType != "Unknown" { items.append("Blood Type: \(passport.bloodType)") }
        if !passport.allergies.isEmpty { items.append("Allergies: \(passport.allergies.joined(separator: ", "))") }
        if !passport.conditions.isEmpty { items.append("Conditions: \(passport.conditions.joined(separator: ", "))") }
        if !passport.medications.isEmpty { items.append("Medications: \(passport.medications.count) listed") }
        if !passport.emergencyContacts.isEmpty { items.append("Emergency Contacts: \(passport.emergencyContacts.count)") }
        if items.isEmpty { items.append("No data yet — add info in Edit") }
        return items
    }
    
    private var fullItems: [String] {
        var items = criticalItems
        if !passport.vaccinations.isEmpty { items.append("Vaccinations: \(passport.vaccinations.count) records") }
        if passport.bmi > 0 { items.append("BMI: \(String(format: "%.1f", passport.bmi))") }
        if !passport.insurance.provider.isEmpty { items.append("Insurance: \(passport.insurance.provider)") }
        if !passport.doctor.name.isEmpty { items.append("Doctor: \(passport.doctor.name)") }
        return items
    }
    
    private func generateQRCode() -> UIImage? {
        let data = passport.qrPayload
        guard !data.isEmpty, data != "{}" else { return nil }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(data.utf8)
        filter.correctionLevel = "H"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}
