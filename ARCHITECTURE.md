# AI Live Trainer System - Architecture Documentation

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  Home | Workout Detail | Live Session | Summary | Insights  │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                   Session Management                         │
│              LiveSessionManager (Orchestrator)               │
└──┬──────────┬───────────┬──────────┬───────────┬───────────┘
   │          │           │          │           │
   ▼          ▼           ▼          ▼           ▼
┌──────┐ ┌────────┐ ┌─────────┐ ┌──────┐ ┌──────────┐
│Camera│ │Vision  │ │AI Engine│ │Voice │ │ Haptics  │
│Feed  │ │FrameWrk│ │ Trainer │ │ Feed │ │ Manager  │
└──────┘ └────────┘ └─────────┘ └──────┘ └──────────┘
   │          │           │          │           │
   └──────────┴───────────┴──────────┴───────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  SwiftData   │
                  │  Persistence │
                  └──────────────┘
```

## Core Components

### 1. Data Layer (Models/)

#### WorkoutModel
- **Purpose**: Defines workout structure and exercises
- **Key Properties**:
  - `id`: Unique identifier
  - `exercises`: Array of Exercise objects
  - `difficultyRating`: 1-5 scale
  - `setCount`: Number of sets to complete
- **Relationships**: Referenced by WorkoutSession

#### WorkoutSession
- **Purpose**: Tracks individual workout performance
- **Key Properties**:
  - `duration`: Total workout time
  - `accuracyPercentage`: Overall form accuracy
  - `feedbackItems`: Array of FeedbackItem objects
- **Persistence**: SwiftData (@Model)

#### UserStats
- **Purpose**: Aggregate user statistics
- **Key Metrics**:
  - Total workouts
  - Current streak
  - Average accuracy
- **Updates**: After each completed session

### 2. View Layer (Views/)

#### Navigation Flow
```
HomeLibraryView (Tab 1)
    └─> WorkoutCardView (ForEach)
        └─> WorkoutPreRollView (Sheet)
            └─> LiveSessionView (FullScreenCover)
                └─> PostWorkoutView (FullScreenCover)
```

#### View Responsibilities

**HomeLibraryView**
- Display workout library
- Show user statistics header
- Navigate to workout details

**LiveSessionView**
- ZStack architecture:
  1. Camera feed (bottom layer)
  2. AR overlay (middle layer)
  3. HUD elements (top layer)
- Manages session lifecycle
- Coordinates feedback display

**ARBodyOverlayView**
- Renders skeletal wireframe using Canvas
- Color-codes based on form correctness
- Draws joints and connections
- Real-time updates from Vision observations

### 3. Engine Layer (Engine/)

#### LiveSessionManager
**Role**: Central orchestrator for workout sessions

**Key Responsibilities**:
- Camera session management
- Frame capture and processing
- State management (reps, sets, time)
- Coordination of all feedback systems

**State Flow**:
```
startSession()
    ↓
setupCamera() + startTimer()
    ↓
captureFrame() [Continuous]
    ↓
processBodyPose() → VNHumanBodyPoseObservation
    ↓
AITrainerEngine.analyzeForm()
    ↓
provideFeedback() → Voice + Haptic + Visual
    ↓
incrementRep() / completeSet()
    ↓
endSession() → createWorkoutSession()
```

#### AITrainerEngine
**Role**: Form analysis and correction logic

**Analysis Pipeline**:
```
analyzeForm(observation, exercise)
    ↓
Route to exercise-specific analyzer:
    - analyzeSquat()
    - analyzePlank()
    - analyzePushUp()
    - analyzeLunge()
    ↓
Extract relevant joint positions
    ↓
Apply validation rules
    ↓
Return FormAnalysisResult {
    isCorrect: Bool
    feedback: String
    confidence: Float
}
```

**Joint Extraction Pattern**:
```swift
guard let leftHip = try? observation.recognizedPoint(.leftHip),
      leftHip.confidence > 0.5 else {
    return lowConfidenceResult
}
```

**Validation Examples**:

*Squat Depth Check*:
```swift
let avgHipY = (leftHip.y + rightHip.y) / 2
let avgKneeY = (leftKnee.y + rightKnee.y) / 2

if avgHipY > avgKneeY + threshold {
    return error("Get deeper!")
}
```

*Plank Alignment Check*:
```swift
let shoulderHipDiff = abs(avgShoulderY - avgHipY)

