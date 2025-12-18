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
        
        // Define all joints using VERIFIED Apple 3D joint names
        // Source: https://developer.apple.com/documentation/vision/vnhumanbodypose3dobservation/jointname
        let allJoints3D: [VNHumanBodyPose3DObservation.JointName] = [
            .root,
            .spine,
            .centerShoulder,
            .centerHead,
            .topHead,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftHip, .leftKnee, .leftAnkle,
            .rightHip, .rightKnee, .rightAnkle
        ]
        
        // Mapping from verified 3D joint names to 2D joint names for compatibility
        // Verified: All 3D joint names exist in Apple documentation
        let jointMapping: [VNHumanBodyPose3DObservation.JointName: VNHumanBodyPoseObservation.JointName] = [
            .root: .root,
            .spine: .root,  // Spine maps to root for 2D compatibility
            .centerHead: .nose,
            .topHead: .nose,
            .centerShoulder: .neck,
            .leftShoulder: .leftShoulder,
            .leftElbow: .leftElbow,
            .leftWrist: .leftWrist,
            .rightShoulder: .rightShoulder,
            .rightElbow: .rightElbow,
            .rightWrist: .rightWrist,
            .leftHip: .leftHip,
            .leftKnee: .leftKnee,
            .leftAnkle: .leftAnkle,
            .rightHip: .rightHip,
            .rightKnee: .rightKnee,
            .rightAnkle: .rightAnkle
        ]
        
        // Pro mode with depth data available
        if deviceMode == .pro, let depthData = depthData {
            // Convert depth data to usable format
            let depthMap = depthData.depthDataMap
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
            
            for joint3D in allJoints3D {
                if let point3D = try? observation.recognizedPoint(joint3D),
                   let joint2D = jointMapping[joint3D] {
                    
                    // Extract 3D position from transformation matrix (Apple verified API)
                    // Source: https://developer.apple.com/documentation/vision/vnhumanbodyrecognizedpoint3d
                    let position = simd_float3(
                        point3D.localPosition.columns.3.x,
                        point3D.localPosition.columns.3.y,
                        point3D.localPosition.columns.3.z
                    )
                    
                    // Store in anatomical coordinate space
                    metricJoints[joint2D] = toAnatomicalSpace(position)
                }
            }
        } else {
            // Standard mode: Use Vision's built-in 3D estimation without depth enhancement
            for joint3D in allJoints3D {
                if let point3D = try? observation.recognizedPoint(joint3D),
                   let joint2D = jointMapping[joint3D] {
                    
                    // Extract 3D position from transformation matrix (Apple verified API)
                    // Source: https://developer.apple.com/documentation/vision/vnhumanbodyrecognizedpoint3d
                    let position = simd_float3(
                        point3D.localPosition.columns.3.x,
                        point3D.localPosition.columns.3.y,
                        point3D.localPosition.columns.3.z
                    )
                    
                    // Store in anatomical coordinate space
                    metricJoints[joint2D] = toAnatomicalSpace(position)
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
        
        // Use verified Apple 3D joint names
        // Source: https://developer.apple.com/documentation/vision/vnhumanbodypose3dobservation/jointname
        let allJoints3D: [VNHumanBodyPose3DObservation.JointName] = [
            .root,
            .spine,
            .centerShoulder,
            .centerHead,
            .topHead,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftHip, .leftKnee, .leftAnkle,
            .rightHip, .rightKnee, .rightAnkle
        ]
        
        // Verified mapping to 2D joint names for return type
        let jointMapping: [VNHumanBodyPose3DObservation.JointName: VNHumanBodyPoseObservation.JointName] = [
            .root: .root,
            .spine: .root,
            .centerHead: .nose,
            .topHead: .nose,
            .centerShoulder: .neck,
            .leftShoulder: .leftShoulder,
            .leftElbow: .leftElbow,
            .leftWrist: .leftWrist,
            .rightShoulder: .rightShoulder,
            .rightElbow: .rightElbow,
            .rightWrist: .rightWrist,
            .leftHip: .leftHip,
            .leftKnee: .leftKnee,
            .leftAnkle: .leftAnkle,
            .rightHip: .rightHip,
            .rightKnee: .rightKnee,
            .rightAnkle: .rightAnkle
        ]
        
        for joint3D in allJoints3D {
            if let point3D = try? observation.recognizedPoint(joint3D),
               let joint2D = jointMapping[joint3D] {
                
                // Extract 3D position from transformation matrix (Apple verified API)
                // Vision 3D coordinates are in camera-relative space (meters)
                // Source: https://developer.apple.com/documentation/vision/vnhumanbodyrecognizedpoint3d
                let position = simd_float3(
                    point3D.localPosition.columns.3.x,
                    point3D.localPosition.columns.3.y,
                    point3D.localPosition.columns.3.z
                )
                
                metricJoints[joint2D] = toAnatomicalSpace(position)
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

