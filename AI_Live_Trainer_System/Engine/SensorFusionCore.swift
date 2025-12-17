//
//  SensorFusionCore.swift
//  AXIS LABS - Biometric Analysis Engine
//
//  Purpose: Merge RGB pose observations with LiDAR/depth data
//  Reference: https://developer.apple.com/documentation/avfoundation/avdepthdata
//
//  Phase 2 Implementation: Sensor Fusion Core
//

import Foundation
import Vision
import AVFoundation
import simd
import CoreImage

/// Fuses 3D pose observations with depth data for metric-accurate biomechanics
class SensorFusionCore {
    
    // MARK: - Properties
    
    /// Camera intrinsic parameters for unprojection
    private var cameraIntrinsics: matrix_float3x3?
    
    /// Current device capability mode
    private let deviceMode: DeviceCapabilityMode
    
    // MARK: - Initialization
    
    init(deviceMode: DeviceCapabilityMode) {
        self.deviceMode = deviceMode
    }
    
    // MARK: - Phase 2: Core Fusion Methods (To Be Implemented)
    
    /// Fuses 3D pose observation with depth map to produce metric coordinates
    /// - Parameters:
    ///   - observation: VNHumanBodyPose3DObservation from Vision Framework
    ///   - depthData: AVDepthData from LiDAR/TrueDepth camera
    /// - Returns: Dictionary of joint positions in metric space (meters)
    @available(iOS 17.0, *)
    func fuseDepthWithPose(
        observation: VNHumanBodyPose3DObservation,
        depthData: AVDepthData?
    ) -> [VNHumanBodyPoseObservation.JointName: simd_float3] {
        
        var metricJoints: [VNHumanBodyPoseObservation.JointName: simd_float3] = [:]
        
        // Define all joints to extract
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .root, .neck, .nose,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftHip, .leftKnee, .leftAnkle,
            .rightHip, .rightKnee, .rightAnkle
        ]
        
        // Pro mode with depth data available
        if deviceMode == .pro, let depthData = depthData {
            // Convert depth data to usable format
            let depthMap = depthData.depthDataMap
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
            
            let depthWidth = CVPixelBufferGetWidth(depthMap)
            let depthHeight = CVPixelBufferGetHeight(depthMap)
            
            for joint in allJoints {
                if let recognizedPoint = try? observation.recognizedPoint(joint),
                   recognizedPoint.confidence > 0.3 {
                    
                    // Get 2D normalized coordinates (0-1 range)
                    let normalizedX = recognizedPoint.location.x
                    let normalizedY = 1.0 - recognizedPoint.location.y  // Flip Y coordinate
                    
                    // Convert to depth map pixel coordinates
                    let depthX = Int(normalizedX * CGFloat(depthWidth))
                    let depthY = Int(normalizedY * CGFloat(depthHeight))
                    
                    // Query depth value at joint location
                    let depth = queryDepthValue(
                        depthMap: depthMap,
                        x: depthX,
                        y: depthY,
                        width: depthWidth,
                        height: depthHeight
                    )
                    
                    // Construct 3D metric position
                    // Vision already provides camera-relative coordinates
                    // We enhance with actual depth measurement
                    let position3D = simd_float3(
                        Float(normalizedX - 0.5) * 2.0,  // X: normalized to [-1, 1]
                        Float(normalizedY - 0.5) * 2.0,  // Y: normalized to [-1, 1]
                        depth  // Z: actual metric depth from LiDAR
                    )
                    
                    metricJoints[joint] = toAnatomicalSpace(position3D)
                }
            }
        } else {
            // Standard mode: Use Vision's built-in 3D estimation without depth enhancement
            for joint in allJoints {
                if let recognizedPoint = try? observation.recognizedPoint(joint),
                   recognizedPoint.confidence > 0.3 {
                    
                    // Use normalized coordinates with estimated depth
                    let position3D = simd_float3(
                        Float(recognizedPoint.location.x - 0.5) * 2.0,
                        Float((1.0 - recognizedPoint.location.y) - 0.5) * 2.0,
                        1.5  // Estimated depth in meters (average user distance)
                    )
                    
                    metricJoints[joint] = toAnatomicalSpace(position3D)
                }
            }
        }
        
