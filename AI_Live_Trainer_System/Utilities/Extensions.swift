//
//  Extensions.swift
//  AI Live Trainer System
//

import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
    
    static let workoutPrimary = Color.blue
    static let workoutAccentSuccess = Color.green
    static let workoutAccentError = Color.red
    static let workoutBackground = Color.black
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Date Extensions

extension Date {
    func formattedWorkoutDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w ago"
        } else if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - Double Extensions

extension Double {
    func formattedDuration() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formattedAccuracy() -> String {
        return String(format: "%.0f%%", self)
    }
}

// MARK: - String Extensions

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}

// MARK: - Array Extensions

extension Array where Element: Hashable {
    func uniqueElements() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    func angle(to point: CGPoint) -> CGFloat {
        let deltaY = point.y - y
        let deltaX = point.x - x
        return atan2(deltaY, deltaX)
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let voiceFeedbackEnabled = "voiceFeedbackEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let preferredDifficulty = "preferredDifficulty"
        static let dailyGoal = "dailyGoal"
    }
    
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    var voiceFeedbackEnabled: Bool {
        get { 
            if object(forKey: Keys.voiceFeedbackEnabled) == nil {
                return true // Default to enabled
            }
            return bool(forKey: Keys.voiceFeedbackEnabled)
        }
        set { set(newValue, forKey: Keys.voiceFeedbackEnabled) }
    }
    
    var hapticFeedbackEnabled: Bool {
        get {
            if object(forKey: Keys.hapticFeedbackEnabled) == nil {
                return true // Default to enabled
            }
            return bool(forKey: Keys.hapticFeedbackEnabled)
        }
        set { set(newValue, forKey: Keys.hapticFeedbackEnabled) }
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let workoutSpring = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let smoothEaseInOut = Animation.easeInOut(duration: 0.3)
}

