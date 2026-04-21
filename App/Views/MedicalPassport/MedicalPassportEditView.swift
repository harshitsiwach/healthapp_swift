import SwiftUI

// MARK: - Medical Passport Edit View

struct MedicalPassportEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let passport: MedicalPassport
    
    @State private var bloodType: String
    @State private var heightCm: String
    @State private var weightKg: String
    
    @State private var allergies: [String]
    @State private var newAllergy = ""
    @State private var conditions: [String]
    @State private var newCondition = ""
    
    @State private var medications: [Medication]
    @State private var contacts: [EmergencyContact]
    @State private var insurance: InsuranceInfo
    @State private var doctor: DoctorInfo
    
    @State private var qrShareLevel: String
    
    let bloodTypes = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    init(passport: MedicalPassport) {
        self.passport = passport
        self._bloodType = State(initialValue: passport.bloodType)
        self._heightCm = State(initialValue: passport.heightCm > 0 ? "\(Int(passport.heightCm))" : "")
        self._weightKg = State(initialValue: passport.weightKg > 0 ? "\(Int(passport.weightKg))" : "")
        self._allergies = State(initialValue: passport.allergies)
        self._conditions = State(initialValue: passport.conditions)
        self._medications = State(initialValue: passport.medications.isEmpty ? [Medication()] : passport.medications)
        self._contacts = State(initialValue: passport.emergencyContacts.isEmpty ? [EmergencyContact()] : passport.emergencyContacts)
        self._insurance = State(initialValue: passport.insurance)
        self._doctor = State(initialValue: passport.doctor)
        self._qrShareLevel = State(initialValue: passport.qrShareLevel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Blood Type + Body
                    basicInfoSection
                    
                    // Allergies
                    allergiesSection
                    
                    // Conditions
                    conditionsSection
                    
                    // Medications
                    medicationsSection
                    
                    // Emergency Contacts
                    contactsSection
                    
                    // Insurance & Doctor
                    insuranceSection
                    
                    // QR Privacy
                    qrPrivacySection
                    
                    saveButton
                }
                .padding()
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Edit Passport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Basic Info", icon: "person.fill")
            
            // Blood Type Picker
            Menu {
                ForEach(bloodTypes, id: \.self) { type in
                    Button(type) { bloodType = type }
                }
            } label: {
                HStack {
                    Text("Blood Type")
                        .foregroundStyle(colors.textSecondary)
                    Spacer()
                    Text(bloodType)
                        .foregroundStyle(bloodType == "Unknown" ? colors.textTertiary : colors.neonRed)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(colors.textTertiary)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                fieldInput("Height (cm)", text: $heightCm, icon: "ruler")
                fieldInput("Weight (kg)", text: $weightKg, icon: "scalemass")
            }
        }
        .themedCard()
    }
    
    // MARK: - Allergies
    
    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Allergies", icon: "exclamationmark.triangle.fill", color: colors.neonOrange)
            
            FlowLayout(spacing: 6) {
                ForEach(allergies, id: \.self) { allergy in
                    HStack(spacing: 4) {
                        Text(allergy)
                        Button {
                            allergies.removeAll { $0 == allergy }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(colors.neonOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(colors.neonOrange.opacity(0.15)))
                }
            }
            
            HStack {
                TextField("Add allergy...", text: $newAllergy)
                    .foregroundStyle(colors.textPrimary)
                    .onSubmit { addAllergy() }
                Button("Add") { addAllergy() }
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(colors.neonOrange)
                    .disabled(newAllergy.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
        }
        .themedCard()
    }
    
    // MARK: - Conditions
    
    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Medical Conditions", icon: "heart.text.square.fill", color: colors.neonPurple)
            
            FlowLayout(spacing: 6) {
                ForEach(conditions, id: \.self) { condition in
                    HStack(spacing: 4) {
                        Text(condition)
                        Button {
                            conditions.removeAll { $0 == condition }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(colors.neonPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(colors.neonPurple.opacity(0.15)))
                }
            }
            
            HStack {
                TextField("Add condition...", text: $newCondition)
                    .foregroundStyle(colors.textPrimary)
                    .onSubmit { addCondition() }
                Button("Add") { addCondition() }
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(colors.neonPurple)
                    .disabled(newCondition.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
        }
        .themedCard()
    }
    
    // MARK: - Medications
    
    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                sectionHeader("Medications", icon: "pill.fill", color: colors.neonBlue)
                Spacer()
                Button {
                    medications.append(Medication())
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(colors.neonBlue)
                }
            }
            
            ForEach(medications.indices, id: \.self) { i in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        TextField("Medication name", text: $medications[i].name)
                            .foregroundStyle(colors.textPrimary)
                        if medications.count > 1 {
                            Button {
                                medications.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(colors.neonRed)
                            }
                        }
                    }
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        TextField("Dosage (e.g. 500mg)", text: $medications[i].dosage)
                            .foregroundStyle(colors.textPrimary)
                        TextField("Frequency", text: $medications[i].frequency)
                            .foregroundStyle(colors.textPrimary)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
        }
        .themedCard()
    }
    
    // MARK: - Emergency Contacts
    
    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                sectionHeader("Emergency Contacts", icon: "phone.circle.fill", color: colors.neonRed)
                Spacer()
                Button {
                    contacts.append(EmergencyContact())
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(colors.neonRed)
                }
            }
            
            ForEach(contacts.indices, id: \.self) { i in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        TextField("Contact name", text: $contacts[i].name)
                            .foregroundStyle(colors.textPrimary)
                        if contacts.count > 1 {
                            Button { contacts.remove(at: i) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(colors.neonRed)
                            }
                        }
                    }
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        TextField("Phone number", text: $contacts[i].phone)
                            .keyboardType(.phonePad)
                            .foregroundStyle(colors.textPrimary)
                        TextField("Relation", text: $contacts[i].relation)
                            .foregroundStyle(colors.textPrimary)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
            }
        }
        .themedCard()
    }
    
    // MARK: - Insurance & Doctor
    
    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Insurance", icon: "creditcard.fill", color: colors.neonBlue)
            
            fieldInput("Provider", text: $insurance.provider, icon: "building.2")
            fieldInput("Policy Number", text: $insurance.policyNumber, icon: "number")
            fieldInput("Group Number", text: $insurance.groupNumber, icon: "number")
            
            sectionHeader("Primary Doctor", icon: "stethoscope", color: colors.neonGreen)
                .padding(.top, 4)
            
            fieldInput("Doctor Name", text: $doctor.name, icon: "person")
            fieldInput("Specialty", text: $doctor.specialty, icon: "cross.case")
            fieldInput("Phone", text: $doctor.phone, icon: "phone")
                .keyboardType(.phonePad)
        }
        .themedCard()
    }
    
    // MARK: - QR Privacy
    
    private var qrPrivacySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("QR Code Sharing", icon: "qrcode", color: colors.neonPurple)
            
            Toggle(isOn: Binding(
                get: { passport.isQRSharingEnabled },
                set: { passport.isQRSharingEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable QR Sharing")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                    Text("Allow emergency access to your medical info")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .tint(colors.neonPurple)
            
            Picker("Share Level", selection: $qrShareLevel) {
                Text("Critical Only").tag("critical")
                Text("Full Profile").tag("full")
            }
            .pickerStyle(.segmented)
            
            Text(qrShareLevel == "critical"
                 ? "Shares: Blood type, allergies, medications, emergency contacts"
                 : "Shares: Everything including vaccinations, insurance, doctor info")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textTertiary)
        }
        .themedCard()
    }
    
    // MARK: - Save
    
    private var saveButton: some View {
        Button {
            save()
            Haptic.notification(.success)
            dismiss()
        } label: {
            Text("Save Passport")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonPurple.gradient))
        }
        .buttonStyle(.scaleButton)
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String, icon: String, color: Color? = nil) -> some View {
        Label(title, systemImage: icon)
            .font(DesignSystem.Typography.subheadline)
            .foregroundStyle(color ?? colors.textPrimary)
    }
    
    private func fieldInput(_ label: String, text: Binding<String>, icon: String = "text.alignleft") -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(colors.textTertiary)
                .frame(width: 16)
            TextField(label, text: text)
                .foregroundStyle(colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
    }
    
    private func addAllergy() {
        let trimmed = newAllergy.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !allergies.contains(trimmed) else { return }
        allergies.append(trimmed)
        newAllergy = ""
    }
    
    private func addCondition() {
        let trimmed = newCondition.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !conditions.contains(trimmed) else { return }
        conditions.append(trimmed)
        newCondition = ""
    }
    
    private func save() {
        passport.bloodType = bloodType
        passport.heightCm = Double(heightCm) ?? 0
        passport.weightKg = Double(weightKg) ?? 0
        passport.allergies = allergies
        passport.conditions = conditions
        passport.medications = medications.filter { !$0.name.isEmpty }
        passport.emergencyContacts = contacts.filter { !$0.name.isEmpty }
        passport.insurance = insurance
        passport.doctor = doctor
        passport.qrShareLevel = qrShareLevel
        try? passport.modelContext?.save()
    }
}
