//
//  AIInsightsView.swift
//  AI Live Trainer System
//

import SwiftUI
import SwiftData

struct AIInsightsView: View {
    @Query private var sessions: [WorkoutSession]
    
    private var insights: [InsightItem] {
        generateInsights(from: sessions)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        EmptyInsightsView()
                    } else {
                        // AI Insights Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                Text("AI Analysis")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Text("Personalized recommendations based on your performance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .padding(.horizontal)
                        
                        // Insights List
                        VStack(spacing: 16) {
                            ForEach(insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func generateInsights(from sessions: [WorkoutSession]) -> [InsightItem] {
        var insights: [InsightItem] = []
        
        if sessions.isEmpty {
            return insights
        }
        
        // Average accuracy insight
        let avgAccuracy = sessions.reduce(0) { $0 + $1.accuracyPercentage } / Double(sessions.count)
        if avgAccuracy >= 85 {
            insights.append(InsightItem(
                icon: "star.fill",
                title: "Excellent Form",
                description: "Your average form accuracy is \(String(format: "%.0f%%", avgAccuracy)). Keep up the great work!",
                type: .positive
            ))
        } else if avgAccuracy < 70 {
            insights.append(InsightItem(
                icon: "exclamationmark.triangle.fill",
                title: "Form Improvement Needed",
                description: "Focus on maintaining proper form. Consider starting with lower difficulty workouts.",
                type: .warning
            ))
        }
        
        // Consistency insight
        let recentSessions = sessions.prefix(7)
        if recentSessions.count >= 5 {
            insights.append(InsightItem(
                icon: "flame.fill",
                title: "On Fire!",
                description: "You've completed \(recentSessions.count) workouts this week. Consistency is key!",
                type: .positive
            ))
        }
        
        // Common error pattern
        let allFeedback = sessions.flatMap { $0.feedbackItems }
        let errorFeedback = allFeedback.filter { $0.severity == .error }
        if !errorFeedback.isEmpty {
            insights.append(InsightItem(
                icon: "lightbulb.fill",
                title: "Focus Area",
                description: "Pay extra attention to form during core exercises. This is your most common correction area.",
                type: .tip
            ))
        }
        
        // Progress insight
        if sessions.count >= 10 {
            let firstFive = sessions.suffix(10).prefix(5)
            let lastFive = sessions.prefix(5)
            
            let firstAvg = firstFive.reduce(0) { $0 + $1.accuracyPercentage } / Double(firstFive.count)
            let lastAvg = lastFive.reduce(0) { $0 + $1.accuracyPercentage } / Double(lastFive.count)
            
            if lastAvg > firstAvg + 5 {
                insights.append(InsightItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Great Progress",
                    description: "Your form has improved by \(String(format: "%.0f%%", lastAvg - firstAvg)) over your last 10 workouts!",
                    type: .positive
                ))
            }
        }
        
        return insights
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .padding(.top, 100)
            
            Text("No Insights Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete a few workouts and our AI will analyze your performance to provide personalized recommendations.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let type: InsightType
    
    enum InsightType {
        case positive
        case warning
        case tip
        
        var color: Color {
            switch self {
            case .positive:
                return .green
            case .warning:
                return .orange
            case .tip:
                return .blue
            }
        }
    }
}

struct InsightCard: View {
    let insight: InsightItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: insight.icon)
                    .font(.title3)
                    .foregroundColor(insight.type.color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    AIInsightsView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}

