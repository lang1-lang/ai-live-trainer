# Developer Guide - AI Live Trainer System

## Quick Start

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- iOS device with iOS 17.0+ (physical device recommended for camera testing)
- Apple Developer account (for device testing)

### First-Time Setup

1. **Clone and Open**
   ```bash
   git clone <repository-url>
   cd AI_Live_Trainer_System
   open AI_Live_Trainer_System.xcodeproj
   ```

2. **Configure Signing**
   - In Xcode, select the project in the navigator
   - Select the "AI_Live_Trainer_System" target
   - Go to "Signing & Capabilities" tab
   - Select your Team from dropdown
   - Xcode will automatically manage provisioning profiles

3. **Update Bundle Identifier** (if needed)
   - Change from `com.yourcompany.AI-Live-Trainer-System`
   - To your preferred identifier: `com.yourcompany.YourAppName`

4. **Build and Run**
   - Select your target device
   - Press ⌘R or click Run button
   - Accept camera permissions when prompted

## Project Structure

```
AI_Live_Trainer_System/
│
├── AI_Live_Trainer_SystemApp.swift    # App entry point
├── ContentView.swift                  # Tab navigation root
├── Info.plist                         # App configuration
│
├── Models/                            # Data layer
│   ├── WorkoutModel.swift            # Workout definitions
│   ├── WorkoutSession.swift          # Session tracking
│   └── UserStats.swift               # User statistics
│
├── Views/                             # UI layer
│   ├── HomeLibraryView.swift         # Tab 1: Workout library
│   ├── WorkoutCardView.swift         # Workout display cards
│   ├── WorkoutPreRollView.swift      # Pre-workout details
│   ├── LiveSessionView.swift         # Live workout screen
│   ├── CameraFeedView.swift          # Camera integration
│   ├── ARBodyOverlayView.swift       # AR skeleton overlay
│   ├── PostWorkoutView.swift         # Results summary
│   ├── ActivityView.swift            # Tab 2: History
│   ├── AIInsightsView.swift          # Tab 3: AI analysis
│   └── SettingsView.swift            # Tab 4: Settings
│
├── Engine/                            # Business logic
│   ├── LiveSessionManager.swift      # Session orchestration
│   ├── AITrainerEngine.swift         # Form analysis
│   ├── VoiceFeedbackManager.swift    # Voice coaching
│   └── DemoModeManager.swift         # Demo scenarios
│
├── Utilities/                         # Helpers
│   ├── HapticFeedback.swift          # Haptic patterns
│   ├── Extensions.swift              # Swift extensions
│   └── CameraPermissionManager.swift # Permission handling
│
└── Assets.xcassets/                   # Images & colors
    ├── AppIcon.appiconset/
    └── AccentColor.colorset/
```

## Development Workflow

### Adding a New Workout

1. **Define the Workout**
   ```swift
   // In WorkoutModel.swift - sampleWorkouts()
   WorkoutModel(
       id: "wk_004",
       displayName: "Your Workout Name",
       difficultyRating: 3,
       setCount: 3,
       workoutDescription: "Brief description",
       coverAsset: "img_hero",
       tags: ["category", "level"],
       exercises: [
           Exercise(name: "Exercise 1", reps: 15, duration: 45),
           Exercise(name: "Exercise 2", reps: 12, duration: 60)
       ]
   )
   ```

2. **Add Form Analysis** (if new exercise type)
   ```swift
   // In AITrainerEngine.swift
   private func analyzeYourExercise(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
       // Extract joints
       guard let leftHip = try? observation.recognizedPoint(.leftHip),
             leftHip.confidence > 0.5 else {
           return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
       }
       
       // Apply validation rules
       if /* condition */ {
           return FormAnalysisResult(
               isCorrect: false,
               feedback: "Correction message",
               confidence: 0.8
           )
       }
       
       return FormAnalysisResult(isCorrect: true, feedback: "Great form!", confidence: 0.85)
   }
   ```

3. **Route in analyzeForm()**
   ```swift
   // In AITrainerEngine.swift - analyzeForm()
   if exerciseLower.contains("yourexercise") {
       return analyzeYourExercise(observation: observation)
   }
   ```

4. **Add Voice Feedback Phrases**
   ```swift
   // In VoiceFeedbackManager.swift - FeedbackPhrases
   static let yourExercise = [
       "error_type": "Fix this way",
       "perfect": "Perfect form!"
   ]
   ```

