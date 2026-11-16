# CC-HLP Cyber-Physical Digital Twin & Hardware Testbed
## Standalone Patent Reduction-to-Practice 3D Demonstration

This standalone interactive 3D web platform is designed to demonstrate the patented **Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption (CC-HLP)** architecture to thesis committees, patent examiners, and municipal evaluators without requiring immediate physical roadside cabinet hardware.

---

### How to Run Locally

From the root project directory, run:
```bash
python3 cchlp_digital_twin/start_demo.py
```
This automatically finds an available port (e.g. `http://localhost:8090`) and opens the interface in your browser.

---

### Key Demonstration Features

#### 1. Interactive 3D Roadside Hardware Cabinet (NEMA TS2 Type 1 / IRC:SP:41)
* **Location in 3D**: At the corner of the intersection on the concrete pad.
* **Interaction**: Click on the roadside cabinet in 3D or click the **"Hardware Cabinet"** camera button:
  * The camera smoothly swoops and zooms right up to the cabinet face.
  * The dual aluminum doors swing open 110° in 3D on physical hinges.
  * Inside the 19-inch equipment rack, all 6 patent modules are illuminated with live pulsing LEDs:
    1. **Edge Computing Unit (Raspberry Pi 5 / Jetson Orin)**: Runs the 100ms deterministic CC-HLP daemon & AI inference (*Claims 1 & 15*).
    2. **Optocoupler Galvanic Isolation Board**: 2500 Vrms optical dry-contact relay triggers (*Claim 3*).
    3. **NEMA TS2 BIU Backplane**: 153.6 kbps SDLC Port 1 synchronous interface (*Claim 4*).
    4. **Hardware Malfunction Management Unit (MMU-16LE / CMU)**: Non-programmable conflict monitor tripping emergency flash in $\le 450\text{ ms}$ on fault (*Claims 5 & 14*).
    5. **Hardware Latency Watchdog Module**: 800ms heartbeat circuit (*Claim 12*).
    6. **C-V2X / DSRC & GNSS Receiver**: Decodes ambulance GPS vectors and civilian CAM messages (*Claim 2*).
  * Clicking any module opens its patent claims card and engineering specs.
  * Clicking **"Close"** or **"️ Drone View"** swings the doors shut and glides back to the wide aerial perspective.

#### 2. Dynamic 3D Traffic Queuing
* **Queue Slider ($N \in [3, 18]$)**: Dynamically spawns or removes realistic 3D vehicles (sedans, SUVs, hatchbacks) queued behind the stopline.
* **Participatory Adoption Slider ($\rho_{\text{app}} \in [0\%, 100\%]$)**: Controls the proportion of civilian drivers running the mobile alert application.
* **Driver Attention Profile**: Toggles reaction time distributions between *Alerted ($\mu=1.4\text{s}$)*, *Normal ($\mu=1.7\text{s}$)*, and *Distracted ($\mu=2.1\text{s}$)*.

#### 3. The "AI Thinking Mind" Experience
* When you click **" DISPATCH AMBULANCE & RUN AI"**:
  1. **Neural Feature Extraction**: The AI scans every vehicle in the 3D queue (distance, gap in adjacent lane, reaction latency).
  2. **Neural Yielding Propensity Model**: Neural network diagram illuminates and computes individual compliance probabilities $p_i$ for every vehicle.
  3. **Patented Poisson-Binomial Quantile Engine**: Runs the exact $O(N^2)$ recursive discrete convolution live in JavaScript, plots the probability distribution curve $P(N_{\text{rem}} = k)$ on a real-time canvas chart, and inverts the quantile for risk tolerance $\varepsilon = 0.05$.
  4. **3D Physical Action**: Participating cars turn on their amber blinkers and smoothly steer laterally into the adjacent lane or shoulder.
  5. **Signal Transition**: At the exact calculated second, the signal transitions from Red $\to$ Yellow ($3.5\text{ s}$) $\to$ All-Red ($2.0\text{ s}$) $\to$ Preemption Green. The ambulance accelerates through with zero severe braking.

#### 4. Fail-Safe Watchdog Demonstration
* Toggle **"Simulate Stale Packet ($\tau > 800\text{ms}$)"**:
  * Simulates network packet loss or cellular disruption.
  * Trips the hardware watchdog, flashing the cabinet LEDs and forcing the system into **State 3 (Conservative Passive Recovery)** or **Mode 4 (Hardware MMU Flash)** as specified in patent Claims 12–14.

#### 5. Camera Angles & Audio
* **Drone View**: Wide aerial view of all 4 road approaches and buildings.
* **Hardware Cabinet**: Close-up inspection of the physical components.
* **Ambulance POV**: Dynamic chase camera following behind the ambulance.
* **Stopline POV**: Low-angle view from queued vehicles looking up at the traffic lights.
* **Siren Audio**: Web Audio API realistic electronic yelp emergency siren.
