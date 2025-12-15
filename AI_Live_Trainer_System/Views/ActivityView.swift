//
//  ActivityView.swift
//  AI Live Trainer System
//

import SwiftUI
import SwiftData

struct ActivityView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        EmptyActivityView()
                    } else {
                        // Weekly Summary
                        WeeklySummaryCard(sessions: sessions)
                            .padding(.horizontal)
                        
                        // Recent Workouts
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Workouts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(sessions.prefix(10)) { session in
                                SessionHistoryRow(session: session)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .padding(.top, 100)
            
            Text("No Activity Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete your first workout to see your progress here!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct WeeklySummaryCard: View {
    let sessions: [WorkoutSession]
    
    private var weeklyStats: (workouts: Int, duration: TimeInterval, avgAccuracy: Double) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentSessions = sessions.filter { $0.date >= oneWeekAgo }
        
        let totalDuration = recentSessions.reduce(0) { $0 + $1.duration }
        let avgAccuracy = recentSessions.isEmpty ? 0 : recentSessions.reduce(0) { $0 + $1.accuracyPercentage } / Double(recentSessions.count)
        
        return (recentSessions.count, totalDuration, avgAccuracy)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                WeeklyStatPill(
                    value: "\(weeklyStats.workouts)",
                    label: "Workouts",
                    icon: "flame.fill"
                )
                
                WeeklyStatPill(
                    value: String(format: "%.0f%%", weeklyStats.avgAccuracy),
                    label: "Avg Form",
                    icon: "target"
                )
                
                WeeklyStatPill(
                    value: "\(Int(weeklyStats.duration / 60))m",
                    label: "Total Time",
                    icon: "clock.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct WeeklyStatPill: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionHistoryRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", session.accuracyPercentage))
                    .font(.headline)
                    .foregroundColor(accuracyColor(session.accuracyPercentage))
                
                Text("\(Int(session.duration / 60))m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 80 {
            return .green
        } else if accuracy >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}

