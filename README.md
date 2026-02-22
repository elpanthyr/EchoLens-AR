# EchoLens-AR
Visualizing sounds through spatial AR.

EchoLens AR is a spatial computing application designed to help the Deaf and Hard of Hearing (DHH) community navigate their environment more safely. It identifies important sounds in real-time and visualizes them as 3D objects in Augmented Reality (AR), helping users understand exactly where a sound is coming from.

---

## The Problem
For millions of people with hearing loss, environmental awareness is a constant challenge. Standard solutions often rely on simple phone vibrations or flashing lights. These methods can be helpful, but they don't provide context or direction. A user might know that an alarm is going off, but not where the danger is located.

## The Solution
EchoLens AR acts as a visual sense. It listens for critical sounds—like sirens, fire alarms, or someone calling out—and places a visual marker at the sound's source using AR. This allows users to keep their eyes on their surroundings without relying on others' help.

---
<img width="501" height="754" alt="onboarding page" src="https://github.com/user-attachments/assets/01fc225f-8769-406c-bc9c-f97c2ba104c4" />
<img width="501" height="753" alt="app" src="https://github.com/user-attachments/assets/300dc9bf-c0d8-40e8-bdd0-bf88d24ab130" />
<img width="502" height="757" alt="settings" src="https://github.com/user-attachments/assets/d9119869-4faf-44d6-aed6-b7ec131e03a9" />

## Key Features
* **Spatial Visualizations**: Detected sounds appear as floating 3D markers in the room.
* **Directional Indicators**: If a sound occurs behind the user, glowing indicators on the edge of the screen guide them toward the source.
* **Background Detection**: The app continues to monitor sounds while minimized or while the device is in a pocket, sending haptic alerts and lock screen notifications for critical events.
* **Privacy First**: All audio processing happens locally on the device. Audio is analyzed in real-time and immediately deleted; nothing is ever recorded or sent to the cloud.

---

## Technical Overview

The application is built using Swift and utilizes several native Apple frameworks to create a seamless experience:

* **SoundAnalysis & CoreML**: Analyzes live audio to identify over 300 different sound types with high accuracy and low latency.
* **ARKit & RealityKit**: Tracks the user's physical space and anchors visual alerts to specific coordinates in the room.
* **AVFoundation**: Manages the microphone input buffer to allow for continuous listening without interrupting other media.
* **Core Haptics**: Converts sounds into physical vibrations, using different patterns to represent different types of alerts.
* **SwiftUI**: Provides a clean interface focused on clarity and ease of use.

---

## Target Audience
* **DHH Community**: Individuals seeking greater independence and safety in their daily lives.
* **Situational Awareness**: People in loud environments (like construction sites) or those using noise-canceling headphones.
* **Sensory Support**: Individuals who find visual cues more manageable than loud, unpredictable audio stimuli.

---

## How to Use
1.  **Launch the App**: Open EchoLens AR and grant the necessary microphone and camera permissions.
2.  **Calibration**: Allow the app a few seconds to map the room.
3.  **Automatic Monitoring**: The app will begin listening. When a recognized sound is detected, a 3D icon will appear in the AR view at the source of the sound.
4.  **Haptic Feedback**: If the sound is urgent, your device will vibrate with a pattern specific to that alert.

---
All rights reserved by @apple
