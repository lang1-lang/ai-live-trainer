//
//  DemoModeManager.swift
//  AI Live Trainer System
//

import Foundation
import UIKit
import AVFoundation

class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    @Published var isDemoActive = false
    @Published var demoScenario: DemoScenario = .perfectForm
    
    private var demoTimer: Timer?
    private var currentStep = 0
    
    enum DemoScenario {
        case perfectForm      // All green wireframe
        case needsCorrection  // Red joints with feedback
        case fullWorkflow     // Complete app demo flow
    }
    
    struct DemoStep {
        let duration: TimeInterval
        let formCorrect: Bool
        let feedback: String
        let reps: Int
    }
    
    private let perfectFormSteps: [DemoStep] = [
        DemoStep(duration: 5, formCorrect: true, feedback: "Perfect form!", reps: 1),
        DemoStep(duration: 5, formCorrect: true, feedback: "Great depth!", reps: 2),
        DemoStep(duration: 5, formCorrect: true, feedback: "Excellent!", reps: 3),
        DemoStep(duration: 5, formCorrect: true, feedback: "Keep it up!", reps: 4)
    ]
    
    private let correctionSteps: [DemoStep] = [
        DemoStep(duration: 3, formCorrect: false, feedback: "Lower your hips more", reps: 1),
        DemoStep(duration: 4, formCorrect: true, feedback: "That's better!", reps: 2),
        DemoStep(duration: 3, formCorrect: false, feedback: "Keep your back straight", reps: 3),
        DemoStep(duration: 4, formCorrect: true, feedback: "Perfect correction!", reps: 4)
    ]
    
    private init() {}
    
    func startDemo(scenario: DemoScenario) {
        isDemoActive = true
        demoScenario = scenario
        currentStep = 0
        
        switch scenario {
        case .perfectForm:
            runDemoSequence(steps: perfectFormSteps)
        case .needsCorrection:
            runDemoSequence(steps: correctionSteps)
        case .fullWorkflow:
            runFullWorkflowDemo()
        }
    }
    
    func stopDemo() {
        isDemoActive = false
        demoTimer?.invalidate()
        demoTimer = nil
        currentStep = 0
    }
    
    private func runDemoSequence(steps: [DemoStep]) {
        guard currentStep < steps.count else {
            stopDemo()
            return
        }
        
        let step = steps[currentStep]
        
        // Simulate feedback
        NotificationCenter.default.post(
            name: .demoFeedbackUpdate,
            object: nil,
            userInfo: [
                "formCorrect": step.formCorrect,
                "feedback": step.feedback,
                "reps": step.reps
            ]
        )
        
        currentStep += 1
        
        // Schedule next step
        demoTimer = Timer.scheduledTimer(withTimeInterval: step.duration, repeats: false) { [weak self] _ in
            self?.runDemoSequence(steps: steps)
        }
    }
    
    private func runFullWorkflowDemo() {
        // This would orchestrate a full app walkthrough
        // Home -> Select Workout -> AR View -> Complete -> Summary
        // Implementation would coordinate with view navigation
    }
    
    // MARK: - Demo Data Generation
    
    func generateDemoBodyPoints() -> [String: CGPoint] {
        // Generate realistic body pose points for demo mode
        let points: [String: CGPoint] = [
            "nose": CGPoint(x: 0.5, y: 0.8),
            "neck": CGPoint(x: 0.5, y: 0.7),
            "leftShoulder": CGPoint(x: 0.4, y: 0.7),
            "rightShoulder": CGPoint(x: 0.6, y: 0.7),
            "leftElbow": CGPoint(x: 0.35, y: 0.55),
            "rightElbow": CGPoint(x: 0.65, y: 0.55),
            "leftWrist": CGPoint(x: 0.32, y: 0.4),
            "rightWrist": CGPoint(x: 0.68, y: 0.4),
            "leftHip": CGPoint(x: 0.45, y: 0.45),
            "rightHip": CGPoint(x: 0.55, y: 0.45),
            "leftKnee": CGPoint(x: 0.43, y: 0.25),
            "rightKnee": CGPoint(x: 0.57, y: 0.25),
            "leftAnkle": CGPoint(x: 0.42, y: 0.05),
            "rightAnkle": CGPoint(x: 0.58, y: 0.05)
        ]
        
        return points
    }
    
    func generateDemoVideo() -> AVAsset? {
        // In a real implementation, this would return a pre-recorded demo video
        // For now, return nil and use live camera with overlay
        return nil
    }
    
    // MARK: - Screenshot Helper
    
    func captureScreenshot(of view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func prepareForAppStoreScreenshots() {
        // Set up ideal conditions for App Store screenshots
        isDemoActive = true
        demoScenario = .perfectForm
        
        // Force UI to show perfect state
        NotificationCenter.default.post(
            name: .prepareForScreenshot,
            object: nil,
            userInfo: ["showPerfectUI": true]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let demoFeedbackUpdate = Notification.Name("demoFeedbackUpdate")
    static let prepareForScreenshot = Notification.Name("prepareForScreenshot")
}

