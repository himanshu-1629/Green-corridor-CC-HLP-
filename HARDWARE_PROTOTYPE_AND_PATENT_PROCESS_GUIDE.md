# GREEN CORRIDOR (JEEVANPATH) & CC-HLP
## Complete Master Guide: Hardware Prototype Implementation & Patent Filing Process

---

## EXECUTIVE OVERVIEW

This document provides a comprehensive, end-to-end operational roadmap for:
1. **Building a Functional Hardware Prototype** (bench-scale Hardware-in-the-Loop testbed to demonstrate the Chance-Constrained Human-in-the-Loop Preemption (CC-HLP) system).
2. **Executing the Full Patent Filing Process** (Indian Patent Office IPO, USPTO, and PCT international filing, including forms, legal framing under Section 3(k), fee structures, and claims protection).

You can copy this document directly into ChatGPT, send it to a registered Patent Attorney, or present it to academic/industrial evaluators.

---

# SECTION 1: HARDWARE PROTOTYPE IMPLEMENTATION GUIDE

```
+-----------------------------------------------------------------------------+
|                            BENCHTOP HIL ARCHITECTURE                        |
+-----------------------------------------------------------------------------+

 [ 🚑 AMBULANCE TELEMETRY ]
        │
        │ GPS Stream (10 Hz NMEA / Lat, Lon, Speed, Heading)
        ▼
 [ ☁️ CLOUD / SUPABASE ] ───(MQTT / WebSocket)───┐
                                                  │
                                                  ▼
                                       [ 🖥️ RASPBERRY PI 5 / JETSON ]
                                       • Evaluates approach queue (N_init)
                                       • Runs CC-HLP Poisson-Binomial Quantile
                                       • Evaluates Boundary Condition:
                                         ETA <= T_clear(N_crit) + T_transition
                                                  │
                                                  │ GPIO Trigger (Active LOW)
                                                  ▼
                                       [ ⚡ OPTOCOUPLER RELAY BOARD ]
                                                  │
                                                  │ Dry Contact Closure
                                                  ▼
                                       [ 🚦 NEMA TS2 / IRC:SP:41 CABINET ]
                                       • Preempt 1 Input Activated
                                       • MMU Enforces Yellow (3.5s) + Red (2s)
                                       • Signal Heads: [RED] -> [GREEN WAVE]
```

---

### 1.1 Complete Bill of Materials (BOM) & Sourcing

| Category | Component Description | Recommended Model | Est. Cost (INR) | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Edge Compute** | Single Board Computer (SBC) | **Raspberry Pi 5 (4GB)** or **Pi 4B** | ₹6,500 – ₹7,500 | Runs local algorithm daemon & physical I/O |
| **Cabinet Interface** | Optocoupler Relay Module | **4-Channel 5V Relay Board** (with opto-isolation) | ₹250 – ₹350 | Electrically isolates Pi GPIO from cabinet voltage |
| **Signal Display** | Traffic Signal Model | **12V / 5V 3-Aspect Mini LED Light** (Red, Yellow, Green) | ₹450 – ₹800 | Visual physical verification of phase cycling |
| **Ambulance OBU** | Microcontroller + GPS | **ESP32-WROOM-32** + **u-blox NEO-M8N GPS** | ₹1,400 – ₹2,200 | Simulates or transmits ambulance telemetry |
| **Queue Detector** | Distance / Vehicle Sensor | **HC-SR04 Ultrasonic** or **USB Webcam (OpenCV)** | ₹150 – ₹1,200 | Measures standing cars ($N_{\text{init}}$) at the stopline |
| **Power Supply** | Multi-voltage Adapter | **5V 3A Type-C** + **12V 2A DC Adapter** | ₹700 – ₹1,000 | Clean DC power rails for logic and signal lamps |
| **Wiring & Base** | Prototyping Breadboard & Wires | Male-Female Jumper Wires + Acrylic Baseplate | ₹300 – ₹500 | Physical bench mounting |
| **TOTAL** | — | — | **~₹9,750 – ₹13,550** | Complete self-contained test bench |

---

### 1.2 Physical Circuit Wiring & Pinout Guide

#### 1. Raspberry Pi GPIO to 4-Channel Relay:
- `Pi Pin 2 (5V DC)` ────> Relay `VCC`
- `Pi Pin 6 (GND)` ──────> Relay `GND`
- `Pi Pin 11 (GPIO 17)` ──> Relay `IN1` (Red Signal Light)
- `Pi Pin 13 (GPIO 27)` ──> Relay `IN2` (Yellow Signal Light)
- `Pi Pin 15 (GPIO 22)` ──> Relay `IN3` (Green Signal Light)
- `Pi Pin 16 (GPIO 23)` ──> Relay `IN4` (Preempt Status / Audio Buzzer)

