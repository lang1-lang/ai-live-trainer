//
//  ARBodyOverlayView.swift
//  AI Live Trainer System
//
//  🔴 CODE RED FIX: Coordinate transformation fixed
//  Reference: VNImagePointForNormalizedPoint conversion
//

import SwiftUI
import Vision

struct ARBodyOverlayView: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let formCorrect: Bool
    
    // 🔴 CODE RED FIX: Add debug mode support
    var isDebugMode: Bool = false
    
    var body: some View {
        // Color-coded wireframe (green/red) or debug yellow dots
        Canvas { context, size in
            // 🔴 CODE RED FIX: Debug mode shows raw yellow dots only
            if isDebugMode {
                drawDebugPoints(context: context, size: size)
            } else {
                drawNormalSkeleton(context: context, size: size)
            }
        }
    }
    
    // 🔴 CODE RED FIX: Raw debug visualization (no smoothing, no physics)
    private func drawDebugPoints(context: GraphicsContext, size: CGSize) {
        for (_, normalizedPoint) in bodyPoints {
            // Convert Vision normalized coordinates to screen coordinates
            // Vision coordinates: (0,0) = bottom-left, (1,1) = top-right
            // UIKit coordinates: (0,0) = top-left, (width,height) = bottom-right
            let screenPoint = normalizedToScreen(normalizedPoint, size: size)
            
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
    
    private func drawNormalSkeleton(context: GraphicsContext, size: CGSize) {
        let wireframeColor = formCorrect ? Color.green : Color.red
        
        // Draw skeleton connections
        let connections = BodyWireframe.jointConnections
        
        for connection in connections {
            if let startPoint = bodyPoints[connection.start],
               let endPoint = bodyPoints[connection.end] {
                
                // 🔴 CODE RED FIX: Proper coordinate transformation
                let start = normalizedToScreen(startPoint, size: size)
                let end = normalizedToScreen(endPoint, size: size)
                
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                
                context.stroke(
                    path,
                    with: .color(wireframeColor.opacity(0.7)),
                    lineWidth: 4
                )
            }
        }
        
        // Draw joints
        for (_, normalizedPoint) in bodyPoints {
            let screenPoint = normalizedToScreen(normalizedPoint, size: size)
            
            let circle = Path { path in
                path.addEllipse(in: CGRect(
                    x: screenPoint.x - 8,
                    y: screenPoint.y - 8,
                    width: 16,
                    height: 16
                ))
            }
            
            context.fill(circle, with: .color(wireframeColor))
            context.stroke(circle, with: .color(.white), lineWidth: 2)
        }
    }
    
    // 🔴 CODE RED FIX: Robust coordinate transformation from Vision normalized to screen coordinates
    /// Converts Vision normalized coordinates to UIKit screen coordinates
    /// Vision: (0,0) = bottom-left, (1,1) = top-right
    /// UIKit: (0,0) = top-left, (width,height) = bottom-right
    private func normalizedToScreen(_ normalized: CGPoint, size: CGSize) -> CGPoint {
        return CGPoint(
            x: normalized.x * size.width,
            y: (1.0 - normalized.y) * size.height  // Flip Y-axis
        )
    }
}

struct BodyWireframe {
    struct JointConnection {
        let start: VNHumanBodyPoseObservation.JointName
        let end: VNHumanBodyPoseObservation.JointName
    }
    
    static let jointConnections: [JointConnection] = [
        // Spine
        JointConnection(start: .neck, end: .root),
        
        // Left arm
        JointConnection(start: .neck, end: .leftShoulder),
        JointConnection(start: .leftShoulder, end: .leftElbow),
        JointConnection(start: .leftElbow, end: .leftWrist),
        
        // Right arm
        JointConnection(start: .neck, end: .rightShoulder),
        JointConnection(start: .rightShoulder, end: .rightElbow),
        JointConnection(start: .rightElbow, end: .rightWrist),
        
        // Left leg
        JointConnection(start: .root, end: .leftHip),
        JointConnection(start: .leftHip, end: .leftKnee),
        JointConnection(start: .leftKnee, end: .leftAnkle),
        
        // Right leg
        JointConnection(start: .root, end: .rightHip),
        JointConnection(start: .rightHip, end: .rightKnee),
        JointConnection(start: .rightKnee, end: .rightAnkle)
    ]
}

