//
//  LiveSessionView.swift
//  AI Live Trainer System
//

import SwiftUI
import AVFoundation

struct LiveSessionView: View {
    let workout: WorkoutModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = LiveSessionManager()
    @State private var showingExitAlert = false
    @State private var showingPostWorkout = false
    @State private var showInfoBanner = true
    
    var body: some View {
        ZStack {
            // Camera Feed Layer
            CameraFeedView(sessionManager: sessionManager)
                .ignoresSafeArea()
            
            // AR Overlay Layer - Phase 4: Use depth-aware visualization if in Pro mode
            if sessionManager.isTracking {
                if sessionManager.deviceMode == .pro && !sessionManager.bodyPoints3D.isEmpty {
                    // Pro mode: Depth-aware skeleton with 3D positions
                    DepthAwareSkeletonView(
                        joints3D: sessionManager.bodyPoints3D,
                        confidences: extractConfidences(from: sessionManager.bodyPoints3D),
                        formCorrect: sessionManager.isFormCorrect,
                        metricOverlays: nil  // Can add metric overlays here
                    )
                    .ignoresSafeArea()
                } else {
                    // Standard mode: Legacy 2D wireframe
                    ARBodyOverlayView(
                        bodyPoints: sessionManager.bodyPoints,
                        formCorrect: sessionManager.isFormCorrect
                    )
                    .ignoresSafeArea()
                }
            }
            
            // HUD Stats Layer
            VStack {
                // NEW: Info Banner (shows for first 8 seconds)
                if showInfoBanner && sessionManager.isTracking {
                    VStack(spacing: 8) {
                        if sessionManager.deviceMode == .pro {
                            HStack {
                                Image(systemName: "laser.burst")
                                    .foregroundColor(.green)
                                Text("LiDAR Active: Military-Grade Precision")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: { showInfoBanner = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.blue)
                                Text("Standard Mode: High-Quality Analysis")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: { showInfoBanner = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
                
                // Top HUD
                HStack {
                    Button(action: {
                        showingExitAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Phase 4: Show mode badge
                        if sessionManager.deviceMode == .pro {
                            HStack(spacing: 4) {
                                Image(systemName: "laser.burst")
                                    .font(.system(size: 8))
                                Text("PRO")
                                    .font(.system(size: 10, weight: .black))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                        }
                        
                        Text("Set \(sessionManager.currentSet)/\(workout.setCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(sessionManager.currentExercise)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding()
                
                Spacer()
                
                // Bottom HUD
                HStack(spacing: 40) {
                    // Rep Counter
                    VStack(spacing: 4) {
                        Text("\(sessionManager.currentRep)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text("REPS")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    
                    // Timer
                    VStack(spacing: 4) {
                        Text(sessionManager.formattedTime)
                            .font(.system(size: 32, weight: .semibold, design: .monospaced))
                        Text("TIME")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .padding(.bottom, 40)
                
                // Live Feedback Text
                if !sessionManager.liveFeedback.isEmpty {
                    Text(sessionManager.liveFeedback)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule()
                                .fill(sessionManager.isFormCorrect ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        )
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            sessionManager.startSession(workout: workout)
            
            // Auto-hide info banner after 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation {
                    showInfoBanner = false
                }
            }
        }
        .onDisappear {
            sessionManager.endSession()
        }
        .alert("End Workout?", isPresented: $showingExitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                sessionManager.endSession()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this workout?")
        }
        .onChange(of: sessionManager.workoutCompleted) {
            if sessionManager.workoutCompleted {
                showingPostWorkout = true
            }
        }
        .fullScreenCover(isPresented: $showingPostWorkout) {
            PostWorkoutView(session: sessionManager.createWorkoutSession())
        }
    }
    
    // MARK: - Helper Functions
    
    /// Extracts confidence scores from session manager
    /// 3D observations don't have per-joint confidence, so we use defaults
    private func extractConfidences(
        from joints: [VNHumanBodyPoseObservation.JointName: simd_float3]
    ) -> [VNHumanBodyPoseObservation.JointName: Float] {
        // Use confidence values from session manager if available
        if !sessionManager.jointConfidences.isEmpty {
            return sessionManager.jointConfidences
        }
        
        // Fallback: default confidence for all joints
        var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]
        for jointName in joints.keys {
            confidences[jointName] = 0.85  // Default high confidence
        }
        return confidences
    }
}

// Import Vision and simd for types
import Vision

#Preview {
    LiveSessionView(workout: WorkoutModel.sampleWorkouts()[0])
}