#### 2. Relay Output Terminals to Signal Heads:
- Connect the **Common (COM)** terminal of Relays 1, 2, and 3 to the positive terminal of the 12V/5V power supply.
- Connect the **Normally Open (NO)** terminal of each relay to the corresponding Red, Yellow, and Green LED anode.
- Connect all LED cathodes back to the Power Supply Ground.

---

### 1.3 Production Edge Controller Python Daemon (`edge_preempt_daemon.py`)

Save and run this script directly on the Raspberry Pi:

```python
#!/usr/bin/env python3
"""
CC-HLP Edge Controller Daemon
Implements Poisson-Binomial Quantile Preemption Trigger with Fail-Safe Timers
"""
import time
import math
import RPi.GPIO as GPIO

# GPIO Configuration
PIN_RED = 17
PIN_YELLOW = 27
PIN_GREEN = 22
PIN_PREEMPT = 23

GPIO.setmode(GPIO.BCM)
GPIO.setup([PIN_RED, PIN_YELLOW, PIN_GREEN, PIN_PREEMPT], GPIO.OUT)

# Signal Safety Constants
T_YELLOW = 3.5      # Mandatory Yellow Clearance (seconds)
T_ALL_RED = 2.0     # Mandatory All-Red Clearance (seconds)
T_LOST = 2.0        # Startup Lost Time (seconds)
HEADWAY_S = 2.0     # Saturation Departure Headway (sec/vehicle)
G_MIN = 6.0         # Minimum Green for Cross-Street
EPSILON = 0.05      # Risk Tolerance Parameter (5%)

def set_signals(red, yellow, green):
    """Controls physical relay state (Active LOW on standard relay boards)."""
    GPIO.output(PIN_RED, GPIO.LOW if red else GPIO.HIGH)
    GPIO.output(PIN_YELLOW, GPIO.LOW if yellow else GPIO.HIGH)
    GPIO.output(PIN_GREEN, GPIO.LOW if green else GPIO.HIGH)

def compute_yielding_probabilities(N_init, d_ev, v_ev):
    """
    Computes deadline-conditioned yielding probability p_i for each vehicle i.
    """
    l_veh = 7.5
    d_safe = 15.0
    mu_m = 1.705
    sigma_m = 0.35
    p_mobile = 0.85
    c_base = 0.92
    p_gap = 0.82
    
    yielding_probs = []
    for i in range(1, N_init + 1):
        x_i = -(N_init - i + 1) * l_veh
        delta_x = abs(x_i - (-d_ev))
        delta_t_deadline = (delta_x - d_safe) / max(v_ev, 1.0)
        
        if delta_t_deadline <= 0:
            p_feasible = 0.0
        else:
            z = (math.log(delta_t_deadline) - mu_m) / sigma_m
            p_feasible = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
            
        p_acoustic = 1.0 / (1.0 + math.exp((delta_x - 180.0) / 30.0))
        p_alert = 1.0 - (1.0 - p_mobile) * (1.0 - p_acoustic)
        p_i = p_alert * c_base * p_gap * p_feasible
        yielding_probs.append(p_i)
        
    return yielding_probs

def compute_critical_queue(yielding_probs, epsilon=0.05):
    """
    Evaluates exact discrete Poisson-Binomial Quantile via recursive convolution.
    """
    N = len(yielding_probs)
    if N == 0:
        return 0
        
    # Distribution of blockers: q_i = 1 - p_i
    q = [1.0 - p for p in yielding_probs]
    
    # Recursive PMF computation
    pmf = [1.0]
    for p_val in q:
        new_pmf = [0.0] * (len(pmf) + 1)
        for k in range(len(pmf)):
            new_pmf[k] += pmf[k] * (1.0 - p_val)
            new_pmf[k + 1] += pmf[k] * p_val
        pmf = new_pmf
        
    # CDF Quantile lookup
    cdf = 0.0
    for n in range(len(pmf)):
        cdf += pmf[n]
        if cdf >= (1.0 - epsilon):
            return n
    return N

def trigger_green_corridor_preemption():
    """Executes safe physical transition to Preemption Green."""
    print(">>> PREEMPTION TRIGGERED: Executing Fail-Safe Clearance Sequence")
    
    # 1. Shift Conflicting Phase to Yellow
    set_signals(red=False, yellow=True, green=False)
    time.sleep(T_YELLOW)
    
    # 2. Shift to All-Red Clearance
    set_signals(red=True, yellow=False, green=False)
    time.sleep(T_ALL_RED)
    
    # 3. Grant Preemption Green
    set_signals(red=False, yellow=False, green=True)
    GPIO.output(PIN_PREEMPT, GPIO.LOW)
    print(">>> PREEMPTION ACTIVE: Emergency Green Wave Open")

def main_loop():
    try:
        # Default State: Normal Red on Emergency Approach
        set_signals(red=True, yellow=False, green=False)
        print("CC-HLP Edge Controller Running. Waiting for incoming telemetry...")
        
        while True:
            # Simulated telemetry: In production, read from Supabase Realtime / MQTT
            d_ev = 260.0    # Distance to stopline (meters)
            v_ev = 20.0     # Speed (m/s) -> 72 km/h
            eta = d_ev / v_ev
            N_init = 8      # Vehicles detected at stopline
            
            # Step 1: Yielding Probabilities
            p_list = compute_yielding_probabilities(N_init, d_ev, v_ev)
            
            # Step 2: Critical Residual Queue
            N_crit = compute_critical_queue(p_list, EPSILON)
            
            # Step 3: Required Lead Time
            T_clear = 0.0 if N_crit == 0 else (T_LOST + N_crit * HEADWAY_S)
            T_lead = T_clear + (T_YELLOW + T_ALL_RED)
            
            print(f"[Telemetry] ETA: {eta:.1f}s | N_init: {N_init} -> N_crit: {N_crit} | T_lead required: {T_lead:.1f}s")
            
            # Step 4: Boundary Trigger Check
            if eta <= T_lead:
                trigger_green_corridor_preemption()
                time.sleep(15.0) # Hold green until EV clears junction
                break
                
            time.sleep(0.5)
            
    finally:
        GPIO.cleanup()

if __name__ == "__main__":
    main_loop()
```

