//
//  BiomechanicsEngine.swift
//  AXIS LABS - Biometric Analysis Engine
//
//  Purpose: Deterministic vector physics analysis engine
//  Replaces: AITrainerEngine (legacy 2D heuristic analysis)
//  Reference: https://wiki.has-motion.com/doku.php?id=visual3d:tutorials:kinematics_and_kinetics:model_based_computations
//
//  Phase 3 Implementation: SIMD-Accelerated Rigid Body Dynamics
//

import Foundation
import simd
import Vision

/// Military-grade biomechanics engine using deterministic vector physics
class BiomechanicsEngine {
    
    // MARK: - Constants
    
    /// Minimum confidence threshold for joint analysis
    private let minConfidence: Float = 0.5
    
    /// Angular tolerance for "good form" (degrees)
    private let angleTolerance: Float = 10.0
    
    // MARK: - Core Vector Operations
    
    /// Calculates angle between three 3D points using dot product
    /// Reference: https://math.stackexchange.com/questions/3684094/angles-between-vectors-in-3d
    /// - Parameters:
    ///   - center: Vertex point (e.g., knee in hip-knee-ankle)
    ///   - p1: First endpoint (e.g., hip)
    ///   - p2: Second endpoint (e.g., ankle)
    /// - Returns: Angle in degrees
    static func calculateJointAngle(
        center: simd_float3,
        p1: simd_float3,
        p2: simd_float3
    ) -> Float {
        // TODO Phase 3: Implement SIMD angle calculation
        // Algorithm from research document:
        // 1. Create vectors from center to each endpoint
        // 2. Normalize vectors
        // 3. Calculate dot product
        // 4. Apply inverse cosine to get angle
        
        let v1 = simd_normalize(p1 - center)
        let v2 = simd_normalize(p2 - center)
        let dot = simd_dot(v1, v2)
        let clamped = simd_clamp(dot, -1.0, 1.0)
        return acos(clamped) * (180.0 / Float.pi)
    }
    
    /// Calculates knee valgus deviation (inward collapse)
    /// Reference: https://pmc.ncbi.nlm.nih.gov/articles/PMC11399566/
    /// - Parameters:
    ///   - hip: Hip joint position
    ///   - knee: Knee joint position
    ///   - ankle: Ankle joint position
    ///   - isLeftLeg: True if analyzing left leg
    /// - Returns: Deviation in meters (positive = valgus/inward, negative = varus/outward)
    static func calculateValgusDeviation(
        hip: simd_float3,
        knee: simd_float3,
        ankle: simd_float3,
        isLeftLeg: Bool
    ) -> Float {
        // 1. Define mechanical axis (hip to ankle vector)
        let legAxis = ankle - hip
        let legLengthSquared = simd_length_squared(legAxis)
        
        // Safety check: avoid division by zero
        guard legLengthSquared > 0.001 else { return 0.0 }
        
        // 2. Calculate vector from hip to knee
        let hipToKnee = knee - hip
        
        // 3. Project knee onto mechanical axis
        // Projection formula: proj = (a·b / |b|²) * b
        let t = simd_dot(hipToKnee, legAxis) / legLengthSquared
        let projectedPoint = hip + (legAxis * t)
        
        // 4. Calculate perpendicular deviation vector
        let deviation = knee - projectedPoint
        let magnitude = simd_length(deviation)
        
        // 5. Determine sign (medial = positive/valgus, lateral = negative/varus)
        // In anatomical space: X is lateral direction
        // For left leg: inward is +X (toward body midline)
        // For right leg: inward is -X (toward body midline)
        let inwardDirection: Float = isLeftLeg ? 1.0 : -1.0
        let xComponent = deviation.x
        
        // Sign indicates direction: positive = valgus (inward), negative = varus (outward)
        return magnitude * (xComponent * inwardDirection > 0 ? 1.0 : -1.0)
    }
    
