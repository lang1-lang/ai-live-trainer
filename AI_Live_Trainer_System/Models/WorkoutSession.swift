//
//  WorkoutSession.swift
//  AI Live Trainer System
//
//  Phase 5: Enhanced with biometric data storage
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
    
    // Phase 5: Advanced biometric data
    var biometricData: [BiometricResultData]?
    var deviceMode: String?  // "pro" or "standard"
    var averageMetrics: [String: Float]?  // Average metrics across session
    
    init(
        workoutId: String,
        workoutName: String,
        date: Date = Date(),
        duration: TimeInterval = 0,
        accuracyPercentage: Double = 0,
        totalReps: Int = 0,
        completedSets: Int = 0,
        feedbackItems: [FeedbackItem] = [],
        biometricData: [BiometricResultData]? = nil,
        deviceMode: String? = nil,
        averageMetrics: [String: Float]? = nil
    ) {
        self.id = UUID()
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.date = date
        self.duration = duration
        self.accuracyPercentage = accuracyPercentage
        self.totalReps = totalReps
        self.completedSets = completedSets
        self.feedbackItems = feedbackItems
        self.biometricData = biometricData
        self.deviceMode = deviceMode
        self.averageMetrics = averageMetrics
    }
}

// Phase 5: Codable wrapper for BiometricResult (for SwiftData storage)
struct BiometricResultData: Codable {
    let isCorrect: Bool
    let primaryFeedback: String
    let confidence: Float
    let metricMeasurements: [String: Float]
    let jointAngles: [String: Float]
    let deviationMetrics: [String: Float]
    let timestamp: TimeInterval
    
    init(from result: BiometricResult) {
        self.isCorrect = result.isCorrect
        self.primaryFeedback = result.primaryFeedback
        self.confidence = result.confidence
        self.metricMeasurements = result.metricMeasurements
        self.jointAngles = result.jointAngles
        self.deviationMetrics = result.deviationMetrics
        self.timestamp = result.timestamp
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

