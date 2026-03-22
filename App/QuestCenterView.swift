import SwiftUI
import SwiftData

struct QuestCenterView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<DailyQuest> { !$0.isCompleted }) private var activeQuests: [DailyQuest]
    @Query(filter: #Predicate<DailyQuest> { $0.isCompleted }) private var completedQuests: [DailyQuest]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Quests")
                                .font(.title.bold())
                            Text("Complete these tasks to earn XP and level up your wellness rank.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Active Quests
                    if !activeQuests.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Active")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(activeQuests) { quest in
                                QuestRow(quest: quest)
                            }
                        }
                    }
                    
                    // Completed Quests
                    if !completedQuests.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Completed Today")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(completedQuests) { quest in
                                QuestRow(quest: quest)
                                    .opacity(0.6)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(GradientBackground())
            .navigationTitle("Quests")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                QuestService.shared.generateDailyQuests(context: context)
            }
        }
    }
}

struct QuestRow: View {
    let quest: DailyQuest
    
    var body: some View {
        GlassCard {
            HStack(spacing: 15) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    if quest.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                            .font(.system(size: 16, weight: .bold))
                            .transition(.scale)
                    } else {
                        Circle()
                            .trim(from: 0, to: CGFloat(quest.currentValue) / CGFloat(max(1, quest.targetValue)))
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: quest.currentValue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                        .strikethrough(quest.isCompleted)
                    Text(quest.descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("+\(quest.xpReward)")
                        .font(.caption.bold())
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

#Preview {
    QuestCenterView()
        .modelContainer(for: DailyQuest.self, inMemory: true)
}