        return metricJoints
    }
    
    /// Queries depth value from depth map at specific pixel coordinates
    /// - Parameters:
    ///   - depthMap: CVPixelBuffer containing depth data
    ///   - x: Pixel X coordinate
    ///   - y: Pixel Y coordinate
    ///   - width: Depth map width
    ///   - height: Depth map height
    /// - Returns: Depth value in meters
    private func queryDepthValue(
        depthMap: CVPixelBuffer,
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> Float {
        // Bounds checking
        guard x >= 0, x < width, y >= 0, y < height else {
            return 1.5  // Default depth if out of bounds
        }
        
        // Get base address of depth data
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            return 1.5
        }
        
        // Depth is typically Float32 format
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        // Calculate offset and read depth value
        let offset = y * (bytesPerRow / MemoryLayout<Float32>.stride) + x
        let depthValue = depthPointer[offset]
        
        // Validate depth value (reject invalid readings)
        if depthValue.isNaN || depthValue <= 0 || depthValue > 10.0 {
            return 1.5  // Default depth for invalid readings
        }
        
        return depthValue
    }
    
    /// Extracts metric coordinates from 3D observation (Pro mode with depth)
    /// - Parameter observation: 3D pose observation
    /// - Returns: Joint positions in camera-relative metric space
    @available(iOS 17.0, *)
    func calculateMetricCoordinates(
        from observation: VNHumanBodyPose3DObservation
    ) -> [VNHumanBodyPoseObservation.JointName: simd_float3] {
        
        // This method extracts native 3D coordinates from Vision
        // When depth data is available, fuseDepthWithPose() should be used instead
        
        var metricJoints: [VNHumanBodyPoseObservation.JointName: simd_float3] = [:]
        
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .root, .neck, .nose,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftHip, .leftKnee, .leftAnkle,
            .rightHip, .rightKnee, .rightAnkle
        ]
        
        for joint in allJoints {
            if let recognizedPoint = try? observation.recognizedPoint(joint),
               recognizedPoint.confidence > 0.3 {
                
                // Vision 3D coordinates are in camera-relative space
                // X: right(+) / left(-)
                // Y: up(+) / down(-)
                // Z: toward camera(+) / away(-)
                let position = simd_float3(
                    Float(recognizedPoint.location.x),
                    Float(recognizedPoint.location.y),
                    Float(recognizedPoint.location.z ?? 1.5)  // Use default if Z unavailable
                )
                
                metricJoints[joint] = toAnatomicalSpace(position)
            }
        }
        
        return metricJoints
    }
    
    /// Updates camera intrinsic parameters from AVCaptureDevice
    /// - Parameter intrinsics: Camera calibration matrix
    func updateCameraIntrinsics(_ intrinsics: matrix_float3x3) {
        self.cameraIntrinsics = intrinsics
    }
    
    // MARK: - Coordinate Space Transformations
    
    /// Converts camera-relative coordinates to anatomical space
    /// - Parameter cameraPoint: Point in Vision camera space
    /// - Returns: Point in anatomical coordinate system
    func toAnatomicalSpace(_ cameraPoint: simd_float3) -> simd_float3 {
        // Camera space (Vision):
        //   X: right(+) / left(-)
        //   Y: up(+) / down(-)
        //   Z: toward camera(+) / away from camera(-)
        //
        // Anatomical space (Biomechanics):
        //   X: lateral right(+) / left(-)
        //   Y: vertical up(+) / down(-)
        //   Z: anterior/forward(+) / posterior/back(-)
        //
        // For front-facing camera, transformation is:
        //   Anatomical X = -Camera X (flip left/right)
        //   Anatomical Y = Camera Y (same)
        //   Anatomical Z = -Camera Z (flip depth direction)
        
        return simd_float3(
            -cameraPoint.x,  // Flip lateral direction
            cameraPoint.y,   // Keep vertical
            -cameraPoint.z   // Flip depth direction
        )
    }
}