    /// Calculates velocity vector from position history
    /// - Parameters:
    ///   - positions: Array of 3D positions over time
    ///   - timestamps: Corresponding timestamps (seconds)
    /// - Returns: Velocity vector in meters/second
    static func calculateVelocity(
        positions: [simd_float3],
        timestamps: [TimeInterval]
    ) -> simd_float3 {
        // TODO Phase 3: Implement velocity calculation (first derivative)
        guard positions.count >= 2, timestamps.count >= 2 else {
            return simd_float3(0, 0, 0)
        }
        
        // Simple finite difference: v = Δposition / Δtime
        let deltaPos = positions.last! - positions[positions.count - 2]
        let deltaTime = Float(timestamps.last! - timestamps[timestamps.count - 2])
        
        guard deltaTime > 0 else { return simd_float3(0, 0, 0) }
        
        return deltaPos / deltaTime
    }
    
    // MARK: - Exercise Analyzers (Phase 3)
    
    /// Analyzes squat form using 3D metric coordinates
    /// - Parameter joints: Dictionary of joint positions in metric space
    /// - Returns: BiometricResult with comprehensive metrics
    func analyzeSquat3D(
        joints: [VNHumanBodyPoseObservation.JointName: simd_float3],
        timestamp: TimeInterval = 0.0
    ) -> BiometricResult {
        // Extract required joints
        guard let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip],
              let leftKnee = joints[.leftKnee],
              let rightKnee = joints[.rightKnee],
              let leftAnkle = joints[.leftAnkle],
              let rightAnkle = joints[.rightAnkle] else {
            return BiometricResult(
                isCorrect: true,
                primaryFeedback: "Position yourself fully in frame",
                confidence: 0.3,
                timestamp: timestamp
            )
        }
        
        // Calculate average positions for bilateral analysis
        let avgHip = (leftHip + rightHip) / 2.0
        let avgKnee = (leftKnee + rightKnee) / 2.0
        let avgAnkle = (leftAnkle + rightAnkle) / 2.0
        
        var metricMeasurements: [String: Float] = [:]
        var jointAngles: [String: Float] = [:]
        var deviationMetrics: [String: Float] = [:]
        var isCorrect = true
        var feedback = "Perfect squat form!"
        var confidence: Float = 0.85
        
        // 1. Squat Depth Analysis (hip vs knee height)
        let hipDepth = avgHip.y - avgKnee.y
        metricMeasurements["hip_depth_meters"] = hipDepth
        
        // Target: Hip should be at or below knee level (positive depth)
        if hipDepth < -0.05 {  // Hip is 5cm+ above knee
            isCorrect = false
            feedback = "Go deeper! Lower your hips below knee level."
            confidence = 0.75
        }
        
        // 2. Knee Angle Calculation (hip-knee-ankle)
        let leftKneeAngle = Self.calculateJointAngle(
            center: leftKnee,
            p1: leftHip,
            p2: leftAnkle
        )
        let rightKneeAngle = Self.calculateJointAngle(
            center: rightKnee,
            p1: rightHip,
            p2: rightAnkle
        )
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0 as Float
        
        jointAngles["knee_angle_deg"] = avgKneeAngle
        jointAngles["left_knee_angle_deg"] = leftKneeAngle
        jointAngles["right_knee_angle_deg"] = rightKneeAngle
        
        // Target: 80-100 degrees for proper squat depth
        if avgKneeAngle > 110 && isCorrect {
            isCorrect = false
            feedback = "Squat deeper! Aim for 90-degree knee bend."
            confidence = 0.70
        }
        
        // 3. Knee Valgus Analysis (inward collapse)
        let leftValgus = Self.calculateValgusDeviation(
            hip: leftHip,
            knee: leftKnee,
            ankle: leftAnkle,
            isLeftLeg: true
        )
        let rightValgus = Self.calculateValgusDeviation(
            hip: rightHip,
            knee: rightKnee,
            ankle: rightAnkle,
            isLeftLeg: false
        )
        
        deviationMetrics["left_knee_valgus_meters"] = leftValgus
        deviationMetrics["right_knee_valgus_meters"] = rightValgus
        
        // Threshold: > 2cm valgus is problematic
        let maxValgus = max(abs(leftValgus), abs(rightValgus))
        if maxValgus > 0.02 && isCorrect {
            isCorrect = false
            feedback = "Keep knees aligned! Avoid inward collapse."
            confidence = 0.72
        }
        
