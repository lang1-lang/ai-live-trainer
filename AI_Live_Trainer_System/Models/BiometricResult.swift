//
//  BiometricResult.swift
//  AXIS LABS - Biometric Analysis Engine
//
//  Purpose: Rich biomechanics result structure with metric measurements
//  Replaces: FormAnalysisResult (legacy 2D heuristic result)
//
//  Phase 3 Implementation: Vector Physics Engine Data Model
//

import Foundation

/// Comprehensive biomechanics analysis result with metric precision
struct BiometricResult {
    
    // MARK: - Core Analysis
    
    /// Overall form correctness flag
    let isCorrect: Bool
    
    /// Primary feedback message for user
    let primaryFeedback: String
    
    /// Confidence score (0.0 - 1.0)
    let confidence: Float
    
    // MARK: - Metric Measurements (Phase 3)
    
    /// Absolute measurements in meters
    /// Examples: "squat_depth_meters": 0.45, "hip_to_ankle_distance": 0.92
    let metricMeasurements: [String: Float]
    
    /// Joint angles in degrees
    /// Examples: "knee_angle_deg": 87.3, "hip_angle_deg": 95.1
    let jointAngles: [String: Float]
    
    /// Deviation metrics in meters
    /// Examples: "knee_valgus_meters": 0.02 (positive = inward), "bar_path_deviation": 0.03
    let deviationMetrics: [String: Float]
    
    /// Velocity measurements in meters/second (Phase 3+)
    /// Examples: "hip_velocity_vertical": -0.45, "wrist_velocity_magnitude": 1.2
    var velocityMetrics: [String: Float]?
    
    // MARK: - Temporal Data
    
    /// Timestamp of measurement (seconds since session start)
    let timestamp: TimeInterval
    
    /// Frame number in session
    var frameNumber: Int?
    
    // MARK: - Initialization
    
    init(
        isCorrect: Bool,
        primaryFeedback: String,
        confidence: Float,
        metricMeasurements: [String: Float] = [:],
        jointAngles: [String: Float] = [:],
        deviationMetrics: [String: Float] = [:],
        velocityMetrics: [String: Float]? = nil,
        timestamp: TimeInterval,
        frameNumber: Int? = nil
    ) {
        self.isCorrect = isCorrect
        self.primaryFeedback = primaryFeedback
        self.confidence = confidence
        self.metricMeasurements = metricMeasurements
        self.jointAngles = jointAngles
        self.deviationMetrics = deviationMetrics
        self.velocityMetrics = velocityMetrics
        self.timestamp = timestamp
        self.frameNumber = frameNumber
    }
    
    // MARK: - Legacy Compatibility
    
    /// Creates BiometricResult from legacy FormAnalysisResult
    /// - Parameter legacy: FormAnalysisResult from old AITrainerEngine
    /// - Returns: BiometricResult with minimal metrics
    static func fromLegacy(_ legacy: FormAnalysisResult, timestamp: TimeInterval) -> BiometricResult {
        return BiometricResult(
            isCorrect: legacy.isCorrect,
            primaryFeedback: legacy.feedback,
            confidence: legacy.confidence,
            timestamp: timestamp
        )
    }
}

// MARK: - Codable Conformance

extension BiometricResult: Codable {
    // Automatic conformance for data persistence and export
}

// MARK: - Debugging

extension BiometricResult: CustomStringConvertible {
    var description: String {
        var desc = "BiometricResult @ \(String(format: "%.2f", timestamp))s\n"
        desc += "  Correct: \(isCorrect ? "✅" : "❌") (confidence: \(confidence))\n"
        desc += "  Feedback: \(primaryFeedback)\n"
        
        if !jointAngles.isEmpty {
            desc += "  Angles: \(jointAngles.map { "\($0.key)=\(String(format: "%.1f", $0.value))°" }.joined(separator: ", "))\n"
        }
        
        if !metricMeasurements.isEmpty {
            desc += "  Metrics: \(metricMeasurements.map { "\($0.key)=\(String(format: "%.3f", $0.value))m" }.joined(separator: ", "))\n"
        }
        
        if !deviationMetrics.isEmpty {
            desc += "  Deviations: \(deviationMetrics.map { "\($0.key)=\(String(format: "%.3f", $0.value))m" }.joined(separator: ", "))\n"
        }
        
        return desc
    }
}

