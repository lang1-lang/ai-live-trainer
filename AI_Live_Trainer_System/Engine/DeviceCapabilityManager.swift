//
//  DeviceCapabilityManager.swift
//  AXIS LABS - Biometric Analysis Engine
//
//  Purpose: Runtime detection of LiDAR/Depth camera capabilities
//  Reference: https://developer.apple.com/documentation/avfoundation/capturing-depth-using-the-lidar-camera
//

import Foundation
import AVFoundation
import UIKit

/// Device capability modes for sensor fusion
enum DeviceCapabilityMode: String {
    case pro       // LiDAR available (iPhone 12 Pro+, iPad Pro 2020+)
    case standard  // No LiDAR (fallback to 2D Vision)
    
    var displayName: String {
        switch self {
        case .pro: return "AXIS LABS PRO"
        case .standard: return "AXIS LABS Standard"
        }
    }
    
    var description: String {
        switch self {
        case .pro: return "Military-Grade Precision (LiDAR + 3D Vision)"
        case .standard: return "High-Quality Analysis (2D Vision)"
        }
    }
}

/// Detects hardware capabilities for optimal sensor fusion configuration
class DeviceCapabilityManager {
    
    // MARK: - Singleton
    
    static let shared = DeviceCapabilityManager()
    
    // MARK: - Properties
    
    /// Current device capability mode
    private(set) var mode: DeviceCapabilityMode = .standard
    
    /// LiDAR availability flag
    var hasLiDAR: Bool {
        return mode == .pro
    }
    
    /// Device model identifier
    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    /// User-friendly device name
    var deviceName: String {
        return UIDevice.current.name
    }
    
    // MARK: - Initialization
    
    private init() {
        detectCapability()
    }
    
    // MARK: - Detection
    
    /// Detects device capability mode based on LiDAR/depth camera availability
    /// Reference: https://developer.apple.com/documentation/avfoundation/avdepthdata
    func detectCapability() {
        // Check for depth data output support
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInLiDARDepthCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back
        )
        
        // LiDAR scanner is available on back camera of Pro devices
        let hasBackLiDAR = discoverySession.devices.contains { device in
            device.deviceType == .builtInLiDARDepthCamera
        }
        
        // Alternative: Check front TrueDepth for depth capability
        let frontDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera],
            mediaType: .video,
            position: .front
        )
        
        let hasFrontDepth = frontDiscoverySession.devices.contains { device in
            device.deviceType == .builtInTrueDepthCamera &&
            device.activeFormat.supportedDepthDataFormats.isEmpty == false
        }
        
        // Pro mode requires LiDAR or TrueDepth with depth support
        if hasBackLiDAR || hasFrontDepth {
            mode = .pro
            print("✅ AXIS LABS PRO Mode: LiDAR/Depth camera detected")
            print("   Device: \(deviceModel)")
            print("   Capabilities: 3D Vision + Metric Depth Fusion")
        } else {
            mode = .standard
            print("ℹ️ AXIS LABS Standard Mode: No depth camera detected")
            print("   Device: \(deviceModel)")
            print("   Capabilities: 2D Vision (High-Quality)")
        }
    }
    
    // MARK: - Depth Device Access
    
    /// Returns the appropriate depth-capable device for the current mode
    /// - Parameter position: Camera position (front/back)
    /// - Returns: AVCaptureDevice with depth capability, or nil if unavailable
    func getDepthCapableDevice(position: AVCaptureDevice.Position = .front) -> AVCaptureDevice? {
        guard mode == .pro else { return nil }
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = position == .back ?
            [.builtInLiDARDepthCamera, .builtInDualCamera] :
            [.builtInTrueDepthCamera]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
        
        // Find device with depth data format support
        return discoverySession.devices.first { device in
            !device.activeFormat.supportedDepthDataFormats.isEmpty
        }
    }
    
    /// Checks if specific depth data format is available
    /// - Parameter device: AVCaptureDevice to check
    /// - Returns: Best depth format, or nil if unavailable
    func getBestDepthFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        return device.activeFormat.supportedDepthDataFormats.first
    }
    
    // MARK: - System Requirements
    
    /// Minimum iOS version for 3D Vision (iOS 17+)
    var supportsVision3D: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }
    
    /// Check if all requirements for Pro mode are met
    var canRunProMode: Bool {
        return hasLiDAR && supportsVision3D
    }
    
    // MARK: - Debug Info
    
    /// Comprehensive system capability report
    func printSystemReport() {
        print("\n" + String(repeating: "=", count: 60))
        print("AXIS LABS - System Capability Report")
        print(String(repeating: "=", count: 60))
        print("Mode:              \(mode.displayName)")
        print("Device:            \(deviceName)")
        print("Model:             \(deviceModel)")
        print("LiDAR Available:   \(hasLiDAR ? "✅" : "❌")")
        print("iOS 17+ (3D):      \(supportsVision3D ? "✅" : "❌")")
        print("Pro Mode Ready:    \(canRunProMode ? "✅" : "❌")")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

