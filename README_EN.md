<div align="center">

# 🎯 OKR Tracker

**Make Goals Accessible, Make Progress Visible**

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-lightgrey.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README_EN.md) | [简体中文](README.md)

</div>

---

## 📖 Introduction

**OKR Tracker** is a native iOS application built with **SwiftUI**, designed to help individuals and teams effectively manage goals using the scientific **OKR (Objectives and Key Results)** methodology.

Unlike traditional to-do list apps, OKR Tracker breaks down **grand visions** into **quantifiable key results** and drives progress updates through **specific daily actions** (Tasks). It features powerful visualization charts and a GitHub-style activity heatmap, giving you a clear view of every effort you make.

## ✨ Key Highlights

### 🎯 Deep Goal Management
*   **Multi-dimensional Tracking**: Supports various key result types including Number, Percentage, Currency, and Boolean (Yes/No).
*   **Smart Weighting**: Set "credit" weights for each key result to realistically reflect the contribution of different tasks to the overall goal.
*   **Auto-archiving**: Automatically archives goals upon completion to keep your focus list clean.

### 📅 Goal-Driven Daily Plan
*   **Linked Execution**: Every daily task is directly bound to a specific key result, eliminating ineffective busyness.
*   **Flexible Recurrence**: Supports Daily, Weekly, Weekdays, and other cycle modes to easily build habits.
*   **Instant Feedback**: Task completion = Progress growth. Watch the progress bar advance with every check-in, gaining a sense of achievement.

### 📊 Immersive Data Insights
*   **Panoramic Dashboard**: The home page displays the average progress and health status (On Track/At Risk/Off Track) of all active goals.
*   **Interactive Charts**: Tap progress cards to expand full-screen area charts and trace the progress curve of every time node.
*   **Activity Heatmap**: Replicates the GitHub contribution graph experience, recording your struggle footprints with green squares, supporting filtering by goal.

## 📱 Screenshots

<div align="center">
  <img src="Image/1.png" width="200" alt="Dashboard" />
  <img src="Image/2.png" width="200" alt="Detail View" />
  <img src="Image/3.png" width="200" alt="Heatmap" />
</div>

> *Note: Screenshots are for demonstration purposes.*

## 🛠 Tech Stack

*   **Language**: Swift 5
*   **UI Framework**: SwiftUI
*   **Data Visualization**: Swift Charts
*   **Architecture**: MVVM (Model-View-ViewModel)
*   **Local Storage**: JSON Persistence (No network dependency, data is fully in your hands)
*   **Compatibility**: iOS 16.0+

## 🚀 Installation & Run

1.  **Clone Project**
    ```bash
    git clone https://github.com/yourusername/OKRTracker.git
    ```

2.  **Open Project**
    Open `OKRTracker.xcodeproj` with Xcode.

3.  **Run**
    Select a simulator (iPhone 14 Pro or later recommended) or connect a real device, then click **Run (Cmd+R)**.

## 🤝 Contribution Guide

Contributions of any kind are welcome! Whether it's finding bugs, proposing new features, or directly submitting Pull Requests.