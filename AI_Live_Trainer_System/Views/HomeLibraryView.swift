//
//  HomeLibraryView.swift
//  AI Live Trainer System
//

import SwiftUI
import SwiftData

struct HomeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userStats: [UserStats]
    @State private var workouts: [WorkoutModel] = []
    @State private var selectedWorkout: WorkoutModel?
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with user stats
                    HeaderView(stats: userStats.first ?? UserStats())
                        .padding(.horizontal)
                    
                    // Workout Cards
                    VStack(spacing: 16) {
                        ForEach(workouts, id: \.id) { workout in
                            WorkoutCardView(workout: workout)
                                .onTapGesture {
                                    selectedWorkout = workout
                                    showingWorkoutDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("My Workouts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWorkoutDetail) {
                if let workout = selectedWorkout {
                    WorkoutPreRollView(workout: workout)
                }
            }
        }
        .onAppear {
            initializeData()
        }
    }
    
    private func initializeData() {
        if workouts.isEmpty {
            workouts = WorkoutModel.sampleWorkouts()
        }
        
        if userStats.isEmpty {
            let newStats = UserStats()
            modelContext.insert(newStats)
        }
    }
}

struct HeaderView: View {
    let stats: UserStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome Back!")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                StatBadge(icon: "flame.fill", value: "\(stats.currentStreak)", label: "Day Streak")
                StatBadge(icon: "figure.strengthtraining.traditional", value: "\(stats.totalWorkouts)", label: "Workouts")
                StatBadge(icon: "target", value: String(format: "%.0f%%", stats.averageAccuracy), label: "Accuracy")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeLibraryView()
        .modelContainer(for: [WorkoutModel.self, UserStats.self], inMemory: true)
}

