//
//  LiveSessionManager.swift
//  AI Live Trainer System
//

import Foundation
import AVFoundation
import Vision
import Combine

class LiveSessionManager: NSObject, ObservableObject {
    // Published properties
    @Published var isTracking = false
    @Published var isFormCorrect = true
    @Published var liveFeedback = ""
    @Published var currentRep = 0
    @Published var currentSet = 1
    @Published var currentExercise = ""
    @Published var elapsedTime: TimeInterval = 0
    @Published var workoutCompleted = false
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    // Camera session
    var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    // AI Trainer
    private var aiTrainer: AITrainerEngine?
    private var workout: WorkoutModel?
    private var sessionStartTime: Date?
    private var timer: Timer?
    private var feedbackHistory: [FeedbackItem] = []
    
    // Feedback managers
    private let voiceManager = VoiceFeedbackManager.shared
    private let hapticManager = HapticFeedbackManager.shared
    
    // Demo mode
    var isDemoMode = false
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func startSession(workout: WorkoutModel) {
        self.workout = workout
        self.currentExercise = workout.exercises.first?.name ?? "Exercise"
        self.sessionStartTime = Date()
        self.aiTrainer = AITrainerEngine()
        
        startTimer()
        startCamera()
        isTracking = true
        
        // Haptic and voice feedback for workout start
        hapticManager.workoutStarted()
        voiceManager.speak("Let's begin! Starting \(workout.displayName).", priority: .high)
    }
    
    func endSession() {
        stopTimer()
        stopCamera()
        isTracking = false
    }
    
    func createWorkoutSession() -> WorkoutSession {
        let duration = Date().timeIntervalSince(sessionStartTime ?? Date())
        let accuracy = calculateAccuracy()
        
        return WorkoutSession(
            workoutId: workout?.id ?? "unknown",
            workoutName: workout?.displayName ?? "Workout",
            duration: duration,
            accuracyPercentage: accuracy,
            totalReps: currentRep,
            completedSets: currentSet,
            feedbackItems: feedbackHistory
        )
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func startCamera() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCamera() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.elapsedTime += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Rep & Set Management
    
    func incrementRep() {
        DispatchQueue.main.async {
            self.currentRep += 1
            
            // Haptic feedback for rep
            self.hapticManager.repCompleted()
            
            // Voice count every 5 reps
            if self.currentRep % 5 == 0 {
                self.voiceManager.speakRepCount(self.currentRep)
            }
            
            // Check if set is complete
            if let workout = self.workout,
               let currentExercise = workout.exercises.first,
               self.currentRep >= currentExercise.reps {
                self.completeSet()
            }
        }
    }
    
    private func completeSet() {
        let completedSetNumber = currentSet
        currentSet += 1
        currentRep = 0
        
        // Haptic and voice for set completion
        hapticManager.setCompleted()
        voiceManager.speakSetComplete(completedSetNumber, total: workout?.setCount ?? 0)
        
        if currentSet > workout?.setCount ?? 0 {
            workoutCompleted = true
            hapticManager.workoutCompleted()
            voiceManager.speakWorkoutComplete()
        }
    }
    
    // MARK: - Feedback Management
    
    func provideFeedback(_ message: String, severity: FeedbackItem.FeedbackSeverity) {
        DispatchQueue.main.async {
            self.liveFeedback = message
            self.isFormCorrect = severity == .good
            
            let feedback = FeedbackItem(
                exerciseName: self.currentExercise,
                message: message,
                timestamp: Date(),
                severity: severity
            )
            self.feedbackHistory.append(feedback)
            
            // Voice and haptic feedback
            if severity == .error || severity == .warning {
                self.hapticManager.formCorrection()
                self.voiceManager.speakCorrection(for: self.currentExercise, correction: message)
            } else if severity == .good {
                self.hapticManager.goodForm()
                if self.currentRep % 5 == 0 {
                    self.voiceManager.speakEncouragement()
                }
            }
            
            // Clear feedback after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.liveFeedback == message {
                    self.liveFeedback = ""
                    self.isFormCorrect = true
                }
            }
        }
    }
    
    // MARK: - Accuracy Calculation
    
    private func calculateAccuracy() -> Double {
        let totalFeedback = Double(feedbackHistory.count)
        if totalFeedback == 0 {
            return 100.0
        }
        
        let goodFeedback = Double(feedbackHistory.filter { $0.severity == .good }.count)
        return (goodFeedback / totalFeedback) * 100.0
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension LiveSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Process frame with Vision
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }
            
            self.processBodyPose(observation)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func processBodyPose(_ observation: VNHumanBodyPoseObservation) {
        guard let aiTrainer = aiTrainer else { return }
        
        // Extract body points
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist, .root,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle
        ]
        
        for joint in allJoints {
            if let point = try? observation.recognizedPoint(joint), point.confidence > 0.3 {
                points[joint] = CGPoint(x: point.location.x, y: point.location.y)
            }
        }
        
        DispatchQueue.main.async {
            self.bodyPoints = points
        }
        
        // Analyze form
        let result = aiTrainer.analyzeForm(observation: observation, exercise: currentExercise)
        
        if !result.isCorrect {
            provideFeedback(result.feedback, severity: .warning)
        } else if currentRep > 0 && currentRep % 5 == 0 {
            provideFeedback("Great form! Keep it up!", severity: .good)
        }
    }
}