---

# SECTION 2: PATENT FILING MASTER PROCESS

### 2.1 The Two-Stage Filing Strategy (Recommended)

```
[ TODAY ]
   │
   ▼
Stage 1: File PROVISIONAL SPECIFICATION (Form 1, 2, 3, 5)
   • Locks international "PRIORITY DATE" immediately.
   • Allows you to legally brand the product "PATENT PENDING".
   • You can freely demonstrate the prototype, pitch to investors, and publish without losing rights.
   • Government Fee: Only ₹1,600 (for Individuals / Startups).
   │
   ▼
[ 12-MONTH GRACE WINDOW ] (Conduct live municipal pilot, gather telemetry data)
   │
   ▼
Stage 2: File COMPLETE SPECIFICATION with FORMAL CLAIMS
   • File Form 2 (Complete Spec + Claims 1 to 20 + Formal Drawings).
   • File Form 18 (Request for Examination - RFE).
   • File PCT Application via WIPO (if filing in the US, EU, or internationally).
```

---

### 2.2 Mandatory IPO Forms & Checklist (Indian Patent Office)

| Form # | Document Title | Description & What to Fill | Statutory Fee (Natural Person / Startup) |
| :--- | :--- | :--- | :--- |
| **Form 1** | Application for Grant of Patent | Identification of inventors, applicant address, declaration of right. | ₹1,600 |
| **Form 2** | Provisional / Complete Specification | Title, Preamble, Technical Field, Background, Detailed Description, Claims, and Abstract. | Included in Form 1 (up to 30 pages & 10 claims) |
| **Form 3** | Statement & Undertaking under Section 8 | Undertaking to inform the Controller of any foreign patent filings (PCT, USPTO). | Nil |
| **Form 5** | Declaration as to Inventorship | Formal declaration signed by inventors naming Himanshu Singh et al. | Nil |
| **Form 9** | Request for Publication *(Optional)* | Fast-tracks publication to **1 month** instead of the standard 18-month waiting period. | ₹2,500 |
| **Form 18** | Request for Examination (RFE) | Triggers the Patent Office examiner to review the application and issue the First Examination Report (FER). | ₹4,000 |
| **Form 28** | Small Entity / Startup / Educational Verification | Submits proof (DPIIT startup certificate or student ID) to secure **80% discount** on all government fees. | Nil |

---

### 2.3 Legal Shield: Overcoming Section 3(k) ("Software per se" Exemption)

In Indian Patent Law (Section 3(k)) and US Patent Law (Alice 101), **software algorithms alone cannot be patented**. To secure a granted patent, the specification and claims MUST be drafted with a strict **Cyber-Physical Technical Effect**.

#### How Our Patent Specification (`patent_specification_cchlp.md`) is Engineered to Pass:
1. **Never claim an abstract mathematical formula**:
   - ❌ *Incorrect*: "A mathematical formula for computing Poisson-Binomial distributions of traffic."
   - ✅ *Correct (Our Claim 1)*: "A cyber-physical emergency traffic preemption system comprising: an emergency vehicle telemetry unit transmitting GPS and speed at 10 Hz; a roadside edge controller interfaced with a traffic signal cabinet; and a hardware Malfunction Management Unit (MMU)..."
