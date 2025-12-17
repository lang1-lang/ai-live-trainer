//
//  ARBodyOverlayView.swift
//  AI Live Trainer System
//
//  ⚠️ LEGACY CODE - PHASE 1 DEPRECATION NOTICE
//  This file contains simple 2D wireframe rendering.
//  Being replaced with depth-aware rendering in DepthAwareSkeletonView.swift
//  Reference: AXIS LABS Engine 2.0 Overhaul Plan - Phase 4
//

import SwiftUI
import Vision

struct ARBodyOverlayView: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let formCorrect: Bool
    
    var body: some View {
        // LEGACY: Simple color-coded wireframe (green/red)
        // REPLACEMENT: DepthAwareSkeletonView.swift with Z-depth gradient (Phase 4)
        Canvas { context, size in
            let wireframeColor = formCorrect ? Color.green : Color.red
            
            // Draw skeleton connections
            let connections = BodyWireframe.jointConnections
            
            for connection in connections {
                if let startPoint = bodyPoints[connection.start],
                   let endPoint = bodyPoints[connection.end] {
                    
                    // Convert normalized points to screen coordinates
                    let start = CGPoint(
                        x: startPoint.x * size.width,
                        y: (1 - startPoint.y) * size.height
                    )
                    let end = CGPoint(
                        x: endPoint.x * size.width,
                        y: (1 - endPoint.y) * size.height
                    )
                    
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
            for (_, point) in bodyPoints {
                let screenPoint = CGPoint(
                    x: point.x * size.width,
                    y: (1 - point.y) * size.height
                )
                
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

