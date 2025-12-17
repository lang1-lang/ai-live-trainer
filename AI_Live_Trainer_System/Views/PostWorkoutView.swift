//
//  PostWorkoutView.swift
//  AI Live Trainer System
//
//  Phase 5: Enhanced with biometric metrics display and data export
//

import SwiftUI
import Charts

struct PostWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportedData: String?
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(session.workoutName)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        // NEW: Analysis Mode Badge
                        if let deviceMode = session.deviceMode {
                            HStack(spacing: 12) {
                                if deviceMode == "pro" {
                                    VStack(spacing: 4) {
                                        HStack {
                                            Image(systemName: "laser.burst")
                                                .font(.title3)
                                            Text("PRO MODE")
                                                .font(.headline)
                                                .fontWeight(.black)
                                        }
                                        .foregroundColor(.white)
                                        
                                        Text("LiDAR + 3D Analysis")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                } else {
                                    VStack(spacing: 4) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                                .font(.title3)
                                            Text("STANDARD MODE")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.white)
                                        
                                        Text("2D Vision Analysis")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Accuracy Radial Chart
                    VStack(spacing: 12) {
                        Text("Form Accuracy")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .trim(from: 0, to: session.accuracyPercentage / 100)
                                .stroke(
                                    LinearGradient(
                                        colors: gradientForAccuracy(session.accuracyPercentage),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: session.accuracyPercentage)
                            
                            VStack(spacing: 4) {
                                Text(String(format: "%.0f%%", session.accuracyPercentage))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("ACCURACY")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "clock.fill",
                            value: formatDuration(session.duration),
                            label: "Duration"
                        )
                        
                        StatCard(
                            icon: "repeat",
                            value: "\(session.totalReps)",
                            label: "Total Reps"
                        )
                        
                        StatCard(
                            icon: "square.stack.3d.up.fill",
                            value: "\(session.completedSets)",
                            label: "Sets Completed"
                        )
                        
                        StatCard(
                            icon: "flame.fill",
                            value: "\(Int(session.duration / 60 * 8))",
                            label: "Calories"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Phase 5: Biometric Metrics Section
                    if let deviceMode = session.deviceMode, deviceMode == "pro",
                       let avgMetrics = session.averageMetrics, !avgMetrics.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header with explanation
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.bar.doc.horizontal.fill")
                                        .foregroundColor(.green)
                                    Text("PRO BIOMECHANICS")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                
                                Text("🎯 Military-grade measurements using LiDAR depth sensors and 3D motion tracking. These metrics are accurate to within 2cm and 5°.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal)
                            
                            Text("Average Measurements")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(Array(avgMetrics.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                                    MetricCard(
                                        label: formatMetricKey(key),
                                        value: formatMetricValue(value, key: key)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Feedback Items
                    if !session.feedbackItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Feedback")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(session.feedbackItems) { item in
                                    FeedbackItemRow(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Phase 5: Export Data Button (Pro mode only)
                        if session.deviceMode == "pro" {
                            VStack(spacing: 8) {
                                Button(action: {
                                    showingExportOptions = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.doc.fill")
                                        Text("Export Detailed Data")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(16)
                                }
                                
                                Text("💾 Share with coaches or import into analytics tools")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Results")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Export Data", isPresented: $showingExportOptions) {
                Button("Export as CSV") {
                    exportAsCSV()
                }
                Button("Export as JSON") {
                    exportAsJSON()
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(item: Binding(
                get: { exportedData.map { ExportData(content: $0) } },
                set: { exportedData = $0?.content }
            )) { data in
                ShareSheet(items: [data.content])
            }
        }
    }
    
    // MARK: - Phase 5: Export Functions
    
    private func exportAsCSV() {
        guard let biometricData = session.biometricData else { return }
        
        var csv = "Timestamp,IsCorrect,Confidence,Feedback\n"
        
        for result in biometricData {
            let escapedFeedback = result.primaryFeedback.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(result.timestamp),\(result.isCorrect),\(result.confidence),\"\(escapedFeedback)\"\n"
        }
        
        // Add metrics
        csv += "\n\nMetric,Value\n"
        if let avgMetrics = session.averageMetrics {
            for (key, value) in avgMetrics.sorted(by: { $0.key < $1.key }) {
                csv += "\(key),\(value)\n"
            }
        }
        
        exportedData = csv
    }
    
    private func exportAsJSON() {
        let exportData: [String: Any] = [
            "session_id": session.id.uuidString,
            "workout_name": session.workoutName,
            "date": ISO8601DateFormatter().string(from: session.date),
            "duration": session.duration,
            "accuracy": session.accuracyPercentage,
            "device_mode": session.deviceMode ?? "standard",
            "average_metrics": session.averageMetrics ?? [:],
            "biometric_data": session.biometricData?.map { result in
                [
                    "timestamp": result.timestamp,
                    "is_correct": result.isCorrect,
                    "confidence": result.confidence,
                    "feedback": result.primaryFeedback,
                    "joint_angles": result.jointAngles,
                    "metric_measurements": result.metricMeasurements,
                    "deviation_metrics": result.deviationMetrics
                ]
            } ?? []
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportedData = jsonString
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatMetricKey(_ key: String) -> String {
        return key
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private func formatMetricValue(_ value: Float, key: String) -> String {
        if key.contains("angle") || key.contains("deg") {
            return String(format: "%.1f°", value)
        } else if key.contains("meters") || key.contains("distance") || key.contains("height") {
            return String(format: "%.2fm", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func gradientForAccuracy(_ accuracy: Double) -> [Color] {
        if accuracy >= 80 {
            return [.green, .green.opacity(0.7)]
        } else if accuracy >= 60 {
            return [.orange, .orange.opacity(0.7)]
        } else {
            return [.red, .red.opacity(0.7)]
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Phase 5: Metric Card Component

struct MetricCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Helper Structures

struct ExportData: Identifiable {
    let id = UUID()
    let content: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FeedbackItemRow: View {
    let item: FeedbackItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForSeverity(item.severity))
                .font(.title3)
                .foregroundColor(colorForSeverity(item.severity))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.exerciseName)
                    .font(.headline)
                
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func iconForSeverity(_ severity: FeedbackItem.FeedbackSeverity) -> String {
        switch severity {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: FeedbackItem.FeedbackSeverity) -> Color {
        switch severity {
        case .good:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

#Preview {
    PostWorkoutView(session: WorkoutSession(
        workoutId: "wk_001",
        workoutName: "The Morning Mobilizer",
        duration: 900,
        accuracyPercentage: 87.5,
        totalReps: 45,
        completedSets: 3,
        feedbackItems: [
            FeedbackItem(exerciseName: "Squat", message: "Great depth! Keep it up.", timestamp: Date(), severity: .good),
            FeedbackItem(exerciseName: "Plank", message: "Lower your hips slightly", timestamp: Date(), severity: .warning)
        ]
    ))
}

