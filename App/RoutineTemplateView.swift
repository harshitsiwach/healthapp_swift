import SwiftUI
import SwiftData

struct RoutineTemplateView: View {
    @Environment(\.modelContext) private var context
    let routine: RoutineTemplate
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                    
                    Text(routine.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("by \(routine.authorName)")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    
                    Text(routine.descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack {
                        Label("\(routine.copyCount) uses", systemImage: "person.2.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top)
                
                // Details Grid
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Routine details")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            RoutineDetailTile(title: "Wake Target", value: routine.wakeTime, icon: "sun.haze.fill", color: .orange)
                            RoutineDetailTile(title: "Sleep Target", value: routine.sleepTime, icon: "moon.stars.fill", color: .indigo)
                            RoutineDetailTile(title: "Hydration", value: String(format: "%.1fL", routine.hydrationGoalLiters), icon: "drop.fill", color: .cyan)
                            RoutineDetailTile(title: "Steps", value: "\(routine.stepGoal)", icon: "figure.walk", color: .green)
                            RoutineDetailTile(title: "Meals/Day", value: "\(routine.mealCadence)", icon: "fork.knife", color: .red)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Action
                Button(action: {
                    withAnimation {
                        RoutineTemplateService.shared.copyRoutine(routine, context: context)
                    }
                }) {
                    Text(routine.isUserActiveRoutine ? "Routine Active" : "Adopt This Routine")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(routine.isUserActiveRoutine ? Color(uiColor: .tertiarySystemFill) : Color.accentColor)
                        .foregroundStyle(routine.isUserActiveRoutine ? Color.primary : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(routine.isUserActiveRoutine)
                .padding()
            }
        }
        .background(GradientBackground())
        .navigationTitle("Template Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RoutineDetailTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.body.bold())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
    }
}
