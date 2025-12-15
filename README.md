# AI Live Trainer System

An iOS fitness application that uses AI-powered computer vision to provide real-time exercise form feedback and coaching.

## Overview

AI Live Trainer System leverages Apple's Vision Framework, ARKit, and CoreML to track body movements during workouts and provide instant feedback on form, helping users exercise safely and effectively.

## Features

### 🎯 Real-Time Form Tracking
- Live body pose detection using Vision Framework
- AR overlay showing skeletal structure
- Instant visual and audio feedback
- Rep and set counting

### 🧠 AI-Powered Coaching
- Exercise-specific form analysis (squats, planks, push-ups, lunges, etc.)
- Personalized correction guidance
- Voice coaching with AVSpeechSynthesizer
- Haptic feedback for errors and encouragement

### 📊 Progress Analytics
- Workout history and statistics
- Form accuracy tracking
- Personalized AI insights
- Streak and achievement tracking

### 🎨 Modern iOS Design
- SwiftUI-based interface
- SF Symbols 5 icons
- Dynamic color theming
- Portrait and landscape support

## Technical Stack

| Component | Technology |
|-----------|-----------|
| **UI Framework** | SwiftUI |
| **Computer Vision** | Vision Framework |
| **AR Tracking** | ARKit (Body Tracking) |
| **AI/ML** | CoreML |
| **Voice** | AVSpeechSynthesizer |
| **Haptics** | CoreHaptics |
| **Data** | SwiftData |
| **Platform** | iOS 17+ |

## Project Structure

```
AI_Live_Trainer_System/
├── Models/
│   ├── WorkoutModel.swift          # Workout data structures
│   ├── WorkoutSession.swift        # Session tracking
│   └── UserStats.swift             # User statistics
├── Views/
│   ├── HomeLibraryView.swift       # Workout library
│   ├── WorkoutCardView.swift       # Workout cards
│   ├── WorkoutPreRollView.swift    # Pre-workout details
│   ├── LiveSessionView.swift       # Live workout screen
│   ├── CameraFeedView.swift        # Camera integration
│   ├── ARBodyOverlayView.swift     # AR skeleton overlay
│   ├── PostWorkoutView.swift       # Results summary
│   ├── ActivityView.swift          # Activity history
│   ├── AIInsightsView.swift        # AI recommendations
│   └── SettingsView.swift          # App settings
├── Engine/
│   ├── LiveSessionManager.swift    # Session orchestration
│   ├── AITrainerEngine.swift       # Form analysis logic
│   ├── VoiceFeedbackManager.swift  # Voice coaching
│   └── DemoModeManager.swift       # Demo & screenshots
├── Utilities/
│   ├── HapticFeedback.swift        # Haptic patterns
│   ├── Extensions.swift            # Helper extensions
│   └── CameraPermissionManager.swift
└── AI_Live_Trainer_SystemApp.swift
```

## Key Components

### AI Trainer Engine

The `AITrainerEngine` class analyzes body pose observations and provides form feedback:

- **Squat Analysis**: Hip depth, knee alignment, back posture
- **Plank Analysis**: Body alignment, hip position
- **Push-up Analysis**: Elbow depth, hand placement
- **Lunge Analysis**: Knee angles, balance

### Voice Feedback Manager

Provides real-time audio coaching with:
- Exercise-specific corrections
- Encouragement and motivation
- Rep counting
- Set completion announcements

### Demo Mode

Special mode for presentations and App Store screenshots:
- Pre-recorded scenarios (perfect form, corrections needed)
- Simulated body tracking
- Consistent UI states for screenshots

## Workout Data Schema

Example workout structure:

```swift
WorkoutModel(
    id: "wk_001",
    displayName: "The Morning Mobilizer",
    difficultyRating: 1,
    setCount: 3,
    description: "Low-impact flow to wake up spine and hips.",
    tags: ["mobility", "recovery", "beginner"],
    exercises: [
        Exercise(name: "Cat-Cow Stretch", reps: 10, duration: 30),
        Exercise(name: "Hip Circles", reps: 8, duration: 40),
        // ...
    ]
)
```

## Setup & Installation

