//
//  DepthAwareSkeletonView.swift
//  AXIS LABS - Biometric Analysis Engine
//
//  Purpose: Enhanced skeleton visualization with depth awareness
//  Replaces: ARBodyOverlayView (legacy 2D wireframe)
//
//  Phase 4 Implementation: Depth-Aware Rendering
//

import SwiftUI
import Vision
import simd

struct DepthAwareSkeletonView: View {
    
    // MARK: - Properties
    
    /// 3D joint positions in metric space
    let joints3D: [VNHumanBodyPoseObservation.JointName: simd_float3]
    
    /// Joint confidence scores
    let confidences: [VNHumanBodyPoseObservation.JointName: Float]
    
    /// Form correctness flag
    let formCorrect: Bool
    
    /// Optional: Metric overlay data (angles, distances)
    var metricOverlays: [String: String]?
    
    // 🔴 CODE RED FIX: Add debug mode support
    var isDebugMode: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Canvas { context, size in
            // 🔴 CODE RED FIX: Debug mode shows raw yellow dots only
            if isDebugMode {
                renderDebugPoints(context: context, size: size)
            } else {
                // Render skeleton with depth-aware coloring
                renderSkeleton(context: context, size: size)
                
                // Render metric overlays if available
                if let overlays = metricOverlays {
                    renderMetricOverlays(context: context, size: size, overlays: overlays)
                }
            }
        }
    }
    
    // 🔴 CODE RED FIX: Raw debug visualization (no smoothing, no physics)
    private func renderDebugPoints(context: GraphicsContext, size: CGSize) {
        for (_, position3D) in joints3D {
            let screenPoint = project3DTo2D(joint3D: position3D, size: size)
            
            // Draw raw yellow dot
            let circle = Path { path in
                path.addEllipse(in: CGRect(
                    x: screenPoint.x - 10,
                    y: screenPoint.y - 10,
                    width: 20,
                    height: 20
                ))
            }
            
            context.fill(circle, with: .color(.yellow))
            context.stroke(circle, with: .color(.white), lineWidth: 2)
        }
    }
    
    // MARK: - Rendering Methods (Phase 4)
    
    private func renderSkeleton(context: GraphicsContext, size: CGSize) {
        // Define skeleton connections
        let connections = BodyWireframe.jointConnections
        
        // 1. Draw connections with depth-aware styling
        for connection in connections {
            guard let start3D = joints3D[connection.start],
                  let end3D = joints3D[connection.end],
                  let startConfidence = confidences[connection.start],
                  let endConfidence = confidences[connection.end],
                  startConfidence > 0.3,
                  endConfidence > 0.3 else {
                continue
            }
            
            // Project 3D joints to 2D screen space
            let startPoint = project3DTo2D(joint3D: start3D, size: size)
            let endPoint = project3DTo2D(joint3D: end3D, size: size)
            
            // Calculate average depth and confidence for this connection
            let avgDepth = (start3D.z + end3D.z) / 2.0
            let avgConfidence = (startConfidence + endConfidence) / 2.0
            
            // Get depth-aware color
            let lineColor = depthToColor(depth: avgDepth)
                .opacity(Double(avgConfidence))
            
            // Draw connection line
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            // Line width varies with depth (closer = thicker)
            let lineWidth = depthToLineWidth(depth: avgDepth)
            
            context.stroke(
                path,
                with: .color(lineColor),
                lineWidth: lineWidth
            )
        }
        
        // 2. Draw joints with confidence-based sizing
        for (jointName, position3D) in joints3D {
            guard let confidence = confidences[jointName],
                  confidence > 0.3 else {
                continue
            }
            
            let screenPoint = project3DTo2D(joint3D: position3D, size: size)
            
            // Joint color based on depth
            let jointColor = depthToColor(depth: position3D.z)
                .opacity(Double(confidence))
            
            // Joint size based on confidence (higher confidence = larger)
            let jointRadius = CGFloat(6.0 + (Double(confidence) * 6.0))
            
            let circle = Path { path in
                path.addEllipse(in: CGRect(
                    x: screenPoint.x - jointRadius,
                    y: screenPoint.y - jointRadius,
                    width: jointRadius * 2,
                    height: jointRadius * 2
                ))
            }
            
            // Fill joint
            context.fill(circle, with: .color(jointColor))
            
            // Add white border for visibility
            context.stroke(
                circle,
                with: .color(.white.opacity(Double(confidence))),
                lineWidth: 2
            )
        }
    }
    
    private func renderMetricOverlays(
        context: GraphicsContext,
        size: CGSize,
        overlays: [String: String]
    ) {
        // Render metric text overlays in top-left corner
        var yOffset: CGFloat = 40
        
        for (key, value) in overlays.sorted(by: { $0.key < $1.key }) {
            let displayText = "\(formatMetricKey(key)): \(value)"
            
            // Create text
            let text = Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            
            // Resolve text for rendering
            let resolvedText = context.resolve(text)
            
            // Draw with background
            let textRect = CGRect(
                x: 10,
                y: yOffset,
                width: 200,
                height: 20
            )
            
            // Semi-transparent background
            context.fill(
                Path(roundedRect: textRect.insetBy(dx: -4, dy: -2), cornerRadius: 4),
                with: .color(.black.opacity(0.6))
            )
            
            // Draw text
            context.draw(
                resolvedText,
                at: CGPoint(x: textRect.minX, y: textRect.midY),
                anchor: .leading
            )
            
            yOffset += 25
        }
    }
    
    /// Formats metric key for display
    private func formatMetricKey(_ key: String) -> String {
        return key
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    /// Maps Z-depth to color using HSV gradient
    /// - Parameter depth: Z-coordinate in meters (absolute value)
    /// - Returns: Color with depth encoding
    private func depthToColor(depth: Float) -> Color {
        // Use absolute depth for color mapping
        let absDepth = abs(depth)
        
        // If form is incorrect, override with red
        if !formCorrect {
            return .red
        }
        
        // Depth-based color gradient:
        // Near (0.5-1.2m): Bright green (most accurate tracking)
        // Mid (1.2-2.0m): Yellow-green
        // Far (2.0-3.0m): Blue
        // Very far (>3.0m): Purple (less reliable)
        
        let hue: Double
        let saturation: Double = 0.8
        let brightness: Double
        
        if absDepth < 1.2 {
            // Near: Bright green
            hue = 0.33  // Green
            brightness = 0.9
        } else if absDepth < 2.0 {
            // Mid: Yellow-green transition
            let t = Double(absDepth - 1.2) / 0.8
            hue = 0.33 - (t * 0.16)  // Green → Yellow
            brightness = 0.85
        } else if absDepth < 3.0 {
            // Far: Blue
            let t = Double(absDepth - 2.0) / 1.0
            hue = 0.17 - (t * 0.5)  // Yellow → Blue
            brightness = 0.75
        } else {
            // Very far: Purple (warning)
            hue = 0.75  // Purple
            brightness = 0.65
        }
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    /// Maps depth to line width (closer = thicker)
    /// - Parameter depth: Z-coordinate in meters
    /// - Returns: Line width in points
    private func depthToLineWidth(depth: Float) -> CGFloat {
        let absDepth = abs(depth)
        
        // Closer objects get thicker lines for visual depth cue
        if absDepth < 1.5 {
            return CGFloat(5.0)
        } else if absDepth < 2.5 {
            return CGFloat(4.0)
        } else {
            return CGFloat(3.0)
        }
    }
    
    // 🔴 CODE RED FIX: Robust 3D to 2D projection with proper coordinate transformation
    /// Projects 3D joint to 2D screen coordinates
    /// - Parameters:
    ///   - joint3D: 3D position in metric space (anatomical coordinates)
    ///   - size: Canvas size
    /// - Returns: 2D screen coordinate
    private func project3DTo2D(joint3D: simd_float3, size: CGSize) -> CGPoint {
        // Vision 3D anatomical space:
        //   X: lateral (-1 left, +1 right)
        //   Y: vertical (-1 down, +1 up)
        //   Z: depth (negative = toward camera, positive = away)
        //
        // UIKit screen space:
        //   X: 0 left, width right
        //   Y: 0 top, height bottom
        //
        // Transformation:
        //   1. Normalize anatomical [-1,1] to [0,1]
        //   2. Flip Y-axis (Vision Y+ is up, UIKit Y+ is down)
        //   3. Scale to screen size
        
        // Normalize X from [-1,1] to [0,1]
        let normalizedX = CGFloat((joint3D.x + 1.0) * 0.5)
        
        // Normalize Y from [-1,1] to [0,1], then flip for UIKit
        let normalizedY = CGFloat((joint3D.y + 1.0) * 0.5)
        let flippedY = 1.0 - normalizedY
        
        // Scale to screen size
        let screenX = normalizedX * size.width
        let screenY = flippedY * size.height
        
        return CGPoint(x: screenX, y: screenY)
    }
}

// MARK: - Preview Provider

struct DepthAwareSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        DepthAwareSkeletonView(
            joints3D: [:],
            confidences: [:],
            formCorrect: true,
            metricOverlays: [
                "knee_angle": "87°",
                "squat_depth": "0.45m"
            ]
        )
        .frame(width: 400, height: 600)
        .background(Color.black)
    }
}

