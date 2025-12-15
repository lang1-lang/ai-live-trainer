//
//  CameraPermissionManager.swift
//  AI Live Trainer System
//

import AVFoundation
import UIKit

class CameraPermissionManager: ObservableObject {
    static let shared = CameraPermissionManager()
    
    @Published var permissionGranted = false
    @Published var showPermissionDeniedAlert = false
    
    private init() {
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            permissionGranted = false
            showPermissionDeniedAlert = true
        @unknown default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if !granted {
                    self?.showPermissionDeniedAlert = true
                }
            }
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}