### Requirements
- Xcode 15.0+
- iOS 17.0+
- Device with front-facing TrueDepth camera (iPhone X or later recommended)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd AI_Live_Trainer_System
   ```

2. **Open in Xcode**
   ```bash
   open AI_Live_Trainer_System.xcodeproj
   ```

3. **Configure signing**
   - Select your development team in project settings
   - Update bundle identifier if needed

4. **Build and run**
   - Select target device
   - Build and run (⌘R)

### Permissions

The app requires camera permission for body tracking. The permission is requested on first launch with this message:

> "Camera access is required for AI-powered form tracking during workouts. We analyze your movements in real-time to provide feedback on your exercise form."

## Usage

### Starting a Workout

1. Browse workout library on home screen
2. Tap a workout card to view details
3. Review exercises and tap "Start Workout"
4. Position yourself in front of camera
5. Follow AI coaching during workout
6. Review results and AI insights

### Demo Mode

For presentations or App Store screenshots:

1. Go to Settings tab
2. Select a demo scenario:
   - **Perfect Form Demo**: Shows all-green skeleton
   - **Correction Demo**: Shows form corrections
   - **Screenshot Mode**: Optimizes UI for screenshots

## AI Form Analysis

### Analysis Pipeline

1. **Capture**: AVCaptureSession captures video frames
2. **Detect**: Vision Framework detects body pose joints
3. **Analyze**: AI Trainer Engine compares against ideal form
4. **Feedback**: Voice, haptic, and visual feedback provided

### Joint Detection

The system tracks 15 key body points:
- Head: nose, neck
- Arms: shoulders, elbows, wrists (L/R)
- Core: root (pelvis)
- Legs: hips, knees, ankles (L/R)

### Form Validation

Each exercise has specific validation rules:

**Squat Example:**
```swift
// Check depth
if avgHipY > avgKneeY + 0.05 {
    feedback = "Get deeper! Lower your hips."
}

// Check knee alignment
if abs(avgKneeX - avgAnkleX) > 0.15 {
    feedback = "Keep your knees aligned with your toes."
}
```

## Customization

### Adding New Exercises

1. Add exercise to workout model
2. Implement analysis method in `AITrainerEngine`:
   ```swift
   private func analyzeNewExercise(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
       // Extract relevant joints
       // Apply validation rules
       // Return feedback
   }
   ```
3. Add feedback phrases to `FeedbackPhrases`

### Modifying Voice Feedback

Edit `VoiceFeedbackManager.swift`:
```swift
utterance.rate = 0.52  // Speech speed
utterance.pitchMultiplier = 1.1  // Voice pitch
utterance.volume = 1.0  // Volume level
```

### Custom Haptic Patterns

Add patterns in `HapticFeedbackManager.swift`:
```swift
enum HapticPattern {
    case celebration
    case error
    case yourCustomPattern
}
```

## Privacy & Security

- **On-Device Processing**: All AI analysis happens locally
- **No Data Collection**: Workout data stays on device
- **Optional Cloud Sync**: Can be enabled via Settings (future feature)
- **Camera Privacy**: Video never saved or transmitted

## Performance Optimization

- Body pose detection runs at 30 FPS
- AI analysis optimized for real-time performance
- Low battery mode reduces tracking frequency
- Adaptive quality based on device capabilities

## Future Enhancements

- [ ] Apple Watch integration for heart rate
- [ ] Custom workout builder
- [ ] Social sharing and challenges
- [ ] More exercise types (yoga, pilates)
- [ ] Video recording with overlay
- [ ] Trainer certification mode
- [ ] Apple Health integration
- [ ] Offline workout downloads

## Troubleshooting

### Camera Not Working
- Check camera permissions in Settings
- Ensure adequate lighting
- Clean camera lens
- Restart app

### Poor Tracking
- Ensure full body is visible in frame
- Stand 6-8 feet from camera
- Use landscape mode for better tracking
- Avoid busy backgrounds

### Voice Feedback Not Playing
- Check volume settings
- Enable voice feedback in Settings
- Ensure Do Not Disturb is off

## License

This project is proprietary software. All rights reserved.

## Credits

- **Design**: iOS Human Interface Guidelines
- **Icons**: SF Symbols 5
- **Frameworks**: Apple Vision, ARKit, CoreML

## Contact

For questions, feedback, or support:
- Email: support@ailivetrainer.com
- Website: www.ailivetrainer.com

---

**Built with ❤️ using SwiftUI and Apple's ML frameworks**

