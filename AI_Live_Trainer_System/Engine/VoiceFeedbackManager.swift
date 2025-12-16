//
//  VoiceFeedbackManager.swift
//  AI Live Trainer System
//

import Foundation
import AVFoundation

class VoiceFeedbackManager: NSObject, @unchecked Sendable {
    static let shared = VoiceFeedbackManager()
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isEnabled = true
    
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        configureTone()
    }
    
    func speak(_ text: String, priority: FeedbackPriority = .normal) {
        guard isEnabled, !text.isEmpty else { return }
        
        // Stop current speech if high priority
        if priority == .high && speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52 // Slightly faster than default for workout context
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for energy
        utterance.volume = 1.0
        
        // Add emphasis for corrections
        if text.contains("!") || priority == .high {
            utterance.pitchMultiplier = 1.2
            utterance.rate = 0.48
        }
        
        speechSynthesizer.speak(utterance)
    }
    
    func speakFeedback(for exercise: String, feedback: String) {
        let fullMessage = "\(feedback)"
        speak(fullMessage, priority: .normal)
    }
    
    func speakCorrection(for exercise: String, correction: String) {
        speak(correction, priority: .high)
    }
    
    func speakEncouragement() {
        let encouragements = [
            "Great job!",
            "Keep it up!",
            "You're doing amazing!",
            "Perfect form!",
            "Nice work!",
            "That's the way!",
            "Excellent!",
            "Strong!"
        ]
        
        if let message = encouragements.randomElement() {
            speak(message, priority: .low)
        }
    }
    
    func speakRepCount(_ count: Int) {
        speak("\(count)", priority: .low)
    }
    
    func speakSetComplete(_ setNumber: Int, total: Int) {
        speak("Set \(setNumber) of \(total) complete. Take a breath.", priority: .normal)
    }
    
    func speakWorkoutComplete() {
        speak("Workout complete! Amazing effort!", priority: .high)
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled && speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .word)
    }
    
    private func configureTone() {
        // Set audio session for voice coaching during workout
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    enum FeedbackPriority {
        case low      // Encouragement, rep counts
        case normal   // Standard feedback
        case high     // Corrections, important alerts
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceFeedbackManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Could add haptic feedback here
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Cleanup if needed
    }
}

// MARK: - Feedback Phrases Library

struct FeedbackPhrases {
    static let squat = [
        "deeper": "Get deeper! Lower your hips.",
        "knees": "Keep your knees aligned with your toes.",
        "back": "Keep your back straight.",
        "perfect": "Perfect squat form!"
    ]
    
    static let plank = [
        "hips_low": "Raise your hips! Keep your body straight.",
        "hips_high": "Lower your hips to form a straight line.",
        "core": "Engage your core.",
        "perfect": "Excellent plank form!"
    ]
    
    static let pushup = [
        "depth": "Go lower! Bend your elbows more.",
        "hands": "Hands should be under your shoulders.",
        "back": "Keep your body in a straight line.",
        "perfect": "Great push-up form!"
    ]
    
    static let lunge = [
        "depth": "Lower down more! Aim for 90-degree angles.",
        "back_knee": "Lower your back knee closer to the ground.",
        "balance": "Keep your torso upright.",
        "perfect": "Perfect lunge form!"
    ]
    
    static func getFeedback(for exercise: String, type: String) -> String {
        let exerciseLower = exercise.lowercased()
        
        if exerciseLower.contains("squat") {
            return squat[type] ?? "Keep going!"
        } else if exerciseLower.contains("plank") {
            return plank[type] ?? "Hold steady!"
        } else if exerciseLower.contains("push") {
            return pushup[type] ?? "Nice work!"
        } else if exerciseLower.contains("lunge") {
            return lunge[type] ?? "Good form!"
        } else {
            return "Keep it up!"
        }
    }
}