### Testing on Device

**Camera Testing Requirements**:
- Must use physical device (Simulator doesn't support camera)
- Ensure good lighting
- Position device 6-8 feet away
- Full body should be visible in frame

**Debug Tips**:
```swift
// Add logging to session manager
print("🎯 Rep count: \(currentRep)")
print("✅ Form correct: \(isFormCorrect)")
print("💬 Feedback: \(liveFeedback)")
```

### Using Demo Mode

**For Development Testing**:
```swift
// In any view
Button("Start Demo") {
    DemoModeManager.shared.startDemo(scenario: .perfectForm)
}
```

**For Screenshots**:
```swift
// Force UI to perfect state
DemoModeManager.shared.prepareForAppStoreScreenshots()
```

## Common Development Tasks

### Adjusting Voice Feedback

**Change Speech Rate**:
```swift
// In VoiceFeedbackManager.swift
utterance.rate = 0.52  // 0.0 (slow) to 1.0 (fast)
```

**Change Voice Pitch**:
```swift
utterance.pitchMultiplier = 1.1  // 0.5 to 2.0
```

**Disable Voice During Development**:
```swift
// In Settings or directly
VoiceFeedbackManager.shared.setEnabled(false)
```

### Modifying Form Validation Thresholds

```swift
// In AITrainerEngine.swift
// Example: Squat depth tolerance
if avgHipY > avgKneeY + 0.05 {  // Adjust 0.05 threshold
    return error("Get deeper!")
}
```

### Customizing UI Colors

```swift
// In Extensions.swift
extension Color {
    static let workoutPrimary = Color.blue  // Change primary color
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
}
```

### Adding Custom Haptics

```swift
// In HapticFeedbackManager.swift
func yourCustomHaptic() {
    var events: [CHHapticEvent] = []
    
    // Define your pattern
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
    
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [intensity, sharpness],
        relativeTime: 0
    )
    events.append(event)
    
    // Play pattern
    do {
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine?.makePlayer(with: pattern)
        try player?.start(atTime: 0)
    } catch {
        print("Failed to play haptic: \(error)")
    }
}
```

## Debugging

### Common Issues

**1. Camera Not Working**
```
Error: AVCaptureSession not starting
Solution:
- Check Info.plist has NSCameraUsageDescription
- Verify permissions in Settings > Privacy > Camera
- Restart app after granting permission
```

**2. Body Tracking Not Detecting**
```
Issue: No skeleton overlay showing
Debug steps:
- Ensure adequate lighting
- Check Vision Framework availability (iOS 14+)
- Verify full body is visible in frame
- Check console for Vision errors
```

**3. SwiftData Not Persisting**
```
Issue: Data not saving between sessions
Debug:
- Check ModelContainer configuration in App file
- Verify @Model macro on classes
- Check for insertion errors in console
```

**4. Voice Feedback Not Playing**
```
Issue: No audio during workout
Debug:
- Check device volume
- Verify audio session configuration
- Check UserDefaults voiceFeedbackEnabled
- Test with simple utterance: 
  VoiceFeedbackManager.shared.speak("Test")
```

### Xcode Debugger Tips

**Break on Error**:
```swift
// Add symbolic breakpoint for all exceptions
// Breakpoint Navigator > + > Symbolic Breakpoint
// Symbol: __exceptionPreprocess
```

**Print Vision Observations**:
```swift
// In LiveSessionManager.processBodyPose()
print("Joint count: \(observation.availableJointNames.count)")
for joint in observation.availableJointNames {
    if let point = try? observation.recognizedPoint(joint) {
        print("\(joint): \(point.location) conf: \(point.confidence)")
    }
}
```

**Monitor Frame Rate**:
```swift
// Add to captureOutput delegate
private var frameCount = 0
private var lastFPSPrint = Date()

func captureOutput(...) {
    frameCount += 1
    if Date().timeIntervalSince(lastFPSPrint) >= 1.0 {
        print("📹 FPS: \(frameCount)")
        frameCount = 0
        lastFPSPrint = Date()
    }
}
```

## Performance Optimization

### Profile with Instruments

1. **Time Profiler**: Identify slow code paths
   - Product > Profile (⌘I)
   - Select "Time Profiler"
   - Focus on processBodyPose and analyzeForm

2. **Allocations**: Check for memory leaks
   - Look for growing memory in session
   - Verify camera session cleanup
   - Check for retain cycles in closures

3. **Energy Log**: Battery impact
   - Monitor camera usage
   - Check background processing
   - Verify proper session stop

### Optimization Tips

**Reduce Vision Processing**:
```swift
// Lower frame rate for better battery
videoOutput.minFrameDuration = CMTime(value: 1, timescale: 15) // 15 FPS
```

**Conditional Processing**:
```swift
// Only process every Nth frame
var frameCounter = 0
func captureOutput(...) {
    frameCounter += 1
    guard frameCounter % 2 == 0 else { return } // Process every other frame
    // ... process frame
}
```

**Lazy Loading**:
```swift
// Load workouts on demand
@State private var workouts: [WorkoutModel] = []

var body: some View {
    // ...
    .onAppear {
        if workouts.isEmpty {
            workouts = WorkoutModel.sampleWorkouts()
        }
    }
}
```

## Testing

### Unit Testing

Create test file:
```swift
// Tests/AITrainerEngineTests.swift
import XCTest
@testable import AI_Live_Trainer_System

final class AITrainerEngineTests: XCTestCase {
    var engine: AITrainerEngine!
    
    override func setUp() {
        super.setUp()
        engine = AITrainerEngine()
    }
    
    func testAngleCalculation() {
        // Test angle calculation helper
        // Mock VNRecognizedPoint objects
        // Assert correct angle
    }
    
    func testSquatDepthValidation() {
        // Test squat validation logic
        // Create mock observation
        // Assert correct feedback
    }
}
```

### UI Testing

```swift
// UITests/WorkoutFlowTests.swift
func testCompleteWorkoutFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // Tap first workout card
    app.scrollViews.otherElements.buttons.firstMatch.tap()
    
    // Verify pre-roll view
    XCTAssertTrue(app.buttons["Start Workout"].exists)
    
    // Start workout
    app.buttons["Start Workout"].tap()
    
    // Verify live session view
    XCTAssertTrue(app.staticTexts.matching(identifier: "RepCounter").exists)
}
```

## Code Style

### Swift Style Guide

**Naming**:
- Classes/Structs: `PascalCase`
- Functions/Variables: `camelCase`
- Constants: `camelCase` (not SCREAMING_SNAKE)

**Layout**:
```swift
// Good
class MyClass {
    // Properties
    var property: String
    
    // Initialization
    init() { }
    
    // Public methods
    func publicMethod() { }
    
    // Private methods
    private func privateMethod() { }
}
```

**SwiftUI Views**:
```swift
struct MyView: View {
    // MARK: - Properties
    @State private var counter = 0
    
    // MARK: - Body
    var body: some View {
        // ...
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        // ...
    }
}
```

### Documentation

**Public APIs**:
```swift
/// Analyzes body pose for exercise form correctness.
///
/// - Parameters:
///   - observation: Vision framework body pose observation
///   - exercise: Name of the exercise being performed
/// - Returns: Analysis result with feedback and confidence
func analyzeForm(observation: VNHumanBodyPoseObservation, exercise: String) -> FormAnalysisResult {
    // ...
}
```

## Deployment

### TestFlight

1. Archive the app (Product > Archive)
2. Validate the archive
3. Upload to App Store Connect
4. Add to TestFlight
5. Share link with testers

### App Store Submission

**Prepare**:
- App icon (1024x1024)
- Screenshots (all required sizes)
- App description
- Keywords
- Privacy policy URL
- Support URL

**Required Info.plist Keys**:
- ✅ NSCameraUsageDescription
- ✅ Bundle identifier
- ✅ Version number
- ✅ Build number

## Resources

### Apple Documentation
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [ARKit](https://developer.apple.com/documentation/arkit)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

### Sample Code
- [Detecting Human Body Poses](https://developer.apple.com/documentation/vision/detecting_human_body_poses_in_images)
- [Capturing Photos](https://developer.apple.com/documentation/avfoundation/avcam_building_a_camera_app)

### Community
- Swift Forums
- Stack Overflow [swift] tag
- r/iOSProgramming

---

**Need Help?**  
Open an issue on GitHub or contact the development team.

