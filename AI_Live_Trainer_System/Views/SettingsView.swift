//
//  SettingsView.swift
//  AI Live Trainer System
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("voiceFeedbackEnabled") private var voiceFeedbackEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Feedback")) {
                    Toggle(isOn: $voiceFeedbackEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Voice Coaching")
                        }
                    }
                    .onChange(of: voiceFeedbackEnabled) { value in
                        VoiceFeedbackManager.shared.setEnabled(value)
                    }
                    
                    Toggle(isOn: $hapticFeedbackEnabled) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Haptic Feedback")
                        }
                    }
                }
                
                Section(header: Text("Demo Mode")) {
                    Button(action: {
                        DemoModeManager.shared.startDemo(scenario: .perfectForm)
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            Text("Perfect Form Demo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        DemoModeManager.shared.startDemo(scenario: .needsCorrection)
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("Correction Demo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        DemoModeManager.shared.prepareForAppStoreScreenshots()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Screenshot Mode")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                Section(header: Text("About")) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("About AI Trainer")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    Text("AI Live Trainer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("AI Live Trainer uses advanced computer vision and machine learning to provide real-time feedback on your exercise form. Train smarter, prevent injuries, and achieve better results.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("Technology")
                            .font(.headline)
                        
                        FeatureRow(icon: "eye.fill", title: "Vision Framework", description: "Body pose detection")
                        FeatureRow(icon: "arkit", title: "ARKit", description: "Real-time 3D tracking")
                        FeatureRow(icon: "cpu", title: "CoreML", description: "On-device AI processing")
                        FeatureRow(icon: "waveform", title: "Speech Synthesis", description: "Voice coaching")
                        
                        Divider()
                        
                        Text("Privacy")
                            .font(.headline)
                        
                        Text("All processing happens on-device. Your workout data never leaves your iPhone or iPad.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}