if shoulderHipDiff > threshold {
    return error("Straighten your back!")
}
```

#### VoiceFeedbackManager
**Role**: Audio coaching system

**Features**:
- AVSpeechSynthesizer integration
- Priority-based queue (high/normal/low)
- Context-aware feedback
- Interruption handling

**Feedback Types**:
- Corrections (high priority)
- Encouragement (low priority)
- Rep counts (low priority)
- Set completions (normal priority)

**Configuration**:
```swift
utterance.rate = 0.52              // Speed
utterance.pitchMultiplier = 1.1    // Tone
utterance.volume = 1.0             // Volume
```

#### DemoModeManager
**Role**: Presentation and screenshot mode

**Scenarios**:
1. **Perfect Form**: All-green skeleton, positive feedback
2. **Needs Correction**: Red joints, correction messages
3. **Full Workflow**: Complete app walkthrough

**Usage**:
```swift
DemoModeManager.shared.startDemo(scenario: .perfectForm)
```

### 4. Utilities Layer

#### HapticFeedbackManager
**Haptic Patterns**:
- `formCorrection()`: Strong warning tap
- `goodForm()`: Light success tap
- `repCompleted()`: Quick impact
- `setCompleted()`: Double success pattern
- `workoutCompleted()`: Celebration burst

**Custom Patterns**:
```swift
let pattern = try CHHapticPattern(events: events, parameters: [])
let player = try engine?.makePlayer(with: pattern)
try player?.start(atTime: 0)
```

#### Extensions
**Color Extensions**:
- Hex color initialization
- Workout-specific palette
- Semantic colors (success, error)

**View Extensions**:
- `cardStyle()`: Consistent card appearance
- `primaryButtonStyle()`: Standard button styling

**Date Extensions**:
- `timeAgo()`: Relative time formatting
- `isThisWeek`: Calendar helpers

## Data Flow

### Workout Session Lifecycle

```
1. User Selection
   HomeLibraryView → WorkoutCardView.onTap
   ↓
2. Review
   WorkoutPreRollView displays exercises
   ↓
3. Start Session
   User taps "Start Workout"
   LiveSessionManager.startSession(workout)
   ↓
4. Camera Setup
   AVCaptureSession starts
   videoOutput delegates frames
   ↓
5. Frame Processing [Loop]
   CMSampleBuffer → CVPixelBuffer
   ↓ VNImageRequestHandler
   VNDetectHumanBodyPoseRequest
   ↓
   VNHumanBodyPoseObservation
   ↓
6. Form Analysis [Loop]
   AITrainerEngine.analyzeForm()
   ↓ FormAnalysisResult
   LiveSessionManager.provideFeedback()
   ↓
   Voice + Haptic + Visual feedback
   ↓
7. Rep/Set Tracking
   Auto or manual incrementRep()
   Check if set complete
   Check if workout complete
   ↓
8. Session Complete
   workoutCompleted = true
   LiveSessionManager.createWorkoutSession()
   ↓
9. Results Display
   PostWorkoutView shows summary
   Save to SwiftData
   Update UserStats
```

### Vision Framework Integration

```swift
// Request setup
let request = VNDetectHumanBodyPoseRequest { request, error in
    guard let observations = request.results as? [VNHumanBodyPoseObservation],
          let observation = observations.first else { return }
    
    processBodyPose(observation)
}

// Handler execution
let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
try? handler.perform([request])
```

### SwiftData Persistence

```swift
// Model definition
@Model
final class WorkoutSession {
    var id: UUID
    var workoutId: String
    var accuracyPercentage: Double
    var feedbackItems: [FeedbackItem]
    // ...
}

// Container setup
let schema = Schema([
    WorkoutModel.self,
    WorkoutSession.self,
    UserStats.self
])
let container = try ModelContainer(for: schema)

// Querying
@Query(sort: \WorkoutSession.date, order: .reverse)
private var sessions: [WorkoutSession]
```

## Performance Considerations

### Frame Rate Management
- Target: 30 FPS for body tracking
- Vision processing on background queue
- Main thread updates for UI only

### Memory Management
- Weak references in closures
- Proper cleanup in `deinit`
- AVCaptureSession lifecycle management

### Battery Optimization
- Stop camera when not needed
- Reduce tracking frequency in low power mode
- Efficient Vision request handling

## Security & Privacy

### Camera Access
- Explicit permission request
- Usage description in Info.plist
- Graceful degradation if denied

### Data Storage
- All data stored locally (SwiftData)
- No network transmission
- User can delete all data

### On-Device Processing
- Vision Framework (on-device)
- CoreML models (on-device)
- No cloud dependencies

## Testing Strategy

### Unit Tests
- AITrainerEngine form validation logic
- FeedbackItem severity classification
- Date/time formatting utilities

### Integration Tests
- LiveSessionManager orchestration
- SwiftData persistence
- Camera permission flow

### UI Tests
- Navigation flow
- Demo mode scenarios
- Workout completion flow

## Future Architecture Enhancements

### Planned Improvements
1. **Modular Exercise System**
   - Plugin architecture for new exercises
   - JSON-based exercise definitions

2. **Cloud Sync**
   - CloudKit integration
   - Conflict resolution
   - Privacy-first design

3. **Apple Watch Companion**
   - WatchConnectivity integration
   - Heart rate correlation
   - Quick start workouts

4. **Offline ML Models**
   - Custom CoreML models
   - Exercise-specific training
   - On-device model updates

5. **Video Recording**
   - AVAssetWriter integration
   - Overlay compositing
   - Share/review functionality

## Development Guidelines

### Code Organization
- One responsibility per file
- Protocol-oriented design where appropriate
- SwiftUI best practices (computed properties, @State, @Binding)

### Naming Conventions
- Views: `*View.swift`
- Managers: `*Manager.swift`
- Models: `*Model.swift`
- Extensions: Group related in `Extensions.swift`

### Performance Rules
- Avoid `@Published` for high-frequency updates
- Use `@MainActor` for UI updates
- Debounce rapid state changes

### Accessibility
- VoiceOver support for all UI
- Dynamic Type support
- High contrast mode support
- Haptic alternatives for audio feedback

---

**Architecture Version**: 1.0  
**Last Updated**: 2025  
**Maintained By**: AI Live Trainer Development Team

