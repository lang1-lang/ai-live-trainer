# Exercise Analysis Guide

This document explains how each exercise is analyzed by the AI Trainer Engine and what form corrections are provided.

## Supported Exercises

### 1. Squats

#### Ideal Form
- **Hip Depth**: Hips should drop below knee level
- **Knee Alignment**: Knees should track over toes, not cave inward
- **Back Posture**: Maintain neutral spine, chest up
- **Weight Distribution**: Weight on heels, not toes

#### Analysis Points
```swift
✓ Left/Right Hip position
✓ Left/Right Knee position
✓ Left/Right Ankle position
✓ Shoulder alignment
```

#### Feedback Messages
| Condition | Message |
|-----------|---------|
| Hips too high | "Get deeper! Lower your hips." |
| Knees past toes | "Keep your knees aligned with your toes." |
| Perfect form | "Perfect squat form!" |

#### Validation Thresholds
```swift
Depth Check: avgHipY < avgKneeY + 0.05
Knee Alignment: abs(avgKneeX - avgAnkleX) < 0.15
```

---

### 2. Planks

#### Ideal Form
- **Body Alignment**: Straight line from shoulders to ankles
- **Hip Position**: Not sagging or piked
- **Core Engagement**: Tight core, no lower back arch
- **Elbow Placement**: Directly under shoulders

#### Analysis Points
```swift
✓ Left/Right Shoulder position
✓ Left/Right Hip position
✓ Left/Right Ankle position
✓ Body line deviation
```

#### Feedback Messages
| Condition | Message |
|-----------|---------|
| Hips sagging | "Raise your hips! Keep your body straight." |
| Hips too high | "Lower your hips to form a straight line." |
| Perfect form | "Excellent plank form!" |

#### Validation Thresholds
```swift
Sag Check: avgHipY < avgShoulderY - 0.1
Pike Check: avgHipY > avgShoulderY + 0.1
```

---

### 3. Push-ups

#### Ideal Form
- **Elbow Depth**: 90-degree bend at bottom
- **Hand Placement**: Slightly wider than shoulder-width
- **Body Alignment**: Straight line maintained
- **Full Range**: Chest near ground at bottom

#### Analysis Points
```swift
✓ Left/Right Shoulder position
✓ Left/Right Elbow position
✓ Left/Right Wrist position
✓ Core alignment
```

#### Feedback Messages
| Condition | Message |
|-----------|---------|
| Not deep enough | "Go lower! Bend your elbows more." |
| Hands too wide/narrow | "Hands should be under your shoulders." |
| Perfect form | "Great push-up form!" |

#### Validation Thresholds
```swift
Depth Check: elbowDepth > 0.05
Hand Placement: abs(avgShoulderX - avgWristX) < 0.2
```

---

### 4. Lunges

#### Ideal Form
- **Front Knee**: 90-degree angle
- **Back Knee**: Nearly touching ground
- **Torso**: Upright, not leaning forward
- **Balance**: Weight distributed evenly

#### Analysis Points
```swift
✓ Left/Right Hip position
✓ Left/Right Knee position
✓ Front/Back leg determination
✓ Torso angle
```

#### Feedback Messages
| Condition | Message |
|-----------|---------|
| Not deep enough | "Lower down more! Aim for 90-degree angles." |
| Back knee high | "Lower your back knee closer to the ground." |
| Perfect form | "Perfect lunge form!" |

#### Validation Thresholds
```swift
Depth Check: kneeHipDiff > 0.2
Back Knee: backKneeY < 0.3
```

---

## Adding New Exercises

### Step-by-Step Guide

#### 1. Define Exercise in Workout
```swift
Exercise(name: "Your Exercise", reps: 12, duration: 45)
```

#### 2. Create Analysis Function
```swift
private func analyzeYourExercise(observation: VNHumanBodyPoseObservation) -> FormAnalysisResult {
    // Extract required joints
    guard let requiredJoint = try? observation.recognizedPoint(.jointName),
          requiredJoint.confidence > 0.5 else {
        return FormAnalysisResult(isCorrect: true, feedback: "", confidence: 0.3)
    }
    
    // Perform validation checks
    if /* error condition */ {
        return FormAnalysisResult(
            isCorrect: false,
            feedback: "Correction message",
            confidence: 0.8
        )
    }
    
    // Success case
    return FormAnalysisResult(
        isCorrect: true,
        feedback: "Perfect form!",
        confidence: 0.85
    )
}
```

#### 3. Add Routing Logic
```swift
// In AITrainerEngine.analyzeForm()
if exerciseLower.contains("yourexercise") {
    return analyzeYourExercise(observation: observation)
}
```

#### 4. Add Voice Feedback Phrases
```swift
// In VoiceFeedbackManager.swift - FeedbackPhrases
static let yourExercise = [
    "error_type": "Correction phrase",
    "perfect": "Success phrase"
]
```

---

## Joint Reference

### Available Joints in Vision Framework

