//
//  WorkoutPreRollView.swift
//  AI Live Trainer System
//

import SwiftUI
import AVKit

struct WorkoutPreRollView: View {
    let workout: WorkoutModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLiveSession = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Demo Video Preview
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 300)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Perfect Form Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Workout Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(workout.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(workout.workoutDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Stats Row
                        HStack(spacing: 20) {
                            InfoPill(icon: "repeat", text: "\(workout.setCount) Sets")
                            InfoPill(icon: "flame.fill", text: "Difficulty \(workout.difficultyRating)")
                            InfoPill(icon: "clock", text: "~\(workout.setCount * 5) min")
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Exercise List
                        Text("Exercises")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                                ExerciseRow(number: index + 1, exercise: exercise)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start Button
                    Button(action: {
                        showingLiveSession = true
                    }) {
                        HStack {
                            Image(systemName: "figure.run")
                                .font(.title3)
                            Text("Start Workout")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingLiveSession) {
                LiveSessionView(workout: workout)
            }
        }
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(20)
    }
}

struct ExerciseRow: View {
    let number: Int
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Label("\(exercise.reps) reps", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(exercise.duration)s", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutPreRollView(workout: WorkoutModel.sampleWorkouts()[1])
}

