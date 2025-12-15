//
//  UserStats.swift
//  AI Live Trainer System
//

import Foundation
import SwiftData

@Model
final class UserStats {
    var id: UUID
    var totalWorkouts: Int
    var totalDuration: TimeInterval
    var currentStreak: Int
    var lastWorkoutDate: Date?
    var averageAccuracy: Double
    
    init(totalWorkouts: Int = 0, totalDuration: TimeInterval = 0, currentStreak: Int = 0, lastWorkoutDate: Date? = nil, averageAccuracy: Double = 0) {
        self.id = UUID()
        self.totalWorkouts = totalWorkouts
        self.totalDuration = totalDuration
        self.currentStreak = currentStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.averageAccuracy = averageAccuracy
    }
}

