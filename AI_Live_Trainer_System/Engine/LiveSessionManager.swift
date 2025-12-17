//
//  LiveSessionManager.swift
//  AI Live Trainer System
//
//  Phase 2 Upgrade: Adding 3D Vision + LiDAR sensor fusion
//  Reference: https://developer.apple.com/documentation/vision/vndetecthumanbodypose3drequest
//

import Foundation
import AVFoundation
import Vision
import Combine
import simd  // Phase 2: SIMD for 3D vector operations

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
    
    // Phase 2: 3D joint positions in metric space
    @Published var bodyPoints3D: [VNHumanBodyPoseObservation.JointName: simd_float3] = [:]
    @Published var jointConfidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]
    @Published var deviceMode: DeviceCapabilityMode = .standard
    
    // Camera session
    var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    // Phase 2: Depth output for LiDAR/TrueDepth
    private var depthOutput: AVCaptureDepthDataOutput?
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    private var depthDataMap: AVDepthData?
    
    // AI Trainer
    private var aiTrainer: AITrainerEngine?
    private var workout: WorkoutModel?
    private var sessionStartTime: Date?
    private var timer: Timer?
    private var feedbackHistory: [FeedbackItem] = []
    
    // Phase 2: Sensor fusion core
    private var sensorFusion: SensorFusionCore?
    
    // Phase 5: Biometric data storage
    private var biometricHistory: [BiometricResult] = []
    
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
        
        // Phase 2: Detect device capabilities
        deviceMode = DeviceCapabilityManager.shared.mode
        sensorFusion = SensorFusionCore(deviceMode: deviceMode)
        
        // Print system capability report
        DeviceCapabilityManager.shared.printSystemReport()
        
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
        
        // Phase 5: Calculate average metrics
        var averageMetrics: [String: Float]?
        if !biometricHistory.isEmpty {
            var metricsSum: [String: (sum: Float, count: Int)] = [:]
            
            for result in biometricHistory {
                // Aggregate all metrics
                for (key, value) in result.jointAngles {
                    let current = metricsSum[key] ?? (0, 0)
                    metricsSum[key] = (current.sum + value, current.count + 1)
                }
                for (key, value) in result.metricMeasurements {
                    let current = metricsSum[key] ?? (0, 0)
                    metricsSum[key] = (current.sum + value, current.count + 1)
                }
                for (key, value) in result.deviationMetrics {
                    let current = metricsSum[key] ?? (0, 0)
                    metricsSum[key] = (current.sum + abs(value), current.count + 1)
                }
            }
            
            // Calculate averages
            averageMetrics = metricsSum.mapValues { $0.sum / Float($0.count) }
        }
        
        // Phase 5: Convert biometric results to codable format
        let biometricData = biometricHistory.map { BiometricResultData(from: $0) }
        
        return WorkoutSession(
            workoutId: workout?.id ?? "unknown",
            workoutName: workout?.displayName ?? "Workout",
            duration: duration,
            accuracyPercentage: accuracy,
            totalReps: currentRep,
            completedSets: currentSet,
            feedbackItems: feedbackHistory,
            biometricData: biometricData.isEmpty ? nil : biometricData,
            deviceMode: deviceMode.rawValue,
            averageMetrics: averageMetrics
        )
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .high
        
        // Phase 2: Get appropriate device based on capability mode
        let videoDevice: AVCaptureDevice?
        
        if deviceMode == .pro,
           let depthDevice = DeviceCapabilityManager.shared.getDepthCapableDevice(position: .front) {
            // Pro mode: Use depth-capable device
            videoDevice = depthDevice
            print("✅ Using depth-capable camera for Pro mode")
        } else {
            // Standard mode: Use regular wide-angle camera
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            print("ℹ️ Using standard camera")
        }
        
        guard let device = videoDevice,
              let videoInput = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Failed to create video input")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Phase 2: Setup depth output for Pro mode
        if deviceMode == .pro {
            setupDepthOutput(for: device)
        }
    }
    
    // MARK: - Phase 2: Depth Output Setup
    
    /// Configures depth data output for LiDAR/TrueDepth camera
    /// Reference: https://developer.apple.com/documentation/avfoundation/capturing-depth-using-the-lidar-camera
    private func setupDepthOutput(for device: AVCaptureDevice) {
        guard let captureSession = captureSession else { return }
        
        // Create depth output
        depthOutput = AVCaptureDepthDataOutput()
        guard let depthOutput = depthOutput else { return }
        
        depthOutput.isFilteringEnabled = true  // Enable depth smoothing
        
        if captureSession.canAddOutput(depthOutput) {
            captureSession.addOutput(depthOutput)
            
            // Synchronize RGB and depth data
            outputSynchronizer = AVCaptureDataOutputSynchronizer(
                dataOutputs: [videoOutput, depthOutput]
            )
            outputSynchronizer?.setDelegate(self, queue: sessionQueue)
            
            print("✅ Depth output configured with synchronization")
        } else {
            print("⚠️ Cannot add depth output, falling back to standard mode")
            self.deviceMode = .standard
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
        // This delegate is used for Standard mode (no depth synchronization)
        guard deviceMode == .standard else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Standard mode: Use 2D Vision (legacy path)
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
    
    // LEGACY: 2D pose processing (Standard mode)
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
    
    // MARK: - Phase 2/3: 3D Vision Processing with Biomechanics Analysis
    
    /// Processes 3D body pose with metric coordinates (Pro mode)
    /// Reference: https://developer.apple.com/documentation/vision/vndetecthumanbodypose3drequest
    @available(iOS 17.0, *)
    private func processBodyPose3D(_ observation: VNHumanBodyPose3DObservation, depthData: AVDepthData?) {
        guard let sensorFusion = sensorFusion,
              let aiTrainer = aiTrainer else { return }
        
        // Fuse 3D pose with depth data to get metric coordinates
        let metricJoints = sensorFusion.fuseDepthWithPose(
            observation: observation,
            depthData: depthData
        )
        
        // Update 3D body points for visualization
        DispatchQueue.main.async {
            self.bodyPoints3D = metricJoints
            
            // 3D observations don't have per-joint confidence, use default high confidence
            var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]
            for jointName in metricJoints.keys {
                confidences[jointName] = 0.85  // Default confidence for successfully detected joints
            }
            self.jointConfidences = confidences
        }
        
        // Extract 2D points for legacy visualization compatibility
        var points2D: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        for (jointName, position3D) in metricJoints {
            // Simple orthographic projection for 2D display
            // Normalize coordinates to 0-1 range for screen display
            points2D[jointName] = CGPoint(
                x: CGFloat((position3D.x + 1.0) / 2.0),  // Convert from [-1,1] to [0,1]
                y: CGFloat((position3D.y + 1.0) / 2.0)
            )
        }
        
        DispatchQueue.main.async {
            self.bodyPoints = points2D
        }
        
        // Phase 3: Use BiomechanicsEngine for 3D analysis
        let timestamp = Date().timeIntervalSince(sessionStartTime ?? Date())
        let biometricResult = aiTrainer.analyzeForm3D(
            joints3D: metricJoints,
            exercise: currentExercise,
            timestamp: timestamp
        )
        
        // Phase 5: Store biometric result for analytics
        biometricHistory.append(biometricResult)
        
        // Convert BiometricResult to feedback
        if !biometricResult.isCorrect {
            provideFeedback(biometricResult.primaryFeedback, severity: .warning)
        } else if currentRep > 0 && currentRep % 5 == 0 {
            provideFeedback(biometricResult.primaryFeedback, severity: .good)
        }
        
        // Debug: Print detailed metrics (remove in production)
        #if DEBUG
        if !biometricResult.jointAngles.isEmpty || !biometricResult.metricMeasurements.isEmpty {
            print("📊 Biometric Analysis:")
            print(biometricResult)
        }
        #endif
    }
}