| Joint Name | Description | Common Uses |
|------------|-------------|-------------|
| `.nose` | Nose tip | Head position, body angle |
| `.neck` | Neck base | Upper body alignment |
| `.leftShoulder` | Left shoulder | Arm exercises, posture |
| `.rightShoulder` | Right shoulder | Arm exercises, posture |
| `.leftElbow` | Left elbow | Push-ups, arm angles |
| `.rightElbow` | Right elbow | Push-ups, arm angles |
| `.leftWrist` | Left wrist | Hand placement |
| `.rightWrist` | Right wrist | Hand placement |
| `.root` | Pelvis center | Core position |
| `.leftHip` | Left hip | Lower body exercises |
| `.rightHip` | Right hip | Lower body exercises |
| `.leftKnee` | Left knee | Squats, lunges |
| `.rightKnee` | Right knee | Squats, lunges |
| `.leftAnkle` | Left ankle | Foot position |
| `.rightAnkle` | Right ankle | Foot position |

### Coordinate System
- **X-axis**: 0.0 (left) to 1.0 (right)
- **Y-axis**: 0.0 (bottom) to 1.0 (top)
- **Origin**: Bottom-left corner
- **Normalized**: Values are percentages of screen dimensions

---

## Validation Patterns

### Distance Comparison
```swift
// Check if point A is above point B
if pointA.y > pointB.y + threshold {
    return error("Position incorrect")
}
```

### Angle Calculation
```swift
func calculateAngle(pointA: VNRecognizedPoint, 
                   pointB: VNRecognizedPoint, 
                   pointC: VNRecognizedPoint) -> Double {
    // Vector AB and CB
    let ab = CGVector(dx: pointA.x - pointB.x, dy: pointA.y - pointB.y)
    let cb = CGVector(dx: pointC.x - pointB.x, dy: pointC.y - pointB.y)
    
    // Dot product and magnitudes
    let dotProduct = ab.dx * cb.dx + ab.dy * cb.dy
    let magnitudeAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy)
    let magnitudeCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy)
    
    // Calculate angle
    let cosine = dotProduct / (magnitudeAB * magnitudeCB)
    return acos(cosine) * 180 / .pi
}
```

### Alignment Check
```swift
// Check if three points form a line
let deviation = abs((pointA.y + pointC.y) / 2 - pointB.y)
if deviation > threshold {
    return error("Alignment incorrect")
}
```

---

## Confidence Scores

### What They Mean
- **0.0 - 0.3**: Low confidence, likely can't see joint
- **0.3 - 0.5**: Moderate confidence, partial occlusion
- **0.5 - 0.7**: Good confidence, usable data
- **0.7 - 1.0**: High confidence, excellent tracking

### Recommended Thresholds
```swift
// For critical joints (load-bearing)
guard joint.confidence > 0.5 else { return }

// For supplementary checks
guard joint.confidence > 0.3 else { return }
```

---

## Testing Exercise Analysis

### Manual Testing
1. Stand in front of device camera
2. Perform exercise with intentional form errors
3. Verify correct feedback is provided
4. Adjust thresholds if too sensitive/lenient

### Unit Testing
```swift
func testSquatDepthValidation() {
    let engine = AITrainerEngine()
    let mockObservation = createMockObservation(
        leftHip: CGPoint(x: 0.45, y: 0.6),  // Too high
        rightHip: CGPoint(x: 0.55, y: 0.6),
        leftKnee: CGPoint(x: 0.43, y: 0.3),
        rightKnee: CGPoint(x: 0.57, y: 0.3)
    )
    
    let result = engine.analyzeSquat(observation: mockObservation)
    
    XCTAssertFalse(result.isCorrect)
    XCTAssertEqual(result.feedback, "Get deeper! Lower your hips.")
}
```

---

## Best Practices

### 1. Start with Core Joints
Focus on main body points (hips, shoulders, knees) before detailed analysis.

### 2. Use Averaged Values
For left/right pairs, use averages for more stable tracking:
```swift
let avgHipY = (leftHip.y + rightHip.y) / 2
```

### 3. Provide Actionable Feedback
- ❌ "Bad form"
- ✅ "Lower your hips more"

### 4. Adjust Thresholds
Fine-tune based on real-world testing with diverse body types.

### 5. Handle Missing Data
Always check confidence scores and provide fallback behavior.

---

## Troubleshooting

### Joint Not Detected
- Ensure full body visible in frame
- Check lighting conditions
- Verify no occlusion by objects
- Try different camera angle

### False Positives
- Increase threshold values
- Add additional validation checks
- Require multiple frames of error before feedback

### False Negatives
- Decrease threshold values
- Simplify validation logic
- Check if confidence thresholds too strict

---

## Resources

- [Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- [VNHumanBodyPoseObservation](https://developer.apple.com/documentation/vision/vnhumanbodyposeobservation)
- [Detecting Human Body Poses in Images](https://developer.apple.com/documentation/vision/detecting_human_body_poses_in_images)

---

**Last Updated**: December 2025  
**Version**: 1.0