        // 4. Vertical Alignment (hip-ankle)
        let hipAnkleDistance = simd_length(simd_float2(avgHip.x - avgAnkle.x, avgHip.z - avgAnkle.z))
        metricMeasurements["hip_ankle_horizontal_distance"] = hipAnkleDistance
        
        // Excessive forward lean check
        if hipAnkleDistance > 0.3 && isCorrect {
            feedback = "Good depth! Keep chest up and avoid excessive lean."
            confidence = 0.80
        }
        
        return BiometricResult(
            isCorrect: isCorrect,
            primaryFeedback: feedback,
            confidence: confidence,
            metricMeasurements: metricMeasurements,
            jointAngles: jointAngles,
            deviationMetrics: deviationMetrics,
            timestamp: timestamp
        )
    }
    
    /// Analyzes plank form using 3D metric coordinates
    /// - Parameter joints: Dictionary of joint positions in metric space
    /// - Returns: BiometricResult with comprehensive metrics
    func analyzePlank3D(
        joints: [VNHumanBodyPoseObservation.JointName: simd_float3],
        timestamp: TimeInterval = 0.0
    ) -> BiometricResult {
        // Extract required joints
        guard let leftShoulder = joints[.leftShoulder],
              let rightShoulder = joints[.rightShoulder],
              let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip],
              let leftAnkle = joints[.leftAnkle],
              let rightAnkle = joints[.rightAnkle] else {
            return BiometricResult(
                isCorrect: true,
                primaryFeedback: "Position yourself fully in frame",
                confidence: 0.3,
                timestamp: timestamp
            )
        }
        
        // Calculate average positions
        let avgShoulder = (leftShoulder + rightShoulder) / 2.0
        let avgHip = (leftHip + rightHip) / 2.0
        let avgAnkle = (leftAnkle + rightAnkle) / 2.0
        
        var metricMeasurements: [String: Float] = [:]
        var deviationMetrics: [String: Float] = [:]
        var isCorrect = true
        var feedback = "Excellent plank form!"
        var confidence: Float = 0.85
        
        // 1. Spinal Alignment Analysis
        // Define ideal body line from shoulders to ankles
        let bodyAxis = avgAnkle - avgShoulder
        let bodyLength = simd_length(bodyAxis)
        
        // Project hip onto ideal body line
        let shoulderToHip = avgHip - avgShoulder
        let t = simd_dot(shoulderToHip, bodyAxis) / (bodyLength * bodyLength)
        let projectedHip = avgShoulder + (bodyAxis * t)
        
        // Calculate hip deviation from ideal line
        let hipDeviation = avgHip - projectedHip
        let verticalDeviation = hipDeviation.y
        
        deviationMetrics["hip_alignment_deviation_meters"] = abs(verticalDeviation)
        metricMeasurements["body_line_length_meters"] = bodyLength
        
        // 2. Hip Sag Detection (hips too low)
        if verticalDeviation < -0.08 {  // Hips 8cm below line
            isCorrect = false
            feedback = "Raise your hips! Engage your core."
            confidence = 0.78
        }
        
        // 3. Hip Pike Detection (hips too high)
        if verticalDeviation > 0.08 {  // Hips 8cm above line
            isCorrect = false
            feedback = "Lower your hips to form a straight line."
            confidence = 0.78
        }
        
        // 4. Shoulder-Hip-Ankle Angle
        let bodyAngle = Self.calculateJointAngle(
            center: avgHip,
            p1: avgShoulder,
            p2: avgAnkle
        )
        
        metricMeasurements["body_angle_deg"] = bodyAngle
        
        // Ideal plank: body should be nearly straight (170-180 degrees)
        if bodyAngle < 165 && isCorrect {
            isCorrect = false
            feedback = "Straighten your body! Maintain a straight line."
            confidence = 0.75
        }
        
        // 5. Core Engagement Check (relative position stability)
        // This would require temporal analysis - mark for future enhancement
        
        return BiometricResult(
            isCorrect: isCorrect,
            primaryFeedback: feedback,
            confidence: confidence,
            metricMeasurements: metricMeasurements,
            jointAngles: [:],
            deviationMetrics: deviationMetrics,
            timestamp: timestamp
        )
    }
    
    /// Analyzes push-up form using 3D metric coordinates
    /// - Parameter joints: Dictionary of joint positions in metric space
    /// - Returns: BiometricResult with comprehensive metrics
    func analyzePushUp3D(
        joints: [VNHumanBodyPoseObservation.JointName: simd_float3],
        timestamp: TimeInterval = 0.0
    ) -> BiometricResult {
        // Extract required joints
        guard let leftShoulder = joints[.leftShoulder],
              let rightShoulder = joints[.rightShoulder],
              let leftElbow = joints[.leftElbow],
              let rightElbow = joints[.rightElbow],
              let leftWrist = joints[.leftWrist],
              let rightWrist = joints[.rightWrist],
              let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip] else {
            return BiometricResult(
                isCorrect: true,
                primaryFeedback: "Position yourself fully in frame",
                confidence: 0.3,
                timestamp: timestamp
            )
        }
        
        // Calculate average positions
        let avgShoulder = (leftShoulder + rightShoulder) / 2.0
        let avgWrist = (leftWrist + rightWrist) / 2.0
        let avgHip = (leftHip + rightHip) / 2.0
        
        var metricMeasurements: [String: Float] = [:]
        var jointAngles: [String: Float] = [:]
        var isCorrect = true
        var feedback = "Great push-up form!"
        var confidence: Float = 0.85
        
        // 1. Elbow Angle Analysis (shoulder-elbow-wrist)
        let leftElbowAngle = Self.calculateJointAngle(
            center: leftElbow,
            p1: leftShoulder,
            p2: leftWrist
        )
        let rightElbowAngle = Self.calculateJointAngle(
            center: rightElbow,
            p1: rightShoulder,
            p2: rightWrist
        )
        let avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2.0 as Float
        
        jointAngles["elbow_angle_deg"] = avgElbowAngle
        jointAngles["left_elbow_angle_deg"] = leftElbowAngle
        jointAngles["right_elbow_angle_deg"] = rightElbowAngle
        
        // Target: < 90 degrees for proper depth
        if avgElbowAngle > 120 {
            isCorrect = false
            feedback = "Go lower! Bend your elbows more."
            confidence = 0.75
        }
        
        // 2. Chest Descent Depth (vertical shoulder displacement)
        let shoulderHeight = avgShoulder.y
        metricMeasurements["shoulder_height_meters"] = shoulderHeight
        
        // 3. Body Alignment Check (shoulder-hip linearity)
        let shoulderHipDistance = simd_length(avgShoulder - avgHip)
        let verticalDifference = abs(avgShoulder.y - avgHip.y)
        let alignmentRatio = verticalDifference / shoulderHipDistance
        
        metricMeasurements["body_alignment_ratio"] = alignmentRatio
        
        // Poor alignment if hips sag significantly
        if alignmentRatio > 0.3 && isCorrect {
            feedback = "Keep your body straight! Engage your core."
            confidence = 0.78
        }
        
        // 4. Hand Position Check (wrists should be under shoulders)
        let handShoulderOffset = simd_length(simd_float2(
            avgWrist.x - avgShoulder.x,
            avgWrist.z - avgShoulder.z
        ))
        
        metricMeasurements["hand_shoulder_offset_meters"] = handShoulderOffset
        
        if handShoulderOffset > 0.15 && isCorrect {
            feedback = "Adjust hand position! Hands should be under shoulders."
            confidence = 0.72
        }
        
        return BiometricResult(
            isCorrect: isCorrect,
            primaryFeedback: feedback,
            confidence: confidence,
            metricMeasurements: metricMeasurements,
            jointAngles: jointAngles,
            deviationMetrics: [:],
            timestamp: timestamp
        )
    }
    
    /// Analyzes lunge form using 3D metric coordinates
    /// - Parameter joints: Dictionary of joint positions in metric space
    /// - Returns: BiometricResult with comprehensive metrics
    func analyzeLunge3D(
        joints: [VNHumanBodyPoseObservation.JointName: simd_float3],
        timestamp: TimeInterval = 0.0
    ) -> BiometricResult {
        // Extract required joints
        guard let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip],
              let leftKnee = joints[.leftKnee],
              let rightKnee = joints[.rightKnee],
              let leftAnkle = joints[.leftAnkle],
              let rightAnkle = joints[.rightAnkle] else {
            return BiometricResult(
                isCorrect: true,
                primaryFeedback: "Position yourself fully in frame",
                confidence: 0.3,
                timestamp: timestamp
            )
        }
        
        var jointAngles: [String: Float] = [:]
        var metricMeasurements: [String: Float] = [:]
        var isCorrect = true
        var feedback = "Perfect lunge form!"
        var confidence: Float = 0.80
        
        // Determine which leg is forward (lower knee Y position)
        let isFrontLeft = leftKnee.y < rightKnee.y
        let frontHip = isFrontLeft ? leftHip : rightHip
        let frontKnee = isFrontLeft ? leftKnee : rightKnee
        let frontAnkle = isFrontLeft ? leftAnkle : rightAnkle
        let backHip = isFrontLeft ? rightHip : leftHip
        let backKnee = isFrontLeft ? rightKnee : leftKnee
        let backAnkle = isFrontLeft ? rightAnkle : leftAnkle
        
        // 1. Front Knee Angle (should be ~90 degrees)
        let frontKneeAngle = Self.calculateJointAngle(
            center: frontKnee,
            p1: frontHip,
            p2: frontAnkle
        )
        
        jointAngles["front_knee_angle_deg"] = frontKneeAngle
        
        if frontKneeAngle < 70 || frontKneeAngle > 110 {
            isCorrect = false
            feedback = "Adjust front leg! Aim for 90-degree knee angle."
            confidence = 0.75
        }
        
        // 2. Back Knee Angle (should also be ~90 degrees)
        let backKneeAngle = Self.calculateJointAngle(
            center: backKnee,
            p1: backHip,
            p2: backAnkle
        )
        
        jointAngles["back_knee_angle_deg"] = backKneeAngle
        
        // 3. Back Knee Height (should be close to ground)
        let backKneeHeight = backKnee.y
        metricMeasurements["back_knee_height_meters"] = backKneeHeight
        
        if backKneeHeight > 0.3 && isCorrect {
            isCorrect = false
            feedback = "Lower down more! Back knee should be near the ground."
            confidence = 0.70
        }
        
        // 4. Front Knee Forward Position (shouldn't extend far past ankle)
        let kneeAnkleOffset = abs(frontKnee.z - frontAnkle.z)
        metricMeasurements["front_knee_forward_offset_meters"] = kneeAnkleOffset
        
        if kneeAnkleOffset > 0.15 && isCorrect {
            feedback = "Good depth! Keep front knee aligned over ankle."
            confidence = 0.78
        }
        
        // 5. Torso Uprightness
        let avgHip = (leftHip + rightHip) / 2.0
        let torsoLean = avgHip.z  // Z-axis measures forward/back lean
        
        metricMeasurements["torso_lean_meters"] = abs(torsoLean)
        
        return BiometricResult(
            isCorrect: isCorrect,
            primaryFeedback: feedback,
            confidence: confidence,
            metricMeasurements: metricMeasurements,
            jointAngles: jointAngles,
            deviationMetrics: [:],
            timestamp: timestamp
        )
    }
}

// MARK: - Bar Path Analysis (Advanced Feature)

extension BiomechanicsEngine {
    
    /// Tracks bar path for weighted exercises
    /// Reference: https://vaughnweightlifting.com/2022/02/07/the-basics-of-a-world-class-bar-path-part-1/
    struct BarPathMetrics {
        let totalDeviation: Float       // Total path deviation in meters
        let horizontalDrift: Float      // Lateral drift from vertical
        let optimalityScore: Float      // 0.0-1.0 score vs ideal path
        let path: [simd_float3]         // Full 3D trajectory
    }
    
    /// Analyzes bar path from wrist position history
    /// - Parameter wristPositions: Array of wrist 3D positions over time
    /// - Returns: Bar path metrics
    static func trackBarPath(wristPositions: [simd_float3]) -> BarPathMetrics {
        // TODO Phase 3+: Implement bar path analysis
        return BarPathMetrics(
            totalDeviation: 0.0,
            horizontalDrift: 0.0,
            optimalityScore: 1.0,
            path: wristPositions
        )
    }
}

