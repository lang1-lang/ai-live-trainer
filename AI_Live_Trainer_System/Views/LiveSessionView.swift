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
    
    var body: some View {
        ZStack {
            // Camera Feed Layer
            CameraFeedView(sessionManager: sessionManager)
                .ignoresSafeArea()
            
            // AR Overlay Layer
            if sessionManager.isTracking {
                ARBodyOverlayView(
                    bodyPoints: sessionManager.bodyPoints,
                    formCorrect: sessionManager.isFormCorrect
                )
                .ignoresSafeArea()
            }
            
            // HUD Stats Layer
            VStack {
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
}

#Preview {
    LiveSessionView(workout: WorkoutModel.sampleWorkouts()[0])
}