// MARK: - Phase 2: Synchronized Depth + RGB Delegate

@available(iOS 17.0, *)
extension LiveSessionManager: AVCaptureDataOutputSynchronizerDelegate {
    
    /// Handles synchronized RGB and depth data (Pro mode)
    /// Reference: https://developer.apple.com/documentation/avfoundation/avcapturedataoutputsynchronizer
    func dataOutputSynchronizer(
        _ synchronizer: AVCaptureDataOutputSynchronizer,
        didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection
    ) {
        // Extract RGB sample buffer
        guard let syncedVideoData = synchronizedDataCollection.synchronizedData(
            for: videoOutput
        ) as? AVCaptureSynchronizedSampleBufferData,
              !syncedVideoData.sampleBufferWasDropped,
              let pixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer) else {
            return
        }
        
        // Extract depth data (if available)
        var depthData: AVDepthData?
        if let depthOutput = depthOutput,
           let syncedDepthData = synchronizedDataCollection.synchronizedData(
            for: depthOutput
           ) as? AVCaptureSynchronizedDepthData,
           !syncedDepthData.depthDataWasDropped {
            depthData = syncedDepthData.depthData
        }
        
        // Store depth data for fusion
        self.depthDataMap = depthData
        
        // Process with 3D Vision request
        let request = VNDetectHumanBodyPose3DRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPose3DObservation],
                  let observation = observations.first else {
                return
            }
            
            self.processBodyPose3D(observation, depthData: depthData)
        }
        
        // Execute Vision request
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

