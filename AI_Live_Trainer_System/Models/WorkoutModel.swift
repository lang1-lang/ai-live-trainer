//
//  WorkoutModel.swift
//  AI Live Trainer System
//

import Foundation
import SwiftData

@Model
final class WorkoutModel {
    var id: String
    var displayName: String
    var difficultyRating: Int
    var setCount: Int
    var workoutDescription: String
    var coverAsset: String
    var tags: [String]
    var exercises: [Exercise]
    
    init(id: String, displayName: String, difficultyRating: Int, setCount: Int, workoutDescription: String, coverAsset: String, tags: [String], exercises: [Exercise] = []) {
        self.id = id
        self.displayName = displayName
        self.difficultyRating = difficultyRating
        self.setCount = setCount
        self.workoutDescription = workoutDescription
        self.coverAsset = coverAsset
        self.tags = tags
        self.exercises = exercises
    }
    
    static func sampleWorkouts() -> [WorkoutModel] {
        return [
            WorkoutModel(
                id: "wk_001",
                displayName: "The Morning Mobilizer",
                difficultyRating: 1,
                setCount: 3,
                workoutDescription: "Low-impact flow to wake up spine and hips.",
                coverAsset: "img_morning_flow_hero",
                tags: ["mobility", "recovery", "beginner"],
                exercises: [
                    Exercise(name: "Cat-Cow Stretch", reps: 10, duration: 30),
                    Exercise(name: "Hip Circles", reps: 8, duration: 40),
                    Exercise(name: "Spinal Twist", reps: 6, duration: 30)
                ]
            ),
            WorkoutModel(
                id: "wk_002",
                displayName: "Iron Core Pillar",
                difficultyRating: 3,
                setCount: 4,
                workoutDescription: "Stability routine for obliques and lower abs.",
                coverAsset: "img_core_pillar_hero",
                tags: ["strength", "core", "intermediate"],
                exercises: [
                    Exercise(name: "Plank", reps: 1, duration: 60),
                    Exercise(name: "Russian Twist", reps: 20, duration: 45),
                    Exercise(name: "Bicycle Crunches", reps: 15, duration: 40)
                ]
            ),
            WorkoutModel(
                id: "wk_003",
                displayName: "High-Octane HIIT",
                difficultyRating: 5,
                setCount: 5,
                workoutDescription: "Explosive movements for agility and heart rate.",
                coverAsset: "img_hiit_hero",
                tags: ["cardio", "advanced", "power"],
                exercises: [
                    Exercise(name: "Burpees", reps: 15, duration: 45),
                    Exercise(name: "Jump Squats", reps: 20, duration: 40),
                    Exercise(name: "Mountain Climbers", reps: 30, duration: 50)
                ]
            )
        ]
    }
}

struct Exercise: Codable {
    var name: String
    var reps: Int
    var duration: Int // in seconds
    
    init(name: String, reps: Int, duration: Int) {
        self.name = name
        self.reps = reps
        self.duration = duration
    }
}

