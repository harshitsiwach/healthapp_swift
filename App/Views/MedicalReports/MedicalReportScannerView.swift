import SwiftUI
import PhotosUI

struct MedicalReportScannerView: View {
    @Environment(\.theme) var colors
    @StateObject private var viewModel = MedicalReportViewModel()
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    GlassCard(material: .regularMaterial) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                    .foregroundStyle(colors.neonPurple)
                                    .font(.title2)
                                Text("Medical Report Scanner")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            
                            Text("Scan your lab reports to get instant insights. Supports blood work, lipid panels, thyroid tests, and more.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                    
                    // Scan Actions
                    HStack(spacing: 16) {
                        // Camera
                        Button {
                            showCamera = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                Text("Camera")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(colors.neonPurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        
                        // Photo Library
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title)
                                Text("Gallery")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(colors.neonBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    // Loading State
                    if viewModel.isProcessing {
                        GlassCard {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Scanning report...")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                    
                    // Scanned Reports
                    if !viewModel.reports.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scanned Reports")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            
                            ForEach(viewModel.reports) { report in
                                ReportCard(report: report)
                            }
                        }
                    }
                    
                    // Empty State
                    if viewModel.reports.isEmpty && !viewModel.isProcessing {
                        GlassCard {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(colors.textSecondary)
                                Text("No reports scanned yet")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                                Text("Take a photo or select from gallery")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Scan Report")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.processImage(image)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.processImage(image)
                }
            }
        }
        .sheet(isPresented: $showResults) {
            if let report = viewModel.reports.first {
                ReportDetailView(report: report)
            }
        }
        .onChange(of: viewModel.reports.count) { _, _ in
            if !viewModel.reports.isEmpty {
                showResults = true
            }
        }
    }
}

// MARK: - Report Card

struct ReportCard: View {
    @Environment(\.theme) var colors
    let report: LabReport
    
    var body: some View {
        NavigationLink(destination: ReportDetailView(report: report)) {
            GlassCard(material: .regularMaterial) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: report.abnormalTests.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(report.abnormalTests.isEmpty ? colors.neonGreen : colors.neonOrange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lab Report")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                            Text(report.date, style: .date)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("\(report.tests.count) tests")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                    }
                    
                    Text(report.summary)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(report.abnormalTests.isEmpty ? colors.neonGreen : colors.neonOrange)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Report Detail View

struct ReportDetailView: View {
    @Environment(\.theme) var colors
    let report: LabReport
    @State private var showAIInsights = false
    
    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Card
                    GlassCard(material: .regularMaterial) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(colors.neonPurple)
                                Text("Report Summary")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Spacer()
                                Text(report.date, style: .date)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                            }
                            
                            if !report.abnormalTests.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(colors.neonOrange)
                                    Text("\(report.abnormalTests.count) values outside normal range")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(colors.neonOrange)
                                }
                            }
                        }
                    }
                    
                    // Abnormal Tests (highlighted)
                    if !report.abnormalTests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Needs Attention")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(colors.neonOrange)
                            
                            ForEach(report.abnormalTests) { test in
                                TestResultRow(test: test, highlighted: true)
                            }
                        }
                    }
                    
                    // All Tests
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Results")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                        
                        ForEach(report.tests) { test in
                            TestResultRow(test: test, highlighted: false)
                        }
                    }
                    
                    // AI Insights Button
                    Button {
                        showAIInsights = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Get AI Insights")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colors.neonPurple.gradient, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAIInsights) {
            MedicalReportAIView(report: report)
        }
    }
}

// MARK: - Test Result Row

struct TestResultRow: View {
    @Environment(\.theme) var colors
    let test: LabTest
    let highlighted: Bool
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(test.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                    
                    if let range = test.normalRange {
                        Text("Normal: \(String(format: "%.1f", range.lowerBound))-\(String(format: "%.1f", range.upperBound)) \(test.unit)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", test.value)) \(test.unit)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(test.status.rawValue)
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(testStatusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(testStatusColor.opacity(0.15), in: Capsule())
                }
            }
        }
    }
    
    var testStatusColor: Color {
        switch test.status {
        case .normal: return colors.neonGreen
        case .high: return colors.neonRed
        case .low: return colors.neonOrange
        case .borderline: return colors.neonYellow
        }
    }
}

// MARK: - Medical Report AI View

struct MedicalReportAIView: View {
    @Environment(\.theme) var colors
    let report: LabReport
    @StateObject private var viewModel = MedicalReportAIViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            GlassCard {
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Analyzing your report...")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        } else if let analysis = viewModel.analysis {
                            GlassCard(material: .regularMaterial) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("AI Analysis")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                    
                                    Text(analysis)
                                        .font(.system(.body, design: .rounded))
                                }
                            }
                            
                            // Disclaimer
                            GlassCard(padding: 12) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(colors.textSecondary)
                                    Text("This analysis is for educational purposes only. Always consult your doctor for medical advice.")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // dismiss
                    }
                }
            }
        }
        .onAppear {
            viewModel.analyze(report: report)
        }
    }
}

// MARK: - View Model

@MainActor
class MedicalReportViewModel: ObservableObject {
    @Published var reports: [LabReport] = []
    @Published var isProcessing = false
    @Published var error: String?
    
    func processImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let text = try await MedicalReportOCR.shared.extractText(from: image)
                let report = MedicalReportOCR.shared.parseLabReport(from: text)
                reports.insert(report, at: 0)
            } catch {
                self.error = error.localizedDescription
            }
            isProcessing = false
        }
    }
}

@MainActor
class MedicalReportAIViewModel: ObservableObject {
    @Published var analysis: String?
    @Published var isLoading = false
    
    private let orchestrator = AIOrchestrator()
    
    func analyze(report: LabReport) {
        isLoading = true
        
        Task {
            do {
                let testSummary = report.tests.map { test in
                    var line = "\(test.name): \(String(format: "%.1f", test.value)) \(test.unit)"
                    if let range = test.normalRange {
                        line += " (Normal: \(String(format: "%.1f", range.lowerBound))-\(String(format: "%.1f", range.upperBound)))"
                    }
                    if test.status != .normal {
                        line += " [\(test.status.rawValue.uppercased())]"
                    }
                    return line
                }.joined(separator: "\n")
                
                let prompt = """
                You are a friendly health advisor explaining lab results to an Indian patient in simple terms.
                
                Here are the lab test results:
                \(testSummary)
                
                Please provide:
                1. A simple explanation of what each abnormal value means
                2. Possible causes (in general terms, not diagnosis)
                3. Lifestyle and dietary suggestions relevant to Indian culture
                4. When they should see a doctor
                
                Keep it simple, reassuring, and actionable. Use Indian food references where relevant.
                DO NOT diagnose or prescribe medication.
                """
                
                let request = AIRequest(
                    task: .medicalDocQA,
                    userPrompt: prompt,
                    systemPrompt: "You are an Indian health educator. Explain lab results in simple language. Never diagnose or prescribe.",
                    generationConfig: GenerationPreset.medicalDocQA.config
                )
                
                let response = try await orchestrator.generate(request)
                analysis = response.text
            } catch {
                analysis = "Could not generate analysis. Please try again."
            }
            isLoading = false
        }
    }
}
