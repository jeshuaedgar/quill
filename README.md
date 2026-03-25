# 🪶 Quill

**A supercharged, AI-powered reminders app for iOS built with SwiftUI.**

Quill is an open-source reminders app that leverages Apple's on-device intelligence to help you capture, organize, and stay on top of everything that matters. Built entirely in Swift with a focus on privacy, performance, and beautiful design.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Xcode](https://img.shields.io/badge/Xcode-26-blue.svg)](https://developer.apple.com/xcode/)

---

## 📱 Screenshots

> _Coming soon — app is actively under development._

---

## ✨ Features

### Core

- ✅ Create, edit, and delete reminders
- ✅ Due dates, times, and recurring schedules
- ✅ Smart notifications
- ✅ Categories and custom lists
- ✅ Priority levels (low, medium, high, urgent)
- ✅ Search, filter, and sort
- ✅ Tags with cross-category linking
- ✅ Dark mode and light mode

### 🧠 Intelligence (On-Device AI)

- 🤖 **Natural language input** — type "Call mom Friday at 5pm" and Quill parses it automatically
- 🤖 **Auto-categorization** — AI assigns categories based on content
- 🤖 **Smart priority** — Suggests urgency based on context and your patterns
- 🤖 **Daily briefing** — AI-generated morning summary of your day
- 🤖 **Smart suggestions** — Pattern-based reminder recommendations
- 🤖 **AI summaries** — Overdue and weekly task summaries powered by on-device LLM

> Intelligence features use Apple's Foundation Models framework (iOS 26+) and Natural Language framework (iOS 18+). **All processing happens on-device. Your data never leaves your phone.**

### 📦 Widgets

- Small — Next upcoming reminder
- Medium — Today's top 3 tasks
- Large — Full daily agenda
- Lock Screen — Countdown to next task
- Live Activity — Currently active/overdue reminder

### 🗣️ Siri & Shortcuts

- "Hey Siri, add a Quill reminder"
- "Hey Siri, what's next on Quill?"
- Full Shortcuts app integration for automation

### ⌚ Apple Watch _(Planned)_

- Quick add from wrist
- Glanceable complications
- Haptic notifications

---

### Tech Stack

| Layer              | Technology                  |
| ------------------ | --------------------------- |
| **UI**             | SwiftUI                     |
| **Data**           | SwiftData                   |
| **Cloud Sync**     | CloudKit                    |
| **On-Device AI**   | Foundation Models (iOS 26+) |
| **NLP**            | Natural Language framework  |
| **Custom ML**      | Core ML + Create ML         |
| **Notifications**  | UserNotifications           |
| **Widgets**        | WidgetKit                   |
| **Voice**          | App Intents / SiriKit       |
| **Minimum Target** | iOS 18                      |

---

## 🚀 Getting Started

### Prerequisites

- **macOS 15+** (Sequoia or later)
- **Xcode 26+** (for Foundation Models support)
- **iPhone or Simulator** running iOS 18+ (iOS 26+ for AI features)
- **Apple Developer Account** (free for simulator, paid for device testing)
- Device with **A17 Pro or later** for Apple Intelligence features

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/quill.git
   cd quill
   ```

2. Open in Xcode

   ```bash
   open Quill.xcodeproj
   ```

3. Select your target device or simulator
4. Build an run (`Cmd + R`)

## 🗺️ Roadmap

### Phase 1 — Foundation _(In Progress)_

- [ ] SwiftData models and CRUD operations
- [ ] Core SwiftUI views (Home, Add, Detail, Lists)
- [ ] Local notifications with scheduling
- [ ] Basic categories and priority system
- [ ] Search and filtering
- [ ] App theming (dark/light mode)

### Phase 2 — Intelligence

- [ ] Natural language date/time parsing (NSDataDetector)
- [ ] NLP entity extraction (Natural Language framework)
- [ ] Core ML category classifier
- [ ] Foundation Models integration (iOS 26+)
- [ ] AI-powered smart input field
- [ ] Auto-categorization
- [ ] Smart priority suggestions
- [ ] Daily briefing generation

### Phase 3 — Polish

- [ ] Widgets (small, medium, large, lock screen)
- [ ] Live Activities for active reminders
- [ ] Siri & App Intents integration
- [ ] Shortcuts actions
- [ ] Animations and haptic feedback
- [ ] Custom app icons
- [ ] Onboarding flow
- [ ] Settings screen

### Phase 4 — Expand

- [ ] Apple Watch companion app
- [ ] Location-based reminders
- [ ] Focus Mode integration
- [ ] CloudKit sync across devices
- [ ] Shared / collaborative lists
- [ ] CSV/JSON export
- [ ] Localization (multiple languages)
