# Green Corridor 🚑⚡
### Intelligent Emergency Organ Transit & Hyper-Localized Citizen Clearance Infrastructure

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Realtime_DB-3ECF8E?logo=supabase)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting_%26_FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Web_%7C_Android-blue)](#)
[![Status](https://img.shields.io/badge/Build-Passing-brightgreen)](#)
[![Live Demo](https://img.shields.io/badge/Live-Demo_Available-success)](https://green-corridor-web.web.app)

> **Live Web Console**: [https://green-corridor-web.web.app](https://green-corridor-web.web.app)  
> **Android APK**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📌 1. Executive Summary & Societal Problem
In emergency medical transfers and organ transit, rapid traffic clearance and real-time coordination directly determine patient outcomes and life-saving success.

### The Problem in India Today:
1. **Manual Traffic Police Bandobast**: Creating a municipal "Green Corridor" currently demands hundreds of phone calls, physical police deployment along every junction, and manual road barricades.
2. **Zero Prior Intimation for Motorists**: Commuters have no advance warning of incoming emergency convoys. This causes sudden panic braking, gridlock at intersections, and severe delays in organ transit.
3. **Alert Fatigue from Mass Broadcasts**: Conventional broadcast systems (such as city-wide SMS alerts) spam millions of uninvolved citizens located miles away, causing public annoyance and indifference.
4. **Fleet Asymmetry**: After delivering an organ at a recipient hospital, ambulances are often marked "Available" immediately while stuck miles away from their home base, causing acute fleet imbalances.

### The JeevanPath Solution:
**JeevanPath** is a full-stack, real-time emergency transit infrastructure that bridges **Donor Hospitals**, **Receiving Trauma Bays**, **Ambulance Drivers**, and **Nearby Citizens**:
* Coordinates transit routes and surgical teams with real-time ETA countdowns.
* Features a high-precision **3D Cockpit** for drivers bound to real hardware GPS.
* Implements **Hyper-Localized Path-Gated Geofencing** that alerts **only** motorists physically driving in the path ahead of the ambulance.
* Delivers **Closed-App Background Wake-Up (FCM)** to ring emergency sirens even when a citizen's phone is locked or the app is killed.
* Manages **Return-to-Base Journeys** to ensure ambulance fleet balance across hospitals.

---

## 🏛️ 2. System Architecture & Ecosystem

JeevanPath divides operations into dedicated interfaces optimized for specific user personas:

```
                            ┌────────────────────────────────────────┐
                            │    🏥 HOSPITAL ADMIN WEB CONSOLE       │
                            │  (Mission Dispatch, Fleet Management,  │
                            │   Trauma Bay Proximity Countdown)      │
                            └──────────────────┬─────────────────────┘
                                               │
                                               ▼
                             ┌───────────────────────────────────┐
                             │    ☁️ SUPABASE REALTIME & CLOUD   │
                             │  (Auth, Missions, Live Telemetry, │
                             │   FCM Background Push Trigger)    │
                             └───────────┬───────────┬───────────┘
                                         │           │
                   ┌─────────────────────┘           └─────────────────────┐
                   ▼                                                       ▼
┌──────────────────────────────────────┐               ┌──────────────────────────────────────┐
│       🚑 DRIVER 3D COCKPIT APP       │               │      🚗 CITIZEN EMERGENCY RADAR      │
│ • Hardware-Bound GPS (Zero Mock)     │               │ • Geodesic Vector Path Projection    │
│ • Real-Road OSRM Route Navigation    │               │ • Ambulance GPS revealed ONLY on-path│
│ • 1-Tap Google Maps Integration      │               │ • Two-Tier Siren Alert (<1km, <500m) │
│ • 500m Proximity Handover Pop-up     │               │ • Silent Background Device Wake-up   │
│ • Reverse Route Return-to-Base       │               │ • Dual-Tone Audio Siren + Haptics    │
└──────────────────────────────────────┘               └──────────────────────────────────────┘
```

---

## ⚡ 3. Key Features & Technical Innovations

### 1. Hospital Admin & Mission Dispatch Console (`Web`)
* **Rapid Corridor Creation**: Select source hospital, target hospital, organ type (Heart, Liver, Lungs, Kidney, Cornea, Bone Marrow), assigned driver, and available ambulance in seconds.
* **Fleet Management**: Live monitoring of ambulances (`Available`, `In Transit`, `Returning`) and driver allocations.
* **Trauma Bay Prep Notification**: When the incoming ambulance enters the final **500-meter radius**, the receiving hospital's screen flashes a high-visibility emergency alert with a meter countdown so surgical teams, perfusionists, and security are mobilized at the emergency entrance.

### 2. Driver 3D Navigation Cockpit (`Mobile / Web`)
* **Strict Hardware GPS (Zero Simulation)**: The ambulance marker is bound directly to the device's real hardware GPS stream (`distanceFilter: 1m`). All artificial timer runners have been eliminated.
* **Dynamic Coordinate Rerouting**: Routes are calculated dynamically from the driver's live GPS position using OSRM (Open Source Routing Machine), eliminating backward-origin routing artifacts.
* **3D Perspective Camera**: Angled cockpit view (`tilt: 50.0°`, `zoom: 18.2`) that dynamically rotates to match the ambulance's real-time heading.
* **1-Tap Google Maps Launch**: An integrated HUD button allows drivers to instantly launch native Google Maps if they require private campus shortcuts or voice navigation.
* **Smart 500m Handover Dialog**: Prevents premature mission completion through an arrival confirmation pop-up.
* **Return-to-Base Navigation & Fleet Balance**: Once delivery is confirmed, the app reverses routing to guide the driver back to their home hospital. The driver is marked `Available` in the database **only** after physically returning to base.

### 3. Citizen Emergency Radar & Path-Gated Filtering (`Mobile / Web`)
* **The "In-Between Paths" Geodesic Filter**:
  * Calculates the perpendicular geodesic distance from the citizen's GPS to every segment of the active corridor road polyline.
  * **On-Path (`isUserInCorridorPath = true`)**: If the citizen is within **250 meters** of the road and positioned ahead of the advancing convoy:
    * The live ambulance GPS marker is revealed on their radar map.
    * Route polyline illuminates in Electric Blue.
    * Real-time distance countdown and live vehicle speed are displayed.
    * Emergency dual-tone audio sirens sound (<1km warning and <500m critical yield banner).
  * **Off-Path (`isUserInCorridorPath = false`)**: If the citizen is on a parallel road (e.g. 400m away) or elsewhere in the city:
    * The ambulance GPS is **completely hidden**.
    * Zero alarms or sirens sound, eliminating public panic and false alerts.
    * Screen displays a calm status: `"All Corridors Clear In Your Area"`.

### 4. Background Device Wake-Up & Cloud Push (Method 2)
* **Closed-App / Locked Screen Handling**:
  * Each citizen device registers a Firebase Cloud Messaging (FCM) token in Supabase on login (`users.fcm_token`).
  * When a corridor is launched, a high-priority silent cloud data push is broadcast.
  * The phone's OS wakes up the app's background isolate (`firebaseMessagingBackgroundHandler`) for 15 seconds.
  * The background isolate silently queries `Geolocator.getCurrentPosition()` and runs the path-check algorithm.
  * **If on that road**: Triggers a **High-Priority Heads-Up Notification** on the lock screen with emergency sirens and heavy vibration (`emergency_corridor_channel`).
  * **If off that road**: The phone returns to sleep silently with zero disturbance and zero battery drain.

---

## 🛠️ 4. Technology Stack

| Layer | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x (Dart 3.x)** | Cross-platform codebase compiled for Web and Android APK. |
| **Database & Auth** | **Supabase** | Managed PostgreSQL, Row Level Security (RLS), Realtime subscriptions, Auth state listeners. |
| **Cloud Hosting** | **Firebase Hosting** | Global low-latency CDN for web client (`green-corridor-web.web.app`). |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | High-priority data payloads for closed-app device wake-up. |
| **Local Notifications** | **flutter_local_notifications** | Android notification channel (`emergency_corridor_channel`) with full-screen intent. |
| **Geospatial & GPS** | **Geolocator** | High-precision hardware GPS streaming (`LocationAccuracy.bestForNavigation`). |
| **Maps & Tiles** | **Google Maps Flutter SDK** | Map rendering, custom markers, vector polyline overlays. |
| **Routing Engine** | **OSRM & OpenRouteService** | Real-world road graph routing and polyline geometry decoding. |
| **Audio Synthesizer** | **HTML5 Web Audio API** | Dual-tone emergency siren synthesizer generated via oscillator nodes. |

---

## 📁 5. Directory Structure

```
green_corridor/
├── android/                             # Native Android configuration
│   ├── app/
│   │   ├── build.gradle.kts             # Desugaring, signing & dependencies
│   │   ├── google-services.json         # Firebase Android config
│   │   └── src/main/AndroidManifest.xml # Permissions (Location, WakeLock, Notifications)
│   └── settings.gradle.kts              # Google services Gradle plugin
├── build/                               # Build artifacts
│   └── app/outputs/flutter-apk/         # Compiled app-release.apk (53MB)
├── lib/                                 # Core Flutter Application Code
│   ├── main.dart                        # App entry point, Supabase & FCM initialization
│   ├── firebase_options.dart            # Multi-platform Firebase credentials
│   ├── supabase_options.dart            # Supabase API URL and keys
│   ├── theme/
│   │   └── app_theme.dart               # Design tokens, gradients, color palettes
│   ├── services/
│   │   ├── push_notification_service.dart# FCM background handler, token sync, local alerts
│   │   ├── citizen_alert_service.dart   # Haptic feedback and siren triggers
│   │   ├── siren_web.dart               # Web Audio API JS interop implementation
│   │   └── siren_stub.dart              # Mobile/desktop fallback stub
│   └── screens/
│       ├── auth_gate.dart               # Role-based route resolver (Admin, Driver, Citizen)
│       ├── welcome_screen.dart          # Landing page with emergency theme
│       ├── login_screen.dart            # Authentication with secure session storage
│       ├── register_screen.dart         # Multi-role account registration
│       ├── hospital_dashboard.dart      # Hospital management hub
│       ├── create_mission_screen.dart   # Corridor dispatching & route preview
│       ├── mission_center_screen.dart   # Mission tracking (Active, Completed, Incoming)
│       ├── mission_details_screen.dart  # Destination hospital tracking & ER bay alert
│       ├── manage_ambulances_screen.dart# Fleet registration & availability controls
│       ├── manage_drivers_screen.dart   # Driver roster and dispatch assignments
│       ├── driver_dashboard.dart        # Full-screen 3D cockpit & Return Journey
│       ├── citizen_screen.dart          # Path-gated radar map & proximity sirens
│       └── super_admin_dashboard.dart   # State-wide oversight console
├── web/                                 # Web platform assets
│   └── index.html                       # Dual-tone siren synthesizer script & meta tags
├── firebase.json                        # Firebase hosting configuration
└── pubspec.yaml                         # Package dependencies and asset declarations
```

---

## 🗄️ 6. Database Schema (Supabase)

### `users` Table
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `uuid` (PK) | Unique user authentication identifier. |
| `name` | `text` | Full name of doctor, driver, or citizen. |
| `email` | `text` | Contact email address. |
| `role` | `text` | `'Hospital Admin'`, `'Driver'`, `'Citizen'`, or `'Super Admin'`. |
| `is_available` | `boolean` | Driver availability status for new dispatches. |
| `hospital_id` | `uuid` (FK) | Associated home base hospital ID (for drivers). |
| `latitude` | `double precision` | Live or registered latitude. |
| `longitude` | `double precision` | Live or registered longitude. |
| `fcm_token` | `text` | Firebase Cloud Messaging device push token. |

### `missions` Table
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `uuid` (PK) | Unique corridor mission identifier. |
| `hospital_id` | `uuid` (FK) | Dispatching source hospital. |
| `destination_hospital_id`| `uuid` (FK) | Receiving destination hospital. |
| `ambulance_id` | `uuid` (FK) | Assigned emergency vehicle unit. |
| `driver_id` | `uuid` (FK) | Assigned emergency pilot. |
| `organ_type` | `text` | Transplant payload (`Heart`, `Liver`, `Kidney`, etc.). |
| `status` | `text` | `'Assigned'`, `'In Transit'`, or `'Completed'`. |
| `created_at` | `timestamptz` | Mission generation timestamp. |

### `ambulances` Table
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `uuid` (PK) | Vehicle unit record. |
| `plate_number` | `text` | Vehicle registration plate. |
| `is_available` | `boolean` | Current deployment readiness. |
| `latitude` | `double precision` | Real-time vehicle GPS latitude. |
| `longitude` | `double precision` | Real-time vehicle GPS longitude. |
| `speed` | `double precision` | Telemetric speed readout (km/h). |
| `last_updated` | `timestamptz` | Telemetry heartbeat timestamp. |

---

## 🚀 7. Getting Started & Installation

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (`v3.19` or newer)
* [Java Development Kit (JDK 17)](https://www.oracle.com/java/technologies/downloads/)
* [Android SDK](https://developer.android.com/studio) with Command-Line Tools
* [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)

### 1. Clone the Repository
```bash
git clone https://github.com/himanshu-1629/green-corridor.git
cd green-corridor
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Locally on Web
```bash
flutter run -d chrome
```

### 4. Build Android Release APK
```bash
flutter build apk --release
```
The compiled APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 5. Deploy Web Build to Firebase Hosting
```bash
flutter build web --release
firebase deploy --only hosting
```

---

## 🧪 8. Multi-Device End-to-End Testing Guide

To experience the complete live workflow across all three roles:

1. **Hospital Dispatch (Computer Browser)**:
   * Navigate to `https://green-corridor-web.web.app` and log in as a **Hospital Admin**.
   * Go to **Create Mission**, pick a destination hospital, select an organ (e.g. Heart), assign an ambulance and driver, and click **Dispatch Emergency Corridor**.
2. **Driver Navigation (Phone 1 / Android APK)**:
   * Log into the mobile app as the assigned **Driver**.
   * Click **Start Mission**. The full-screen 3D Cockpit engages with real GPS camera tracking.
   * Drive towards the destination. Observe the speedometer and route guidance.
   * Within 500m of destination, confirm arrival via the **Arrival Handover Dialog**.
   * Click **Start Return Journey to Base** to navigate safely back to home hospital.
3. **Citizen Geofence & Siren Test (Phone 2 / Citizen App)**:
   * Log into the app as a **Citizen**.
   * **If standing away from the corridor**: Radar displays `All Corridors Clear In Your Area` with ambulance GPS hidden.
   * **If standing on the corridor road**: Live ambulance marker appears, distance counts down, and emergency sirens sound (<1km and <500m) instructing you to yield left.
   * **If phone screen is locked**: Background FCM wakes up the phone and triggers a high-priority heads-up siren banner.

---

## 🗺️ 9. Roadmap & Future Scope

- [x] Full-Screen 3D Dynamic Cockpit with hardware GPS binding.
- [x] OSRM & OpenRouteService integration with 1-tap Google Maps fallback.
- [x] Smart 500m Handover Geofencing and Reverse Return-to-Base lifecycle.
- [x] Hyper-localized Path-Gated Citizen Radar (ambulance GPS revealed only on-path).
- [x] Closed-app background push notifications with GPS wake-up (Method 2).
- [ ] **AI-Powered V2X Traffic Signal Preemption**: Direct integration with municipal SCATS / ITMS traffic controllers to turn signals green automatically 60 seconds before ambulance arrival.
- [ ] **Drone & Heli-Relay Multimodal Tracking**: Support for aerial organ transport and multimodal drone-to-ambulance handover corridors.
- [ ] **ABDM & NOTTO Integration**: Automated compliance with National Organ & Tissue Transplant Organisation registries.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

---

### 👨‍💻 Author & Developer
**Developed by [Himanshu Singh](https://github.com/himanshu-1629)**  
*Project Repository*: [https://github.com/himanshu-1629/green-corridor](https://github.com/himanshu-1629/green-corridor)
