//
//  HapticFeedback.swift
//  AI Live Trainer System
//

import UIKit
import CoreHaptics

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private var engine: CHHapticEngine?
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Prepare feedback generators
            impactFeedback.prepare()
            notificationFeedback.prepare()
            selectionFeedback.prepare()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }
    
    // MARK: - Workout Feedback
    
    func formCorrection() {
        // Strong haptic for form errors
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func goodForm() {
        // Light haptic for good form
        notificationFeedback.notificationOccurred(.success)
    }
    
    func repCompleted() {
        // Quick tap for rep count
        impactFeedback.impactOccurred()
    }
    
    func setCompleted() {
        // Success pattern for set completion
        notificationFeedback.notificationOccurred(.success)
        
        // Add custom pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notificationFeedback.notificationOccurred(.success)
        }
    }
    
    func workoutStarted() {
        // Strong impact to signal start
        impactFeedback.impactOccurred(intensity: 1.0)
    }
    
    func workoutCompleted() {
        // Celebration pattern
        playCustomPattern(type: .celebration)
    }
    
    // MARK: - UI Feedback
    
    func buttonTap() {
        selectionFeedback.selectionChanged()
    }
    
    func cardSwipe() {
        impactFeedback.impactOccurred(intensity: 0.7)
    }
    
    // MARK: - Custom Patterns
    
    private func playCustomPattern(type: HapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        
        var events: [CHHapticEvent] = []
        
        switch type {
        case .celebration:
            // Quick burst pattern for celebration
            for i in 0..<5 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + Double(i) * 0.1))
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.1
                )
                events.append(event)
            }
            
        case .error:
            // Double strong tap
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            ))
            
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0.15
            ))
            
        case .countdown:
            // Three taps with increasing intensity
            for i in 1...3 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i) * 0.3)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i - 1) * 0.5
                )
                events.append(event)
            }
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    enum HapticPattern {
        case celebration
        case error
        case countdown
    }
}

