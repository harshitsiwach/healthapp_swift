import SwiftUI

// MARK: - Vaccination Tracker View

struct VaccinationTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let passport: MedicalPassport
    
    @State private var vaccinations: [Vaccination]
    @State private var showingAdd = false
    
    init(passport: MedicalPassport) {
        self.passport = passport
        self._vaccinations = State(initialValue: passport.vaccinations)
    }
    
    let commonVaccines = [
        ("COVID-19", "syringe"),
        ("Hepatitis B", "syringe"),
        ("Hepatitis A", "syringe"),
        ("Tetanus", "syringe"),
        ("Influenza (Flu)", "syringe"),
        ("MMR (Measles, Mumps, Rubella)", "syringe"),
        ("HPV", "syringe"),
        ("Typhoid", "syringe"),
        ("Yellow Fever", "syringe"),
        ("Rabies", "syringe"),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "syringe.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(colors.neonGreen)
                            .neonGlow(colors.neonGreen, intensity: 0.4)
                        
                        Text("Vaccination Records")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(colors.textPrimary)
                        
                        Text("\(vaccinations.count) vaccines recorded")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Quick Add Common Vaccines
                    if vaccinations.isEmpty || vaccinations.count < 5 {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Quick Add Common Vaccines")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(colors.textPrimary)
                            
                            ForEach(commonVaccines, id: \.0) { vaccine in
                                let alreadyAdded = vaccinations.contains { $0.name == vaccine.0 }
                                Button {
                                    if !alreadyAdded {
                                        Haptic.selection()
                                        var newVax = Vaccination(name: vaccine.0, dose: "Dose 1")
                                        vaccinations.append(newVax)
                                        saveVaccinations()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: vaccine.1)
                                            .foregroundStyle(alreadyAdded ? colors.neonGreen : colors.neonGreen.opacity(0.5))
                                        Text(vaccine.0)
                                            .font(DesignSystem.Typography.body)
                                            .foregroundStyle(colors.textPrimary)
                                        Spacer()
                                        if alreadyAdded {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(colors.neonGreen)
                                        } else {
                                            Image(systemName: "plus.circle")
                                                .foregroundStyle(colors.textTertiary)
                                        }
                                    }
                                    .padding(DesignSystem.Spacing.sm)
                                    .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .themedCard()
                    }
                    
                    // Recorded Vaccines
                    if !vaccinations.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Your Vaccines")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(colors.textPrimary)
                            
                            ForEach(vaccinations) { vax in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vax.name)
                                            .font(DesignSystem.Typography.bodyBold)
                                            .foregroundStyle(colors.textPrimary)
                                        HStack(spacing: 4) {
                                            if !vax.dose.isEmpty {
                                                Text(vax.dose)
                                                    .foregroundStyle(colors.neonGreen)
                                            }
                                            if !vax.date.isEmpty {
                                                Text("· \(vax.date)")
                                                    .foregroundStyle(colors.textSecondary)
                                            }
                                        }
                                        .font(DesignSystem.Typography.caption2)
                                    }
                                    Spacer()
                                    Button {
                                        vaccinations.removeAll { $0.id == vax.id }
                                        saveVaccinations()
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundStyle(colors.neonRed.opacity(0.6))
                                    }
                                }
                                .padding(DesignSystem.Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
                            }
                        }
                        .themedCard()
                    }
                    
                    // Custom Add
                    Button {
                        showingAdd = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Vaccine")
                        }
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.neonGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(colors.neonGreen.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.scaleButton)
                    .padding(.horizontal)
                }
                .padding()
                .padding(.bottom, 100)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Vaccines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonGreen)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddVaccinationSheet { newVax in
                    vaccinations.append(newVax)
                    saveVaccinations()
                }
            }
        }
    }
    
    private func saveVaccinations() {
        passport.vaccinations = vaccinations
        try? passport.modelContext?.save()
    }
}

// MARK: - Add Vaccination Sheet

struct AddVaccinationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let onSave: (Vaccination) -> Void
    
    @State private var name = ""
    @State private var dose = ""
    @State private var date = ""
    @State private var provider = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                fieldInput("Vaccine Name", text: $name, icon: "syringe")
                fieldInput("Dose (e.g. Booster, Dose 2)", text: $dose, icon: "number")
                fieldInput("Date (e.g. 2024-01-15)", text: $date, icon: "calendar")
                fieldInput("Provider (optional)", text: $provider, icon: "building.2")
                
                Spacer()
                
                Button {
                    let vax = Vaccination(name: name, date: date, dose: dose, provider: provider)
                    onSave(vax)
                    Haptic.notification(.success)
                    dismiss()
                } label: {
                    Text("Add Vaccine")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(name.isEmpty ? AnyShapeStyle(colors.textTertiary.opacity(0.3)) : AnyShapeStyle(colors.neonGreen)))
                }
                .buttonStyle(.scaleButton)
                .disabled(name.isEmpty)
            }
            .padding()
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Add Vaccine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
    
    private func fieldInput(_ label: String, text: Binding<String>, icon: String) -> some View {
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
}
