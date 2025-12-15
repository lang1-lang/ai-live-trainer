//
//  WorkoutCardView.swift
//  AI Live Trainer System
//

import SwiftUI

struct WorkoutCardView: View {
    let workout: WorkoutModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors(for: workout.difficultyRating),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                
                // Difficulty Badge
                DifficultyBadge(rating: workout.difficultyRating)
                    .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(workout.workoutDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(workout.setCount) Sets", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Tags
                    HStack(spacing: 4) {
                        ForEach(workout.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func gradientColors(for difficulty: Int) -> [Color] {
        switch difficulty {
        case 1...2:
            return [Color.green.opacity(0.7), Color.blue.opacity(0.7)]
        case 3...4:
            return [Color.orange.opacity(0.7), Color.pink.opacity(0.7)]
        default:
            return [Color.red.opacity(0.7), Color.purple.opacity(0.7)]
        }
    }
}

struct DifficultyBadge: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "flame.fill" : "flame")
                    .font(.caption2)
                    .foregroundColor(index <= rating ? .orange : .white.opacity(0.5))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    WorkoutCardView(workout: WorkoutModel.sampleWorkouts()[0])
        .padding()
}

