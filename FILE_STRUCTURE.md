# File Structure - AI Live Trainer System

Complete file tree with descriptions of each component.

```
📦 AI_Live_Trainer_System/
│
├── 📱 AI_Live_Trainer_SystemApp.swift        [App Entry Point]
│   └─ Main app struct with SwiftData container setup
│
├── 🎨 ContentView.swift                       [Root Navigation]
│   └─ TabView with 4 tabs (Home, Activity, Insights, Settings)
│
├── ℹ️  Info.plist                             [App Configuration]
│   └─ Permissions, capabilities, and metadata
│
├── 📊 Models/                                 [Data Layer]
│   │
│   ├── WorkoutModel.swift                    [Workout Definition]
│   │   ├─ @Model for SwiftData persistence
│   │   ├─ Exercise struct
│   │   └─ Sample workouts factory method
│   │
│   ├── WorkoutSession.swift                  [Session Tracking]
│   │   ├─ @Model for SwiftData persistence
│   │   ├─ Performance metrics
│   │   └─ FeedbackItem struct
│   │
│   └── UserStats.swift                       [User Statistics]
│       ├─ @Model for SwiftData persistence
│       ├─ Aggregate metrics
│       └─ Streak calculation
│
├── 🎭 Views/                                  [UI Layer]
│   │
│   ├── HomeLibraryView.swift                 [Tab 1: Home]
│   │   ├─ ScrollView with workout cards
│   │   ├─ HeaderView with user stats
│   │   └─ Navigation to workout details
│   │
│   ├── WorkoutCardView.swift                 [Workout Display]
│   │   ├─ Gradient hero image
│   │   ├─ Difficulty badge
│   │   └─ Exercise metadata
│   │
│   ├── WorkoutPreRollView.swift              [Pre-Workout Details]
│   │   ├─ Video preview placeholder
│   │   ├─ Exercise list
│   │   └─ Start workout button
│   │
│   ├── LiveSessionView.swift                 [Live Workout]
│   │   ├─ ZStack architecture:
│   │   │   ├─ Camera feed (bottom)
│   │   │   ├─ AR overlay (middle)
│   │   │   └─ HUD (top)
│   │   ├─ Session manager coordination
│   │   └─ Exit and completion handling
│   │
│   ├── CameraFeedView.swift                  [Camera Integration]
│   │   ├─ UIViewRepresentable wrapper
│   │   ├─ AVCaptureVideoPreviewLayer
│   │   └─ Coordinator for lifecycle
│   │
│   ├── ARBodyOverlayView.swift               [AR Skeleton]
│   │   ├─ Canvas for drawing
│   │   ├─ Joint connections rendering
│   │   ├─ Color coding (green/red)
│   │   └─ BodyWireframe joint definitions
│   │
│   ├── PostWorkoutView.swift                 [Results Summary]
│   │   ├─ Radial accuracy chart
│   │   ├─ Stats grid (duration, reps, sets)
│   │   ├─ Feedback items list
│   │   └─ Share/Done buttons
│   │
│   ├── ActivityView.swift                    [Tab 2: History]
│   │   ├─ Weekly summary card
│   │   ├─ Recent workouts list
│   │   ├─ Empty state view
│   │   └─ SessionHistoryRow components
│   │
│   ├── AIInsightsView.swift                  [Tab 3: AI Analysis]
│   │   ├─ Generated insights list
│   │   ├─ Performance trends
│   │   ├─ Recommendations
│   │   └─ Empty state view
│   │
│   └── SettingsView.swift                    [Tab 4: Settings]
│       ├─ Voice/haptic toggles
│       ├─ Demo mode controls
│       ├─ AboutView sheet
│       └─ FeatureRow components
│
├── ⚙️  Engine/                                [Business Logic]
│   │
│   ├── LiveSessionManager.swift              [Session Orchestrator]
│   │   ├─ ObservableObject with @Published state
│   │   ├─ Camera session management
│   │   ├─ Frame processing pipeline
│   │   ├─ Rep/set tracking logic
│   │   ├─ Feedback coordination
│   │   └─ AVCaptureVideoDataOutputSampleBufferDelegate
│   │
│   ├── AITrainerEngine.swift                 [Form Analysis]
│   │   ├─ analyzeForm() routing
│   │   ├─ analyzeSquat()
│   │   ├─ analyzePlank()
│   │   ├─ analyzePushUp()
│   │   ├─ analyzeLunge()
│   │   ├─ calculateAngle() helper
│   │   └─ FormAnalysisResult struct
│   │
│   ├── VoiceFeedbackManager.swift            [Voice Coaching]
│   │   ├─ AVSpeechSynthesizer wrapper
│   │   ├─ Priority-based queue
│   │   ├─ Context-aware feedback
│   │   ├─ FeedbackPhrases library
│   │   └─ AVSpeechSynthesizerDelegate
│   │
│   └── DemoModeManager.swift                 [Demo System]
│       ├─ ObservableObject for demo state
│       ├─ DemoScenario enum
│       ├─ DemoStep sequencer
│       ├─ Screenshot preparation
│       └─ NotificationCenter integration
│
├── 🛠  Utilities/                             [Helpers]
│   │
│   ├── HapticFeedback.swift                  [Haptic Manager]
│   │   ├─ CHHapticEngine wrapper
│   │   ├─ Workout-specific patterns
│   │   ├─ Custom pattern builder
│   │   └─ HapticPattern enum
│   │
│   ├── Extensions.swift                      [Swift Extensions]
│   │   ├─ Color extensions (hex, semantic)
│   │   ├─ View extensions (styles, modifiers)
│   │   ├─ Date extensions (formatting, relative)
│   │   ├─ Double extensions (duration, accuracy)
│   │   ├─ String extensions (validation, formatting)
│   │   ├─ Array extensions (unique elements)
│   │   ├─ CGPoint extensions (distance, angle)
│   │   ├─ UserDefaults extensions (typed keys)
│   │   └─ Animation extensions (presets)
│   │
│   └── CameraPermissionManager.swift         [Permission Handler]
│       ├─ ObservableObject for permission state
│       ├─ Authorization check
│       ├─ Permission request
│       └─ Settings redirect
│
└── 🎨 Assets.xcassets/                        [Asset Catalog]
    │
    ├── Contents.json                         [Catalog Metadata]
    │
    ├── AppIcon.appiconset/                   [App Icon]
    │   └── Contents.json                     [Icon definitions for all sizes]
    │
    └── AccentColor.colorset/                 [Accent Color]
        └── Contents.json                     [System blue definition]


📚 Documentation Files (Root Level)
│
├── 📖 README.md                               [Project Overview]
│   ├─ Features and capabilities
│   ├─ Technical stack
│   ├─ Setup instructions
│   ├─ Usage guide
│   └─ Architecture overview
│
├── 🏗  ARCHITECTURE.md                        [Technical Deep-Dive]
│   ├─ System architecture diagrams
│   ├─ Component responsibilities
│   ├─ Data flow documentation
│   ├─ Performance considerations
│   └─ Future enhancements
│
├── 👨‍💻 DEVELOPER_GUIDE.md                      [Development Guide]
│   ├─ Setup instructions
│   ├─ Project structure explanation
│   ├─ Development workflow
│   ├─ Common tasks
│   ├─ Debugging tips
│   └─ Code style guide
│
├── 📋 PROJECT_SUMMARY.md                      [Executive Summary]
│   ├─ Project overview
│   ├─ Feature list
│   ├─ Technical specs
│   ├─ Data models
│   └─ Success metrics
│
├── 🏋️ EXERCISE_GUIDE.md                       [Exercise Documentation]
│   ├─ Supported exercises
│   ├─ Analysis algorithms
│   ├─ Validation thresholds
│   ├─ Adding new exercises
│   └─ Joint reference
│
├── 📁 FILE_STRUCTURE.md                       [This File]
│   └─ Complete file tree with descriptions
│
├── 📝 CHANGELOG.md                            [Version History]
│   ├─ Release notes
│   ├─ Feature additions
│   ├─ Bug fixes
│   └─ Breaking changes
│
├── ⚖️  LICENSE                                [Legal]
│   └─ Proprietary license terms
│
└── 🚫 .gitignore                              [Git Configuration]
    └─ Xcode and build artifacts exclusions


📊 File Statistics
│
├── Total Files: 35+
├── Swift Files: 24
├── Documentation Files: 7
├── Configuration Files: 4
├── Asset Files: 3+
│
├── Lines of Code: ~4,000+
├── Models: 3
├── Views: 10
├── Engine Components: 4
├── Utilities: 3
└── Documentation Pages: ~15,000 words


🎯 Key File Relationships
│
├── App Launch Flow:
│   AI_Live_Trainer_SystemApp.swift
│   └─> ContentView.swift
│       └─> HomeLibraryView.swift
│           └─> WorkoutPreRollView.swift
│               └─> LiveSessionView.swift
│                   └─> PostWorkoutView.swift
│
├── Data Flow:
│   WorkoutModel.swift ──> LiveSessionManager.swift
│   └─> AITrainerEngine.swift
│       └─> VoiceFeedbackManager.swift
│           └─> HapticFeedback.swift
│               └─> WorkoutSession.swift (saved)
│
├── Camera Pipeline:
│   LiveSessionView.swift
│   └─> CameraFeedView.swift (AVFoundation)
│       └─> LiveSessionManager.swift (Frame capture)
│           └─> AITrainerEngine.swift (Vision processing)
│               └─> ARBodyOverlayView.swift (Render results)
│
└── Settings & Preferences:
    SettingsView.swift
    ├─> VoiceFeedbackManager.swift
    ├─> HapticFeedback.swift
    └─> DemoModeManager.swift


🔑 Critical Files (Cannot Remove)
│
├── AI_Live_Trainer_SystemApp.swift    [App won't launch]
├── ContentView.swift                  [Navigation broken]
├── Info.plist                         [Build fails]
├── LiveSessionManager.swift           [Core feature broken]
├── AITrainerEngine.swift              [No form analysis]
└── WorkoutModel.swift                 [No data structure]


📦 Modular Components (Can Be Modified/Extended)
│
├── Views/* (all)                      [UI can be redesigned]
├── Engine/AITrainerEngine.swift       [Add more exercises]
├── Engine/VoiceFeedbackManager.swift  [Customize phrases]
├── Utilities/HapticFeedback.swift     [Add patterns]
└── Models/WorkoutModel.swift          [Add more workouts]


🧪 Testing Files (To Be Added)
│
├── Tests/
│   ├── AITrainerEngineTests.swift     [Unit tests for form analysis]
│   ├── LiveSessionManagerTests.swift  [Session orchestration tests]
│   ├── WorkoutModelTests.swift        [Data model tests]
│   └── ExtensionsTests.swift          [Utility function tests]
│
└── UITests/
    ├── WorkoutFlowTests.swift         [End-to-end flow tests]
    ├── NavigationTests.swift          [Tab and navigation tests]
    └── AccessibilityTests.swift       [VoiceOver and Dynamic Type]


📱 Platform-Specific Files
│
├── iOS Exclusive:
│   ├── Info.plist (iOS permissions)
│   ├── CameraFeedView.swift (AVFoundation iOS-specific)
│   └── HapticFeedback.swift (CoreHaptics iOS-only)
│
└── iPad Optimizations:
    └── ContentView.swift (orientation support)


🔄 File Dependencies Map
│
LiveSessionManager.swift depends on:
    ├─ AVFoundation
    ├─ Vision
    ├─ Combine
    ├─ WorkoutModel.swift
    ├─ WorkoutSession.swift
    ├─ AITrainerEngine.swift
    ├─ VoiceFeedbackManager.swift
    └─ HapticFeedback.swift

AITrainerEngine.swift depends on:
    ├─ Vision
    ├─ CoreGraphics
    └─ Foundation

All Views depend on:
    ├─ SwiftUI
    └─ Relevant Model files


💡 Navigation Guide
│
"I want to..."
│
├─ Add a new workout
│   └─> Edit: Models/WorkoutModel.swift
│
├─ Modify UI appearance
│   └─> Edit: Views/*.swift + Utilities/Extensions.swift
│
├─ Change form validation rules
│   └─> Edit: Engine/AITrainerEngine.swift
│
├─ Customize voice feedback
│   └─> Edit: Engine/VoiceFeedbackManager.swift
│
├─ Add new haptic patterns
│   └─> Edit: Utilities/HapticFeedback.swift
│
├─ Modify data persistence
│   └─> Edit: Models/*.swift + AI_Live_Trainer_SystemApp.swift
│
└─ Update app metadata
    └─> Edit: Info.plist


🎨 Asset Organization
│
Assets.xcassets/
├── Colors
│   └── AccentColor (System Blue)
├── Icons
│   └── AppIcon (All sizes)
└── Images (To be added)
    ├── Workout Hero Images
    ├── Exercise Thumbnails
    └── UI Graphics


📊 Code Metrics
│
├── Average File Size: ~150 lines
├── Largest Files:
│   ├─ LiveSessionManager.swift (~300 lines)
│   ├─ AITrainerEngine.swift (~250 lines)
│   └─ Extensions.swift (~200 lines)
│
├── Documentation Ratio: 40%
├── Comments: Inline + header docs
└── Swift Version: 5.9+


🔐 Security & Privacy Files
│
├── Info.plist
│   └─ NSCameraUsageDescription (required)
│
├── CameraPermissionManager.swift
│   └─ Permission handling logic
│
└── All processing on-device
    └─ No network-related files


🚀 Build Configuration
│
├── Debug
│   ├─ Full logging enabled
│   ├─ Demo mode available
│   └─ Faster compile times
│
└── Release
    ├─ Optimizations enabled
    ├─ Logging minimized
    └─ App Store ready
```

---

**Last Updated**: December 2025  
**Total Project Size**: ~4,000 lines of code + ~15,000 words of documentation  
**Platform**: iOS 17+ (iPhone & iPad)

