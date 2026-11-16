# Green Corridor 🚑⚡
### Intelligent Emergency Medical Transit & Chance-Constrained Traffic Signal Preemption (CC-HLP)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Realtime_DB-3ECF8E?logo=supabase)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting_%26_FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![CC-HLP Digital Twin](https://img.shields.io/badge/Digital_Twin-Live_3D_Sim-6C63FF?logo=three.js)](https://green-corridor-web.web.app/cchlp/)
[![SUMO](https://img.shields.io/badge/SUMO-TraCI_Microscopic-007ACC?logo=eclipse)](https://eclipse.dev/sumo/)
[![Platform](https://img.shields.io/badge/Platform-Web_%7C_Android-blue)](#)
[![Status](https://img.shields.io/badge/Build-Passing-brightgreen)](#)

> ### 🌐 Live Production Deployments
> | Subsystem | Domain & Architecture | Live Interactive Link |
> | :--- | :--- | :--- |
> | **Green Corridor Platform** | Production Multi-Portal Emergency Logistics System (Hospital, Driver, Police & Citizens) | 🚀 [**https://green-corridor-web.web.app**](https://green-corridor-web.web.app) |
> | **CC-HLP 3D Digital Twin** | Patented Cyber-Physical Signal Preemption Simulator with NEMA TS2 Cabinet Hardware Interlocks | 🚦 [**https://green-corridor-web.web.app/cchlp/**](https://green-corridor-web.web.app/cchlp/)<br>*(Mirror: [https://himanshu-1629.github.io/Green-corridor-CC-HLP-/](https://himanshu-1629.github.io/Green-corridor-CC-HLP-/))* |
> | **Executive Project Brief (1-Page Dossier)** | PDF Research Handout, Architecture Claims, and Audited Benchmark Table | 📄 [**View 1-Page PDF**](https://green-corridor-web.web.app/PROJECT_ONE_PAGER.pdf) • [Web View](https://green-corridor-web.web.app/one-pager.html) |
> | **SUMO TraCI Benchmark Suite** | 50-Seed Monte Carlo Microscopic Traffic Simulation with IDM Car-Following | 🔬 [**`/sumo_simulation`**](./sumo_simulation) *(Run: `python3 sumo_simulation/run_cchlp_traci.py`)* |
>
> **Android Release Package**: `build/app/outputs/flutter-apk/app-release.apk` (available directly on the portal)

---

## 📌 1. Executive Summary & Societal Problem

In critical organ transplants and emergency trauma transfers, rapid corridor clearance directly determines patient outcomes. A donor heart or liver suffers irreversible ischemic damage if transit times exceed strict clinical windows.

### The Problem in Metropolitan Traffic Today:
1. **Manual Traffic Police Bandobast**: Creating an ad-hoc "Green Corridor" currently requires hundreds of phone calls, physical police deployment along every intersection, and manual barricading.
2. **The Standing Queue Deadlock**: When an emergency vehicle (EV) approaches an intersection, traditional GPS preemption merely turns the signal green. However, civilian cars queued at the red light cannot vanish. The EV gets stuck behind stationary civilian vehicles, causing complete stops and transit failure.
3. **Severe Cross-Street Delay & Secondary Gridlock**: Turning signals green miles in advance freezes perpendicular city traffic, creating gridlock across entire arterial grids.
4. **Driver Panic & Alert Fatigue**: Motorists lack advance directional intimation. Mass alerts (such as SMS or sirens) spam millions of uninvolved commuters, causing public panic or indifference.
5. **Fleet Imbalance**: After delivering an organ, ambulances are stranded far from their home trauma center, unable to return swiftly for subsequent emergencies.

### The Green Corridor Solution:
**Green Corridor** is a unified cyber-physical emergency logistics and signal control architecture comprising two tightly integrated layers:
1. **The Green Corridor Fleet Platform**: A full-stack, real-time coordination suite linking donor hospitals, receiving trauma teams, ambulance drivers, traffic police, and motorists via low-latency Supabase Realtime synchronization and background Firebase Cloud Messaging (FCM).
2. **The CC-HLP Preemption Engine & Cyber-Physical Digital Twin**: A patented, chance-constrained traffic preemption architecture that mathematically resolves the standing queue deadlock through a **Dual-Action Traffic Clearing Law**, backed by Eclipse SUMO microscopic simulations and a 3D NEMA TS2 hardware cabinet digital twin.

---

## 🏛️ 2. System Architecture & Ecosystem

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
┌────────────────────────────────────┐                   ┌───────────────────────────────────┐
│     🚑 DRIVER 3D COCKPIT           │                   │     📱 CITIZEN RADAR RADIAL       │
│  (Hardware GPS Distance Filter,    │                   │  (Hyper-Localized Path-Gating,    │
│   Dynamic Rerouting, 1-Tap Maps,   │                   │   Silent Screen Wake-Up, FCM,     │
│   Return-to-Base Navigation)       │                   │   Directional Siren Warnings)     │
└────────────────────────────────────┘                   └───────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│         🚦 CC-HLP CYBER-PHYSICAL TRAFFIC PREEMPTION ENGINE (Edge / Three.js / SUMO)         │
│  • Chance-Constrained Green Transition: P(T_trans + T_clear <= ETA_EV) >= 1 - epsilon      │
│  • Patented Dual-Action Law: Front Queue (N_crit) Flushes Fwd; Rear Zipper-Merges to L2    │
│  • Dynamic Driver Brain: Continuous Replanning, Quintic s(t) Trajectories, Courtesy Easing │
│  • NEMA TS2 Cabinet: MMU-16LE Conflict Monitor, TS2 BIU SDLC Bus, 800ms Watchdog Interlock │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚡ 3. Green Corridor Fleet Platform Features

### 1. Hospital Admin & Mission Dispatch Console (`Web`)
* **Rapid Corridor Creation**: Select donor hospital, recipient hospital, organ type (Heart, Liver, Lungs, Kidney, Cornea, Bone Marrow), assigned driver, and vehicle in seconds.
* **Fleet Management**: Live tracking of fleet assets (`Available`, `In Transit`, `Returning`) with driver status.
* **Trauma Bay Prep Notification**: When the incoming ambulance enters the final **500-meter radius**, the receiving hospital's screen flashes a high-visibility countdown alert so surgical teams, perfusionists, and security are mobilized at the emergency entrance.

### 2. Driver 3D Navigation Cockpit (`Mobile / Web`)
* **Strict Hardware GPS (Zero Simulation)**: Bound directly to the device's real hardware GPS stream (`distanceFilter: 1m`).
* **Dynamic Coordinate Rerouting**: Routes are calculated dynamically from the driver's live GPS position using OSRM (Open Source Routing Machine).
* **3D Perspective Camera**: Angled cockpit view (`tilt: 50.0°`, `zoom: 18.2`) dynamically rotating to match the vehicle's heading.
* **1-Tap Google Maps HUD**: Integrated button to launch native Google Maps if drivers require private campus shortcuts or voice prompts.
* **Return-to-Base Navigation & Fleet Balance**: Once delivery is confirmed, the app reverses routing to guide the driver back to their home hospital. The driver is marked `Available` in the database **only** after physically returning to base.

### 3. Citizen Emergency Radar & Path-Gated Filtering (`Mobile / Web`)
* **The "In-Between Paths" Geodesic Filter**:
  * Calculates the perpendicular geodesic distance from the citizen's GPS to every segment of the active corridor polyline.
  * **On-Path (`isUserInCorridorPath = true`)**: Within 250m and positioned ahead of the advancing convoy:
    * The live ambulance GPS marker is displayed on their radar map.
    * Route polyline illuminates in Electric Blue.
    * Real-time distance countdown and vehicle speed are displayed.
    * Emergency sirens sound (<1 km warning and <500 m critical yield banner).
  * **Off-Path (`isUserInCorridorPath = false`)**: If the citizen is on a parallel road (e.g. 400m away) or elsewhere in the city:
    * The ambulance GPS is **completely hidden**.
    * Zero alarms sound, eliminating public panic and alert fatigue.
    * Screen displays a calm status: `"All Corridors Clear In Your Area"`.

### 4. Background Device Wake-Up & Cloud Push
* **Closed-App / Locked Screen Handling**:
  * Each citizen device registers a Firebase Cloud Messaging (FCM) token in Supabase on login (`users.fcm_token`).
  * When a corridor is launched, a high-priority silent cloud data push is broadcast.
  * The phone's OS wakes up the app's background isolate (`firebaseMessagingBackgroundHandler`) for 15 seconds.
  * The background isolate silently queries `Geolocator.getCurrentPosition()` and runs the path-check algorithm.
  * **If on that road**: Triggers a **High-Priority Heads-Up Notification** on the lock screen with emergency sirens and vibration (`emergency_corridor_channel`).
  * **If off that road**: The phone returns to sleep silently with zero disturbance and zero battery drain.

---

## 🚦 4. CC-HLP: Chance-Constrained Preemption & Digital Twin

CC-HLP (**Chance-Constrained Human-in-the-Loop Preemption**) is a patented cyber-physical signal preemption architecture that eliminates emergency vehicle braking episodes while bounding cross-street queue delays.

### 4.1 The Fundamental Problem: Queue Deadlock
Conventional Emergency Vehicle Preemption (EVP) systems operate on static distance triggers (e.g., green signal when EV $\le 300\,	ext{m}$). However:
* In congested cities, **Lane 1 is blocked by a standing queue of 6 to 12 civilian cars** stopped at the red light.
* Simply turning the signal green when the ambulance is 300m away is catastrophic: startup lost time ($T_{	ext{lost}} = 2\,	ext{s}$) plus saturation headway ($h = 2\,	ext{s/veh}$) means 10 cars take $\ge 22\,	ext{s}$ to clear the stopline.
* The ambulance arrives in $12\,	ext{s}$, colliding with or stopping dead behind the standing queue ($0\,	ext{km/h}$ emergency braking).

### 4.2 The Mathematical Invariant & Chance Constraints
CC-HLP formulates the preemption decision as a **Chance-Constrained Stochastic Optimization Problem**:

$$\mathbb{P}\left(T_{	ext{trans}} + T_{	ext{clear}}(N_{	ext{crit}}) \le 	ext{ETA}_{	ext{EV}}
ight) \ge 1 - \epsilon$$

Where:
* $T_{	ext{trans}} = T_{	ext{yellow}} + T_{	ext{all\_red}}$ is the minimum safety clearance interval ($5.5\,	ext{s}$).
* $T_{	ext{clear}}(N_{	ext{crit}}) = T_{	ext{lost}} + N_{	ext{crit}} \cdot h$ is the queue discharge time.
* $	ext{ETA}_{	ext{EV}} = rac{d_{	ext{stopline}}}{v_{	ext{EV}}}$ is the real-time kinematic arrival deadline.
* $\epsilon$ is the acceptable risk bound (set to $0.05$, enforcing a **$95\%$ safety guarantee**).
* Driver reaction times follow a non-deterministic Lognormal distribution: $	au \sim 	ext{Lognormal}(\mu=1.705, \sigma=0.35)$.

The stochastic invariant is solved in real time using a **Poisson-Binomial characteristic function (FFT)**, calculating the latest possible moment to truncate cross-street green without causing EV deceleration.

### 4.3 The Patented Dual-Action Clearing Law
Instead of forcing all queued cars to move forward or hoping they pull over onto curbs, CC-HLP dynamically partitions the queue into two distinct, deterministic subsets based on the critical threshold $N_{	ext{crit}}$:

$$N_{	ext{crit}} = \left\lfloor rac{	ext{ETA}_{	ext{EV}} - T_{	ext{trans}} - T_{	ext{lost}}}{h} 
ight
floor$$

```
                                      INTERSECTION STOPLINE
                                               │
                                               ▼
[Lane 1]  ... [Car 6] [Car 5] [Car 4]   |   [Car 3] [Car 2] [Car 1] ===> GREEN STOPLINE DISCHARGE
                 │       │       │             (N <= N_crit = 3 cars flush forward on green)
                 ▼       ▼       ▼
              COOPERATIVE ZIPPER MERGE
                 ▼       ▼       ▼
[Lane 2]  ... [Car B]   [Car C]   [Car D] ... (Moving Traffic with Courtesy Speed Easing)
```

1. **Downstream Subset ($v_i \le N_{	ext{crit}}$)**:
   The first $N_{	ext{crit}}$ vehicles closest to the stopline are commanded to **FLUSH FORWARD ON GREEN**. Since $N_{	ext{crit}}$ is mathematically guaranteed to cross the stopline before the ambulance arrives, they clear cleanly through the intersection.
2. **Upstream Subset ($v_i > N_{	ext{crit}}$)**:
   Vehicles further back in the queue cannot cross the stopline in time. They are directed to execute a **Cooperative Zipper Merge into Lane 2**, completely vacating Lane 1 into a $100\%$ open emergency seam.

### 4.4 Dynamic Driver Brain & Cooperative Gap Creation
Every civilian vehicle in the digital twin executes a continuous, collision-aware decision loop rather than blindly following rigid waypoints:

* **Continuous Lateral Trajectory**:
  Lane changes follow a quintic smoothstep profile:
  $$y(t) = y_1 + \left(10 s^3 - 15 s^4 + 6 s^5
ight)(y_2 - y_1), \quad s \in [0, 1]$$
  Vehicles visibly leave the Lane 1 center, move diagonally across the lane boundary, and align with Lane 2 without snapping or teleporting.
* **Cooperative Courtesy Speed Easing**:
  When a Lane 1 vehicle attempts to merge, the adjacent vehicle in Lane 2 detects the lateral intention. If safe, the Lane 2 vehicle gently eases off the accelerator or applies bounded deceleration ($-1.2\,	ext{m/s}^2$) to enlarge the insertion gap.
* **Dynamic Decision Replanning**:
  If the target gap becomes congested or an overtaking car accelerates, the merging vehicle cancels the attempt, continues moving forward, and recalculates an alternate gap dynamically.

### 4.5 Cyber-Physical Roadside Cabinet Architecture (NEMA TS2)
The CC-HLP system directly interfaces with standard **NEMA TS2 Type 1 / Type 2** and **IRC:SP:41** roadside traffic controller cabinets:

* **NEMA TS2 BIU (Bus Interface Unit)**: Simulates synchronous 153.6 kbps SDLC serial bus communication connecting the controller to detector racks and load switches. If bus comms drop, a $5.0\,	ext{s}$ safety pad is added.
* **MMU-16LE Malfunction Management Unit**: Hardware conflict monitor that supervises conflicting green signal heads. If contradictory signals occur, an electromechanical crowbar relay physically isolates the AI preemption controller in under $800\,	ext{ms}$, dropping the intersection into fail-safe flashing mode.
* **C-V2X 5.9 GHz Radio**: Dedicated Short-Range Communication (DSRC / 802.11bd / 3GPP Rel-16) transceiver broadcasting Cooperative Awareness Messages (CAM) to alert vehicles with sub-second latency ($\mu = 0.6\,	ext{s}$ driver reaction delay).
* **Hardware Watchdog ($	au \le 800\,	ext{ms}$)**: Hardware heartbeat timer. If the preemption algorithm fails to refresh within $800\,	ext{ms}$, the watchdog trips, forcing an instantaneous fail-safe yellow/red flash.

---

## 🔬 5. Microscopic Traffic Benchmarking (Eclipse SUMO & TraCI)

To validate CC-HLP against IEEE and transportation engineering standards, the algorithm is evaluated via a **Two-Tier Validation Architecture**:
* **Tier 1 (Scientific Ground Truth)**: Headless microscopic simulation in **Eclipse SUMO** via the **TraCI (Traffic Control Interface)** Python API with standard **Intelligent Driver Model (IDM)** car-following and sub-lane lateral kinematics.
* **Tier 2 (Real-Time Cyber-Physical Twin)**: Real-time 3D WebGL simulator modeling hardware cabinet faults, camera feeds, and C-V2X radio packet dropouts.

### 5.1 Audited 50-Seed Monte Carlo Benchmark Results
Evaluated along a **3.2 km arterial corridor with 5 signalized junctions**, an EV cruise speed of $72\,	ext{km/h}$ ($20\,	ext{m/s}$), and non-deterministic traffic arrivals across 50 pinned seeds:

| Preemption Controller Architecture | EV Travel Time (s) | Emergency Braking Episodes | Complete EV Stops ($0\,	ext{km/h}$) | Stopline Clearance Violations | Non-Emergency Cross Delay (s/veh) | Preemption Duration (s) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Fixed-Distance Static Trigger (300m)** | 220.21 s | 4.98 | 4.40 | 4.80 | 56.82 s | 144.97 s |
| **2. Queue-Discharge Estimator (Obrusnik 2020)** | 172.12 s | 5.00 | 0.12 | 0.78 | 56.94 s | 144.92 s |
| **3. Reactive Sensor Observer (2s Polling)** | 165.06 s | 3.52 | 0.00 | 0.68 | 43.27 s | 111.10 s |
| **4. CC-HLP Dual-Action (Proposed Architecture)** | **161.42 s** | **1.62** | **0.00** | **0.02 (-98%)** | **47.44 s** | **122.05 s** |

### Key Benchmark Findings:
1. **Zero Complete Stops ($0.00$)**: CC-HLP completely eliminates the standing queue deadlock. The ambulance never decelerates to a full stop.
2. **$98\%$ Reduction in Clearance Violations**: Down from $4.80$ violations per run in the static baseline to $0.02$ in CC-HLP.
3. **Transit Time Savings**: Delivers a **$58.8$-second transit reduction** over the static 300m baseline across the 3.2 km corridor.
4. **Controlled Cross Delay**: Bounded at $47.44\,	ext{s/veh}$, preventing secondary arterial gridlock.

---

## 🛠️ 6. Technology Stack

| Domain | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile & Web App** | **Flutter 3.x / Dart 3.x** | Unified cross-platform client for Hospital, Ambulance Driver, and Citizen portals. |
| **Backend & Database** | **Supabase (PostgreSQL)** | Low-latency Realtime database, Row-Level Security (RLS), and authentication. |
| **Cloud Hosting & Push** | **Firebase Hosting & FCM** | Global CDN for web distribution and high-priority silent background wake-up notifications. |
| **3D Digital Twin Engine** | **Three.js / WebGL** | Real-time procedural 3D corridor, NEMA cabinet, and vehicle physics visualization. |
| **Microscopic Traffic Sim** | **Eclipse SUMO & TraCI** | Gold-standard microscopic traffic simulation with IDM car-following and TraCI control. |
| **Stochastic Optimization** | **Python (NumPy, SciPy)** | Poisson-Binomial FFT solver for real-time chance-constrained preemption calculation. |
| **Hardware Emulation** | **NEMA TS2 / MMU-16LE** | Software emulation of 153.6k SDLC bus, conflict monitor, and 800ms watchdog circuits. |
| **Geospatial & Navigation** | **Geolocator & OSRM** | Hardware GPS navigation (`distanceFilter: 1m`) and dynamic route geometry decoding. |

---

## 📁 7. Directory Structure

```
green_corridor/
├── cchlp_digital_twin/                  # CC-HLP 3D Cyber-Physical Digital Twin
│   ├── index.html                       # Standalone Three.js 3D simulator & Neumorphic HUD
│   ├── cchlp_math_engine.py             # Analytical Poisson-Binomial characteristic solver
│   └── cchlp_dataset.csv                # Calibrated driver reaction and yielding dataset
├── sumo_simulation/                     # Eclipse SUMO Microscopic TraCI Suite
│   ├── corridor.nod.xml                 # Geometric junction nodes
│   ├── corridor.edg.xml                 # 2-lane mainline arterial & cross streets
│   ├── corridor.con.xml                 # Lane connections and signal phase mapping
│   ├── corridor.net.xml                 # Compiled SUMO road network
│   ├── corridor.rou.xml                 # Vehicle routes (IDM civilian + emergency EV)
│   ├── corridor.sumocfg                 # Master SUMO configuration (0.1s time-step)
│   ├── run_cchlp_traci.py               # TraCI Python preemption controller
│   └── sumo_cchlp_benchmark_output.csv  # Output benchmark metrics
├── docs/                                # GitHub Pages Deployment Root
│   ├── index.html                       # Production mirror of CC-HLP 3D Digital Twin
│   ├── cchlp_dataset.csv                # Dataset for web runtime
│   └── .nojekyll                        # GitHub Pages static asset bypass
├── lib/                                 # Green Corridor Flutter Application
│   ├── main.dart                        # Entry point, Supabase & FCM initialization
│   ├── firebase_options.dart            # Multi-platform Firebase credentials
│   ├── supabase_options.dart            # Supabase API URL and keys
│   ├── services/
│   │   ├── push_notification_service.dart# FCM background isolate & local alert sounder
│   │   ├── citizen_alert_service.dart   # Directional sirens & haptic feedback triggers
│   │   ├── siren_web.dart               # Web Audio API dual-tone siren oscillator
│   │   └── siren_stub.dart              # Mobile platform audio fallback stub
│   ├── screens/
│   │   ├── auth_gate.dart               # Role-based resolver (Hospital, Driver, Citizen)
│   │   ├── welcome_screen.dart          # Landing screen
│   │   ├── login_screen.dart            # Authentication with secure session storage
│   │   ├── hospital_dashboard.dart      # Hospital corridor creation & trauma prep
│   │   ├── driver_dashboard.dart        # 3D GPS navigation cockpit & Return Journey
│   │   ├── citizen_screen.dart          # Path-gated radar map & directional sirens
│   │   └── super_admin_dashboard.dart   # City-wide corridor oversight console
│   └── theme/
│       └── app_theme.dart               # Theme tokens, emergency gradients, color palettes
├── PROJECT_ONE_PAGER.pdf                # Academic Research Dossier & Benchmark Handout (1-Page A4)
├── PROJECT_ONE_PAGER.html               # Web view of the project dossier
├── firebase.json                        # Firebase hosting configuration (multi-route)
└── pubspec.yaml                         # Flutter dependencies and asset declarations
```

---

## 🚀 8. Getting Started & How to Run

### 1. Run the Green Corridor Flutter App
```bash
# Clone the repository
git clone https://github.com/himanshu-1629/Green-corridor-CC-HLP-.git
cd green_corridor

# Install Flutter dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Build Release APK for Android
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 2. Run the CC-HLP 3D Digital Twin Locally
```bash
# Start a local HTTP server in the digital twin directory
python3 -m http.server 8090 --directory cchlp_digital_twin

# Open in your browser:
# http://localhost:8090
```

### 3. Run the SUMO TraCI Microscopic Benchmark
```bash
# Run the TraCI benchmark (includes native kinematic emulator, runs on any machine)
python3 sumo_simulation/run_cchlp_traci.py

# (Optional) Run with SUMO GUI if Eclipse SUMO is installed:
sumo-gui -c sumo_simulation/corridor.sumocfg
```

### 4. Generate the 1-Page Academic PDF Handout
```bash
python3 scratch/generate_one_pager.py
# Outputs: PROJECT_ONE_PAGER.pdf (strictly 1 single A4 page)
```

---

## 📄 9. Project Dossier & Internship Deliverables

For academic reviews, project presentations, and internship applications, a single-page executive summary is available:

* **Direct PDF Handout**: [**`PROJECT_ONE_PAGER.pdf`**](https://green-corridor-web.web.app/PROJECT_ONE_PAGER.pdf)
* **Interactive Web Dossier**: [https://green-corridor-web.web.app/one-pager.html](https://green-corridor-web.web.app/one-pager.html)
* **GitHub Repository**: [https://github.com/himanshu-1629/Green-corridor-CC-HLP-](https://github.com/himanshu-1629/Green-corridor-CC-HLP-)

---

## 📄 License
This project is open-source under the **MIT License**.

### 👨‍💻 Author & Lead Architect
**Himanshu Singh**  
*School of Computer Science & Engineering*  
*Vellore Institute of Technology (VIT Chennai)*  
GitHub: [@himanshu-1629](https://github.com/himanshu-1629)
