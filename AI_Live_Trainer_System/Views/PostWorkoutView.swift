//
//  PostWorkoutView.swift
//  AI Live Trainer System
//

import SwiftUI
import Charts

struct PostWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(session.workoutName)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Accuracy Radial Chart
                    VStack(spacing: 12) {
                        Text("Form Accuracy")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .trim(from: 0, to: session.accuracyPercentage / 100)
                                .stroke(
                                    LinearGradient(
                                        colors: gradientForAccuracy(session.accuracyPercentage),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: session.accuracyPercentage)
                            
                            VStack(spacing: 4) {
                                Text(String(format: "%.0f%%", session.accuracyPercentage))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("ACCURACY")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "clock.fill",
                            value: formatDuration(session.duration),
                            label: "Duration"
                        )
                        
                        StatCard(
                            icon: "repeat",
                            value: "\(session.totalReps)",
                            label: "Total Reps"
                        )
                        
                        StatCard(
                            icon: "square.stack.3d.up.fill",
                            value: "\(session.completedSets)",
                            label: "Sets Completed"
                        )
                        
                        StatCard(
                            icon: "flame.fill",
                            value: "\(Int(session.duration / 60 * 8))",
                            label: "Calories"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Feedback Items
                    if !session.feedbackItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Feedback")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(session.feedbackItems) { item in
                                    FeedbackItemRow(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Results")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func gradientForAccuracy(_ accuracy: Double) -> [Color] {
        if accuracy >= 80 {
            return [.green, .green.opacity(0.7)]
        } else if accuracy >= 60 {
            return [.orange, .orange.opacity(0.7)]
        } else {
            return [.red, .red.opacity(0.7)]
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct FeedbackItemRow: View {
    let item: FeedbackItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForSeverity(item.severity))
                .font(.title3)
                .foregroundColor(colorForSeverity(item.severity))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.exerciseName)
                    .font(.headline)
                
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func iconForSeverity(_ severity: FeedbackItem.FeedbackSeverity) -> String {
        switch severity {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: FeedbackItem.FeedbackSeverity) -> Color {
        switch severity {
        case .good:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

#Preview {
    PostWorkoutView(session: WorkoutSession(
        workoutId: "wk_001",
        workoutName: "The Morning Mobilizer",
        duration: 900,
        accuracyPercentage: 87.5,
        totalReps: 45,
        completedSets: 3,
        feedbackItems: [
            FeedbackItem(exerciseName: "Squat", message: "Great depth! Keep it up.", timestamp: Date(), severity: .good),
            FeedbackItem(exerciseName: "Plank", message: "Lower your hips slightly", timestamp: Date(), severity: .warning)
        ]
    ))
}