2. **Physical Transformation of Matter & Energy**:
   - The algorithm directly switches physical AC/DC contact-closure relays, modulates optical signal lights (switching red to green), alters vehicular kinetic energy (preventing emergency vehicle deceleration $a \le -2.0\text{ m/s}^2$), and enforces physical yellow/all-red hardware safety intervals.
3. **Hardware Watchdog Tie-in**:
   - The inclusion of the **Hardware MMU (106)** establishes physical separation and an independent fail-safe interlock, legally classifying the invention as an industrial control system rather than business software.

---

### 2.4 Formal Patent Drawings Sheet Guide (FIG. 1 to FIG. 4)

Indian Patent Rules require drawings on **A4 paper, black ink only, with 4 cm margins**, and reference numerals corresponding to the specification:

1. **FIG. 1 — System Architecture Diagram**:
   - Label `101`: Emergency Vehicle Telemetry Unit (GNSS + LTE).
   - Label `102`: Cloud Orchestrator.
   - Label `103`: Civilian Navigation Client Devices.
   - Label `104`: Roadside Edge Controller.
   - Label `105`: Traffic Signal Cabinet (NEMA TS2 / IRC:SP:41).
   - Label `106`: Hardware Malfunction Management Unit (MMU).
2. **FIG. 2 — Spatial Approach Queue & Geofence Layout**:
   - Shows intersection approach lane with stopline ($x = 0$), individual cars ($x_1, x_2, \dots, x_N$), safety perimeter ($d_{\text{safe}} = 15\text{ m}$), and decision lookahead horizon ($d_{\text{horizon}} = v_{\text{EV}} \cdot \Delta t_{\text{decision}}$).
3. **FIG. 3 — Algorithmic Method Flowchart**:
   - Flow boxes: Queue Detection $\to$ Deadline Feasibility Calculation $\to$ Dual-Channel Alert Perception $\to$ Exact Poisson-Binomial Quantile ($N_{\text{crit}}$) $\to$ Boundary Trigger Evaluation $\to$ Preemption Actuation.
4. **FIG. 4 — Operational Pareto Frontier Graph**:
   - X-axis: Risk Tolerance Parameter $\varepsilon \in [0.01, 0.10]$.
   - Y-axis: Emergency Vehicle Deceleration Events vs. Cross-Street Civilian Delay.

---

### 2.5 Complete Filing Cost Estimate

| Milestone | Self-Filed (Portal) | Through Patent Agent / Attorney |
| :--- | :--- | :--- |
| **Provisional Filing (Forms 1, 2, 3, 5, 28)** | ₹1,600 | ₹12,000 – ₹20,000 |
| **Early Publication (Form 9 - Optional)** | ₹2,500 | ₹3,500 – ₹5,000 |
| **Complete Specification & Claims** | Nil (included) | ₹15,000 – ₹30,000 |
| **Request for Examination (Form 18)** | ₹4,000 | ₹6,000 – ₹8,000 |
| **Hearing / FER Response Support** | Nil | ₹10,000 – ₹20,000 |
| **TOTAL (Indian Patent)** | **₹5,600 – ₹8,100** | **₹45,000 – ₹80,000** |

---

# SECTION 3: STEP-BY-STEP ACTION PLAN

1. **Week 1: Provisional Filing**
   - Register on [ipindiaonline.gov.in](https://ipindiaonline.gov.in/epatentfiling/goForLogin/doLogin) with a Class 3 Digital Signature (DSC).
   - Submit Form 1, Form 2 (using `patent_specification_cchlp.md`), Form 3, and Form 5.
   - Pay ₹1,600. Receive your official **Patent Application Number and Priority Date Receipt**.
2. **Weeks 2–4: Benchtop Prototype Build**
   - Order the ₹10,000 hardware kit (Raspberry Pi, optocoupler relays, LED signals).
   - Wire the circuit and flash `edge_preempt_daemon.py`.
   - Connect live smartphone telemetry from the existing Flutter driver app.
3. **Month 2–3: Traffic Police / Smart City Department Demo**
   - Present the working benchtop prototype to local Traffic Police or Smart City authorities under a Non-Disclosure Agreement (NDA) or using your official "Patent Pending" status.
   - Propose an off-peak arterial pilot at a single test intersection.
4. **Month 11: File Complete Specification & International PCT**
   - Incorporate real telemetry logs gathered from field runs into the complete specification.
   - File PCT application via WIPO to protect intellectual property in the United States, European Union, and Asia-Pacific.
