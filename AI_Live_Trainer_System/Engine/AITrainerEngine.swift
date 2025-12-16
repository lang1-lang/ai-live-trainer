//
//  AITrainerEngine.swift
//  AI Live Trainer System
//

import Foundation
import Vision
import CoreGraphics

struct FormAnalysisResult {
    let isCorrect: Bool
    let feedback: String
    let confidence: Float
}

class AITrainerEngine {
    
    func analyzeForm(observation: VNHumanBodyPoseObservation, exercise: String) -> FormAnalysisResult {
        let exerciseLower = exercise.lowercased()
        
        // Route to specific exercise checker
        if exerciseLower.contains("squat") {
            return analyzeSquat(observation: observation)
        } else if exerciseLower.contains("plank") {
            return analyzePlank(observation: observation)
        } else if exerciseLower.contains("push") {
            return analyzePushUp(observation: observation)
        } else if exerciseLower.contains("lunge") {
            return analyzeLunge(observation: observation)
        } else {
            return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.5)
        }
    }
    
    // MARK: - Squat Analysis
    
    private func analyzeSquat(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
        guard let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip),
              let leftKnee = try? observation.recognizedPoint(.leftKnee),
              let rightKnee = try? observation.recognizedPoint(.rightKnee),
              leftHip.confidence > 0.5,
              rightHip.confidence > 0.5,
              leftKnee.confidence > 0.5,
              rightKnee.confidence > 0.5 else {
            return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
        }
        
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
        let avgKneeY = (leftKnee.location.y + rightKnee.location.y) / 2
        
        // Check depth: hips should be at or below knee level
        if avgHipY > avgKneeY + 0.05 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Get deeper! Lower your hips.",
                confidence: 0.8
            )
        }
        
        // Check knee alignment
        if let leftAnkle = try? observation.recognizedPoint(.leftAnkle),
           let rightAnkle = try? observation.recognizedPoint(.rightAnkle),
           leftAnkle.confidence > 0.5,
           rightAnkle.confidence > 0.5 {
            
            let avgKneeX = (leftKnee.location.x + rightKnee.location.x) / 2
            let avgAnkleX = (leftAnkle.location.x + rightAnkle.location.x) / 2
            
            // Knees shouldn't go too far forward past toes
            if abs(avgKneeX - avgAnkleX) > 0.15 {
                return FormAnalysisResult(
                    isCorrect: false,
                    feedback: "Keep your knees aligned with your toes.",
                    confidence: 0.7
                )
            }
        }
        
        return FormAnalysisResult(
            isCorrect: true,
            feedback: "Perfect squat form!",
            confidence: 0.85
        )
    }
    
    // MARK: - Plank Analysis
    
    private func analyzePlank(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip),
              let leftAnkle = try? observation.recognizedPoint(.leftAnkle),
              let rightAnkle = try? observation.recognizedPoint(.rightAnkle),
              leftShoulder.confidence > 0.5,
              rightShoulder.confidence > 0.5,
              leftHip.confidence > 0.5,
              rightHip.confidence > 0.5 else {
            return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
        }
        
        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
        let avgAnkleY = (leftAnkle.location.y + rightAnkle.location.y) / 2
        
        // Check body alignment - should form a straight line
        let shoulderHipDiff = abs(avgShoulderY - avgHipY)
        let hipAnkleDiff = abs(avgHipY - avgAnkleY)
        
        // If hips are sagging
        if avgHipY < avgShoulderY - 0.1 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Raise your hips! Keep your body straight.",
                confidence: 0.8
            )
        }
        
        // If hips are too high
        if avgHipY > avgShoulderY + 0.1 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Lower your hips to form a straight line.",
                confidence: 0.8
            )
        }
        
        return FormAnalysisResult(
            isCorrect: true,
            feedback: "Excellent plank form!",
            confidence: 0.85
        )
    }
    
    // MARK: - Push-Up Analysis
    
    private func analyzePushUp(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftElbow = try? observation.recognizedPoint(.leftElbow),
              let rightElbow = try? observation.recognizedPoint(.rightElbow),
              let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              leftShoulder.confidence > 0.5,
              rightShoulder.confidence > 0.5 else {
            return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
        }
        
        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let avgElbowY = (leftElbow.location.y + rightElbow.location.y) / 2
        
        // Check elbow angle for proper depth
        let elbowDepth = avgShoulderY - avgElbowY
        
        if elbowDepth < 0.05 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Go lower! Bend your elbows more.",
                confidence: 0.75
            )
        }
        
        // Check hand placement
        let avgShoulderX = (leftShoulder.location.x + rightShoulder.location.x) / 2
        let avgWristX = (leftWrist.location.x + rightWrist.location.x) / 2
        
        if abs(avgShoulderX - avgWristX) > 0.2 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Hands should be under your shoulders.",
                confidence: 0.7
            )
        }
        
        return FormAnalysisResult(
            isCorrect: true,
            feedback: "Great push-up form!",
            confidence: 0.85
        )
    }
    
    // MARK: - Lunge Analysis
    
    private func analyzeLunge(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
        guard let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip),
              let leftKnee = try? observation.recognizedPoint(.leftKnee),
              let rightKnee = try? observation.recognizedPoint(.rightKnee),
              leftHip.confidence > 0.5,
              rightHip.confidence > 0.5 else {
            return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
        }
        
        // Determine which leg is forward (lower knee)
        let frontKnee = leftKnee.location.y < rightKnee.location.y ? leftKnee : rightKnee
        let backKnee = leftKnee.location.y < rightKnee.location.y ? rightKnee : leftKnee
        
        // Front knee should be at approximately 90 degrees
        let frontHip = leftKnee.location.y < rightKnee.location.y ? leftHip : rightHip
        let kneeHipDiff = abs(frontKnee.location.y - frontHip.location.y)
        
        if kneeHipDiff < 0.2 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Lower down more! Aim for 90-degree angles.",
                confidence: 0.75
            )
        }
        
        // Back knee should be close to ground
        if backKnee.location.y > 0.3 {
            return FormAnalysisResult(
                isCorrect: false,
                feedback: "Lower your back knee closer to the ground.",
                confidence: 0.7
            )
        }
        
        return FormAnalysisResult(
            isCorrect: true,
            feedback: "Perfect lunge form!",
            confidence: 0.8
        )
    }
    
    // MARK: - Helper Functions
    
    func calculateAngle(pointA: VNRecognizedPoint, pointB: VNRecognizedPoint, pointC: VNRecognizedPoint) -> Double {
        let a = CGPoint(x: pointA.location.x, y: pointA.location.y)
        let b = CGPoint(x: pointB.location.x, y: pointB.location.y)
        let c = CGPoint(x: pointC.location.x, y: pointC.location.y)
        
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        
        let dotProduct = ab.dx * cb.dx + ab.dy * cb.dy
        let magnitudeAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy)
        let magnitudeCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy)
        
        let cosine = dotProduct / (magnitudeAB * magnitudeCB)
        let angle = acos(cosine) * 180 / .pi
        
        return angle
    }
}

