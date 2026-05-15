import SwiftUI
import SwiftData

// MARK: - Medical Passport View

struct MedicalPassportView: View {
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Query private var passports: [MedicalPassport]
    
    @State private var showingEdit = false
    @State private var showingQR = false
    @State private var showingVaccinations = false
    @State private var showingExport = false
    @State private var animateIn = false
    
    private var passport: MedicalPassport {
        if let existing = passports.first { return existing }
        let new = MedicalPassport()
        modelContext.insert(new)
        try? modelContext.save()
        return new
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header Card
                headerCard
                
                // Critical Info
                criticalInfoCard
                
                // Allergies & Conditions
                if !passport.allergies.isEmpty || !passport.conditions.isEmpty {
                    allergiesConditionsCard
                }
                
                // Medications
                if !passport.medications.isEmpty {
                    medicationsCard
                }
                
                // Quick Actions
                quickActions
                
                // Vaccinations
                vaccinationsCard
                
                // Emergency Contacts
                if !passport.emergencyContacts.isEmpty {
                    emergencyContactsCard
                }
                
                // Insurance & Doctor
                if passport.insurance.provider.isEmpty == false || passport.doctor.name.isEmpty == false {
                    insuranceDoctorCard
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Medical Passport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptic.selection()
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(colors.neonPurple)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            MedicalPassportEditView(passport: passport)
        }
        .sheet(isPresented: $showingQR) {
            QRCodeView(passport: passport)
        }
        .sheet(isPresented: $showingVaccinations) {
            VaccinationTrackerView(passport: passport)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) { animateIn = true }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                // Completion ring
                Circle()
                    .stroke(colors.cardBorder, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: passport.completionPercentage)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [colors.neonPurple, colors.neonBlue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(colors.neonPurple)
                    Text("\(Int(passport.completionPercentage * 100))%")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.textPrimary)
                }
            }
            
            Text("Medical Passport")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(colors.textPrimary)
            
            Text("Your portable health profile")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
            
            if passport.completionPercentage < 1.0 {
                Button {
                    Haptic.selection()
                    showingEdit = true
                } label: {
                    Text("Complete Your Profile")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(colors.neonPurple.gradient))
                }
                .buttonStyle(.scaleButton)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .strokeBorder(colors.neonPurple.opacity(0.3)))
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Critical Info
    
    private var criticalInfoCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Label("Critical Info", systemImage: "exclamationmark.shield.fill")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonRed)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                infoTile(icon: "drop.fill", label: "Blood Type", value: passport.bloodType, color: colors.neonRed)
                infoTile(icon: "ruler", label: "Height", value: passport.heightCm > 0 ? "\(Int(passport.heightCm)) cm" : "Not set", color: colors.neonBlue)
                infoTile(icon: "scalemass.fill", label: "Weight", value: passport.weightKg > 0 ? "\(Int(passport.weightKg)) kg" : "Not set", color: colors.neonGreen)
                infoTile(icon: "heart.fill", label: "BMI", value: passport.bmi > 0 ? String(format: "%.1f", passport.bmi) : "Not set", color: passport.bmi > 0 ? bmiColor : colors.textTertiary)
            }
        }
        .themedCard()
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private var bmiColor: Color {
        if passport.bmi < 18.5 { return colors.neonBlue }
        if passport.bmi < 25 { return colors.neonGreen }
        if passport.bmi < 30 { return colors.neonYellow }
        return colors.neonRed
    }
    
    private func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
                Text(value)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
    }
    
    // MARK: - Allergies & Conditions
    
    private var allergiesConditionsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if !passport.allergies.isEmpty {
                Label("Allergies", systemImage: "exclamationmark.triangle.fill")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.neonOrange)
                
                FlowLayout(spacing: 6) {
                    ForEach(passport.allergies, id: \.self) { allergy in
                        Text(allergy)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(colors.neonOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(colors.neonOrange.opacity(0.15)))
                    }
                }
            }
            
            if !passport.conditions.isEmpty {
                Label("Conditions", systemImage: "heart.text.square.fill")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.neonPurple)
                    .padding(.top, passport.allergies.isEmpty ? 0 : 4)
                
                FlowLayout(spacing: 6) {
                    ForEach(passport.conditions, id: \.self) { condition in
                        Text(condition)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(colors.neonPurple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(colors.neonPurple.opacity(0.15)))
                    }
                }
            }
        }
        .themedCard()
    }
    
    // MARK: - Medications
    
    private var medicationsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Label("Medications", systemImage: "pill.fill")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonBlue)
            
            ForEach(passport.medications) { med in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(med.name)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text("\(med.dosage) · \(med.frequency)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "pill.fill")
                        .foregroundStyle(colors.neonBlue.opacity(0.5))
                }
                .padding(DesignSystem.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
        }
        .themedCard()
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                Haptic.impact(.light)
                showingQR = true
            } label: {
                quickActionLabel(icon: "qrcode", title: "QR Code", color: colors.neonPurple)
            }
            .buttonStyle(.scaleButton)
            
            Button {
                Haptic.impact(.light)
                showingVaccinations = true
            } label: {
                quickActionLabel(icon: "syringe.fill", title: "Vaccines", color: colors.neonGreen)
            }
            .buttonStyle(.scaleButton)
        }
    }
    
    private func quickActionLabel(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .themedCard(padding: DesignSystem.Spacing.sm)
    }
    
    // MARK: - Vaccinations
    
    private var vaccinationsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Label("Vaccinations", systemImage: "syringe.fill")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.neonGreen)
                Spacer()
                Button("Manage") {
                    showingVaccinations = true
                }
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(colors.neonGreen)
            }
            
            if passport.vaccinations.isEmpty {
                Text("No vaccinations recorded")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            } else {
                ForEach(passport.vaccinations.prefix(3)) { vax in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vax.name)
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundStyle(colors.textPrimary)
                            Text("\(vax.dose) · \(vax.date)")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(colors.neonGreen)
                    }
                }
                if passport.vaccinations.count > 3 {
                    Text("+ \(passport.vaccinations.count - 3) more")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
            }
        }
        .themedCard()
    }
    
    // MARK: - Emergency Contacts
    
    private var emergencyContactsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Label("Emergency Contacts", systemImage: "phone.circle.fill")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonRed)
            
            ForEach(passport.emergencyContacts) { contact in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text("\(contact.relation) · \(contact.phone)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    Spacer()
                    Link(destination: URL(string: "tel:\(contact.phone)") ?? URL(string: "about:blank")!) {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(colors.neonGreen)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(colors.neonGreen.opacity(0.15)))
                    }
                }
            }
        }
        .themedCard()
    }
    
    // MARK: - Insurance & Doctor
    
    private var insuranceDoctorCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if !passport.insurance.provider.isEmpty {
                Label("Insurance", systemImage: "creditcard.fill")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.neonBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(passport.insurance.provider)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                    if !passport.insurance.policyNumber.isEmpty {
                        Text("Policy: \(passport.insurance.policyNumber)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
            
            if !passport.doctor.name.isEmpty {
                Label("Primary Doctor", systemImage: "stethoscope")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.neonGreen)
                    .padding(.top, !passport.insurance.provider.isEmpty ? 4 : 0)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(passport.doctor.name)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                    if !passport.doctor.specialty.isEmpty {
                        Text(passport.doctor.specialty)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
        }
        .themedCard()
    }
}

