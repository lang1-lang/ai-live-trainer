//
//  WorkoutSession.swift
//  AI Live Trainer System
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var workoutId: String
    var workoutName: String
    var date: Date
    var duration: TimeInterval
    var accuracyPercentage: Double
    var totalReps: Int
    var completedSets: Int
    var feedbackItems: [FeedbackItem]
    
    init(workoutId: String, workoutName: String, date: Date = Date(), duration: TimeInterval = 0, accuracyPercentage: Double = 0, totalReps: Int = 0, completedSets: Int = 0, feedbackItems: [FeedbackItem] = []) {
        self.id = UUID()
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.date = date
        self.duration = duration
        self.accuracyPercentage = accuracyPercentage
        self.totalReps = totalReps
        self.completedSets = completedSets
        self.feedbackItems = feedbackItems
    }
}

struct FeedbackItem: Codable, Identifiable {
    var id: UUID = UUID()
    var exerciseName: String
    var message: String
    var timestamp: Date
    var severity: FeedbackSeverity
    
    enum FeedbackSeverity: String, Codable {
        case good = "good"
        case warning = "warning"
        case error = "error"
    }
}

