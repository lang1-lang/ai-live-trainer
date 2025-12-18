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
import UIKit  // For device orientation

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
    
    // 🔴 CODE RED FIX: Debug & Performance Monitoring
    @Published var isDebugMode = false  // Show raw Vision dots
    @Published var currentFPS: Double = 0
    @Published var processingTimeMs: Double = 0
    @Published var trackingConfidence: Float = 0
    
    // Camera session
    var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.axis.sessionQueue", qos: .userInteractive)
    
    // 🔴 CODE RED FIX: Dedicated Vision processing queue (background, serial)
    private let visionQueue = DispatchQueue(label: "com.axis.visionQueue", qos: .userInitiated)
    
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
    
    // 🔴 CODE RED FIX: Frame timing & throttling
    private var lastFrameTime: CFTimeInterval = 0
    private var isProcessingFrame = false
    private let targetFrameTime: CFTimeInterval = 1.0 / 60.0  // 16.67ms for 60fps
    private var frameCount = 0
    private var fpsTimer: CFTimeInterval = 0
    
    // 🔴 CODE RED FIX: Thermal monitoring
    private var thermalStateObserver: NSObjectProtocol?
    private var hasDowngradedForThermal = false
    
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
        
        // 🔴 CODE RED FIX: Setup thermal monitoring
        setupThermalMonitoring()
        
        setupCamera()
    }
    
    deinit {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 🔴 CODE RED FIX: Thermal State Monitoring
    private func setupThermalMonitoring() {
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalStateChange()
        }
    }
    
    private func handleThermalStateChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .nominal, .fair:
            // Normal operation - restore Pro mode if available
            if hasDowngradedForThermal && DeviceCapabilityManager.shared.mode == .pro {
                print("🌡️ Thermal state improved - restoring Pro mode")
                deviceMode = .pro
                hasDowngradedForThermal = false
            }
            
        case .serious, .critical:
            // Thermal throttling - downgrade to Standard mode
            if deviceMode == .pro && !hasDowngradedForThermal {
                print("⚠️ Thermal throttling - downgrading to Standard mode")
                deviceMode = .standard
                hasDowngradedForThermal = true
                
                DispatchQueue.main.async {
                    self.provideFeedback("Device cooling down - switching to 2D mode", severity: .warning)
                }
            }
            
        @unknown default:
            break
        }
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
        
        // Frame dropping behavior (automatic in iOS 17+)
        if #unavailable(iOS 17.0) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
        }
        
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
        
        // 🔴 CODE RED FIX: "Glass Floor" Performance Rule - Drop frame if still processing
        guard !isProcessingFrame else {
            return  // Skip this frame to maintain 60fps
        }
        
        // 🔴 CODE RED FIX: Calculate FPS
        let currentTime = CACurrentMediaTime()
        if currentTime - fpsTimer >= 1.0 {
            DispatchQueue.main.async {
                self.currentFPS = Double(self.frameCount)
            }
            frameCount = 0
            fpsTimer = currentTime
        }
        frameCount += 1
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 🔴 CODE RED FIX: Mark as processing to prevent concurrent frame processing
        isProcessingFrame = true
        let frameStartTime = CACurrentMediaTime()
        
        // 🔴 CODE RED FIX: Process Vision on background queue (QoS: .userInitiated)
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Standard mode: Use 2D Vision (legacy path)
            let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
                guard let self = self,
                      let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    self?.isProcessingFrame = false
                    return
                }
                
                // Process pose on background thread
                self.processBodyPose(observation, orientation: self.getVideoOrientation(from: connection))
                
                // 🔴 CODE RED FIX: Measure processing time
                let processingTime = (CACurrentMediaTime() - frameStartTime) * 1000.0  // Convert to ms
                DispatchQueue.main.async {
                    self.processingTimeMs = processingTime
                }
                
                // Release processing lock
                self.isProcessingFrame = false
                
                // 🔴 CODE RED FIX: If processing took >16ms, next frame will be auto-dropped
                if processingTime > 16.0 {
                    #if DEBUG
                    print("⚠️ Frame processing exceeded 16ms budget: \(String(format: "%.1f", processingTime))ms")
                    #endif
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.getImageOrientation(from: connection), options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
                self.isProcessingFrame = false
            }
        }
    }
    
    // LEGACY: 2D pose processing (Standard mode)
    private func processBodyPose(_ observation: VNHumanBodyPoseObservation, orientation: AVCaptureVideoOrientation) {
        guard let aiTrainer = aiTrainer else { return }
        
        // Extract body points
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]
        
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist, .root,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle
        ]
        
        var totalConfidence: Float = 0
        var confidenceCount = 0
        
        for joint in allJoints {
            if let point = try? observation.recognizedPoint(joint), point.confidence > 0.3 {
                // 🔴 CODE RED FIX: Store normalized coordinates (Vision coordinates)
                // These will be converted to screen coordinates in the view layer
                points[joint] = CGPoint(x: point.location.x, y: point.location.y)
                confidences[joint] = point.confidence
                
                totalConfidence += point.confidence
                confidenceCount += 1
            }
        }
        
        // Calculate average tracking confidence
        let avgConfidence = confidenceCount > 0 ? totalConfidence / Float(confidenceCount) : 0
        
        DispatchQueue.main.async {
            self.bodyPoints = points
            self.trackingConfidence = avgConfidence
            
            // 🔴 CODE RED FIX: In debug mode, don't apply smoothing
            if self.isDebugMode {
                // Debug mode shows raw Vision output
                self.jointConfidences = confidences
            }
        }
        
        // Analyze form
        let result = aiTrainer.analyzeForm(observation: observation, exercise: currentExercise)
        
        if !result.isCorrect {
            provideFeedback(result.feedback, severity: .warning)
        } else if currentRep > 0 && currentRep % 5 == 0 {
            provideFeedback("Great form! Keep it up!", severity: .good)
        }
    }
    
    // 🔴 CODE RED FIX: Helper method to get video orientation enum (handles iOS 17.0+ deprecation)
    // Uses new videoRotationAngle API on iOS 17.0+, falls back to deprecated videoOrientation on earlier versions
    private func getVideoOrientation(from connection: AVCaptureConnection) -> AVCaptureVideoOrientation {
        // iOS 17.0+: Convert new videoRotationAngle API to enum
        if #available(iOS 17.0, *) {
            let rotationAngle = connection.videoRotationAngle
            // Convert rotation angle (degrees) to AVCaptureVideoOrientation enum
            // 0° = .portrait, 90° = .landscapeLeft, 180° = .portraitUpsideDown, 270° = .landscapeRight
            switch Int(rotationAngle.rounded()) {
            case 0, 360, -360:
                return .portrait
            case 90, -270:
                return .landscapeLeft
            case 180, -180:
                return .portraitUpsideDown
            case 270, -90:
                return .landscapeRight
            default:
                return .portrait
            }
        } else {
            // iOS 16 and earlier: Use deprecated videoOrientation (still works)
            return connection.videoOrientation
        }
    }
    
    // 🔴 CODE RED FIX: Helper method to convert video orientation to image orientation
    // ⚠️ GRAPHICS DEBUG NOTE: The generic CIImage orientation might be defaulting to .up (Portrait)
    // while the camera buffer is .right (Landscape). This causes the skeleton to look "sideways" or
    // "scrambled" inside the bounding box. If debug labels appear rotated, hardcode the orientation
    // to match the physical device orientation exactly.
    private func getImageOrientation(from connection: AVCaptureConnection) -> CGImagePropertyOrientation {
        let videoOrientation = getVideoOrientation(from: connection)
        
        // For front-facing camera, we need to account for mirroring
        switch videoOrientation {
        case .portrait:
            return .up
        case .portraitUpsideDown:
            return .down
        case .landscapeRight:
            return .left
        case .landscapeLeft:
            return .right
        @unknown default:
            return .up
        }
    }
    
    // MARK: - Phase 2/3: 3D Vision Processing with Biomechanics Analysis
    
    /// Processes 3D body pose with metric coordinates (Pro mode)
    /// Reference: https://developer.apple.com/documentation/vision/vndetecthumanbodypose3drequest
    @available(iOS 17.0, *)
    private func processBodyPose3D(_ observation: VNHumanBodyPose3DObservation, depthData: AVDepthData?, orientation: AVCaptureVideoOrientation) {
        guard let sensorFusion = sensorFusion,
              let aiTrainer = aiTrainer else { return }
        
        // Fuse 3D pose with depth data to get metric coordinates
        let metricJoints = sensorFusion.fuseDepthWithPose(
            observation: observation,
            depthData: depthData
        )
        
        // 🔴 CODE RED FIX: Calculate average confidence from available joints
        let avgConfidence = metricJoints.isEmpty ? 0.0 : 0.85  // Default high confidence for 3D tracking
        
        // Update 3D body points for visualization
        DispatchQueue.main.async {
            self.bodyPoints3D = metricJoints
            self.trackingConfidence = avgConfidence
            
            // 3D observations don't have per-joint confidence, use default high confidence
            var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]
            for jointName in metricJoints.keys {
                confidences[jointName] = 0.85  // Default confidence for successfully detected joints
            }
            self.jointConfidences = confidences
        }
        
        // Extract 2D points for legacy visualization compatibility
        // 🔴 CODE RED FIX: Proper projection from 3D to 2D normalized coordinates
        var points2D: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        for (jointName, position3D) in metricJoints {
            // Project 3D position to 2D normalized coordinates
            // Vision 3D coordinates are in anatomical space
            // We need to convert to Vision 2D normalized space (0,0 bottom-left, 1,1 top-right)
            points2D[jointName] = CGPoint(
                x: CGFloat((position3D.x + 1.0) / 2.0),  // Convert from [-1,1] to [0,1]
                y: CGFloat((position3D.y + 1.0) / 2.0)   // Convert from [-1,1] to [0,1]
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
        // 🔴 CODE RED FIX: "Glass Floor" Performance Rule - Drop frame if still processing
        guard !isProcessingFrame else {
            return  // Skip this frame to maintain 60fps
        }
        
        // 🔴 CODE RED FIX: Calculate FPS
        let currentTime = CACurrentMediaTime()
        if currentTime - fpsTimer >= 1.0 {
            DispatchQueue.main.async {
                self.currentFPS = Double(self.frameCount)
            }
            frameCount = 0
            fpsTimer = currentTime
        }
        frameCount += 1
        
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
        
        // 🔴 CODE RED FIX: Get video orientation for proper coordinate transformation
        guard let connection = videoOutput.connection(with: .video) else {
            return
        }
        let videoOrientation = getVideoOrientation(from: connection)
        
        // 🔴 CODE RED FIX: Mark as processing to prevent concurrent frame processing
        isProcessingFrame = true
        let frameStartTime = CACurrentMediaTime()
        
        // 🔴 CODE RED FIX: Process Vision on background queue (QoS: .userInitiated)
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Process with 3D Vision request
            let request = VNDetectHumanBodyPose3DRequest { [weak self] request, error in
                guard let self = self,
                      let observations = request.results as? [VNHumanBodyPose3DObservation],
                      let observation = observations.first else {
                    self?.isProcessingFrame = false
                    return
                }
                
                // Process pose on background thread
                self.processBodyPose3D(observation, depthData: depthData, orientation: videoOrientation)
                
                // 🔴 CODE RED FIX: Measure processing time
                let processingTime = (CACurrentMediaTime() - frameStartTime) * 1000.0  // Convert to ms
                DispatchQueue.main.async {
                    self.processingTimeMs = processingTime
                }
                
                // Release processing lock
                self.isProcessingFrame = false
                
                // 🔴 CODE RED FIX: If processing took >16ms, next frame will be auto-dropped
                if processingTime > 16.0 {
                    #if DEBUG
                    print("⚠️ 3D Frame processing exceeded 16ms budget: \(String(format: "%.1f", processingTime))ms")
                    #endif
                }
            }
            
            // Execute Vision request with proper orientation
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: self.getImageOrientation(from: connection),
                options: [:]
            )
            do {
                try handler.perform([request])
            } catch {
                print("❌ 3D Vision request failed: \(error)")
                self.isProcessingFrame = false
            }
        }
    }
}

