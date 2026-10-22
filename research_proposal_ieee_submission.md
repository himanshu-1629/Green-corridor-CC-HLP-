# IEEE TRANSACTIONS ON INTELLIGENT TRANSPORTATION SYSTEMS (T-ITS)
## RESEARCH MANUSCRIPT PROPOSAL & MATHEMATICAL FORMULATION

```markdown
PROMPT FOR CHATGPT / AI PEER REVIEWER:
Act as an IEEE Senior Peer Reviewer and Area Editor for IEEE Transactions on Intelligent Transportation Systems (T-ITS).
Conduct a rigorous review of this revised, mathematically formalized research proposal.
In this version, we have incorporated all previous critiques:
1. Explicitly positioned against prior art: Obrusník et al. (2020) for queue-aware preemption, Lidestam et al. (2020) for in-vehicle alerts, and Su et al. (EMVLight, 2023) for joint signal routing.
2. Eliminated double-counting in queue clearance by deriving clearance strictly from Webster/Newell vehicle conservation: T_clear = t_L + (N / q_max).
3. Derived driver yielding probability P(yield) via a 5-stage conditional chain with Poisson critical gap acceptance P(gap >= t_c) = exp(-q_adj * t_c) from Highway Capacity Manual (HCM) standards.
4. Formulated the preemption trigger as a Chance-Constrained Stochastic Optimization Problem: P(T_clear(N_rem) + T_trans <= ETA_k) >= 1 - \epsilon, incorporating Binomial queue variance rather than treating compliance as deterministic.
5. Modeled signal controller transitions via standard NEMA TS2 / MUTCD state constraints (minimum green, yellow change, all-red clearance).
6. Defined an explicit ablation study comparing our model directly against Obrusník et al. (2020) under varying app penetration (\rho_app \in [0.0, 0.6]).

Evaluate:
A. Scientific Novelty & Theoretical Contribution.
B. Mathematical Rigor & Internal Consistency.
C. Publication Viability for IEEE T-ITS or IEEE ITSC.
```

================================================================================
TITLE:
Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption:
Integrating In-Cabin Mobile Participatory Alerts with Stochastic Queue Discharge
================================================================================

## 1. ABSTRACT
Emergency Vehicle Preemption (EVP) controllers traditionally face a fundamental trade-off: triggering green waves too early induces secondary arterial gridlock, while triggering them too late forces emergency vehicles (EVs) to decelerate behind un-cleared civilian queues. While queue-discharge preemption algorithms (e.g., Obrusník et al., 2020) adapt green onset to observed stationary queues, they treat civilian traffic as purely passive agents that only disperse after the signal turns green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings induce earlier yielding, yet this behavioral response has never been mathematically integrated into signal preemption timing.

In this paper, we propose a Chance-Constrained Human-in-the-Loop Preemption (CC-HLP) framework that couples mobile participatory alert telemetry with microscopic queue dissipation physics. We formulate a five-stage conditional yielding probability chain that models alert delivery, driver attention, and Poisson critical-gap acceptance in adjacent lanes. Because driver compliance is inherently stochastic, we model the residual blocking queue as a Binomial random variable and formulate an analytical Chance-Constrained Trigger Invariant: P(T_clear(N_rem) + T_transition <= ETA) >= 1 - \epsilon, guaranteeing preemption safety at a defined confidence level (e.g., 99%). By accounting for alert-induced voluntary yielding before green onset, the controller safely delays preemption trigger times, preserving orthogonal civilian throughput without compromising EV transit reliability. We validate our framework through extensive microscopic simulation against Obrusník's queue-discharge baseline across penetration rates \rho \in [0.0, 0.6].

---

## 2. LITERATURE POSITIONING & RESEARCH GAP

### 2.1 Prior Art Dissection
1. **Queue-Aware Preemption**: Obrusník et al. (2020, IFAC) established preemption timing based on queue dissipation and acceleration headways. However, their model assumes zero lateral movement prior to green onset (P_yield = 0).
2. **In-Cabin Emergency Warnings**: Lidestam et al. (2020, Frontiers in Psych.) and connected-vehicle human-factor studies proved that advance mobile warnings induce earlier yielding. However, these studies remain isolated in psychology and simulator domains without interfacing with traffic signal controller logic.
3. **Multi-Agent Preemption Routing**: Su et al. (EMVLight, 2023, Trans. Res. Part C) modeled joint routing and signal control via multi-agent reinforcement learning, treating civilian traffic as macroscopic flow rather than participatory agents.

### 2.2 The Identified Research Gap
**No existing framework bridges the gap between participatory in-cabin alert penetration and signal preemption scheduling.** Specifically, the open research question is:
> *Can real-time estimation of alert-induced yielding compliance reliably compress predicted queue clearance horizons under stochastic uncertainty, thereby delaying signal preemption onset to minimize cross-street disruption while mathematically bounding EV deceleration risk?*

---

## 3. MATHEMATICAL FORMULATION

### 3.1 Macroscopic Queue Clearance Dynamics (Webster / Newell Formulation)
Let intersection $k$ have a queue of $N_k(t)$ stationary vehicles on the approach lane. Under classical traffic flow conservation (Webster, 1958; Newell, 1982), the time required for a stationary queue to clear an intersection after green onset is:

$$T_{\text{clear}}(N) = t_L + \frac{N}{q_{\max}}$$

Where:
- $t_L$: Startup lost time due to human perception-reaction latency ($t_L \approx 2.0\text{ s}$).
- $q_{\max}$: Saturation flow rate of the approach lane ($q_{\max} \approx 0.5\text{ veh/s} = 1800\text{ veh/h/lane}$).
- Saturation headway $h_s = \frac{1}{q_{\max}} \approx 2.0\text{ s/veh}$.

*(Note: We eliminate the previous ad-hoc addition of backward shockwave speed $w$, as saturation headway $h_s$ already intrinsically captures the departure time of queued vehicles across the stopline without double-counting).*

---

### 3.2 Five-Stage Conditional Driver Yielding Model
Advance acoustic and digital alerts emitted by the Green Corridor mobile application encourage drivers in the approach lane to yield to an adjacent lane before the signal turns green. The probability that an arbitrary queued driver successfully yields, $P(\text{yield})$, is decomposed into five conditional events:

$$P(\text{yield}) = P(\mathcal{C}) \cdot P(\mathcal{D} \mid \mathcal{C}) \cdot P(\mathcal{A} \mid \mathcal{D}) \cdot P(\mathcal{M} \mid \mathcal{A}) \cdot P(\mathcal{G} \mid \mathcal{M})$$

Where:
1. $P(\mathcal{C}) = \rho_{\text{app}}$: **App Coverage Rate** ($\rho_{\text{app}} \in [0, 1]$, observed via real-time platform telemetry).
2. $P(\mathcal{D} \mid \mathcal{C}) = (1 - P_{\text{loss}})$: **Network Delivery Probability** via Firebase Cloud Messaging / WebSocket ($P_{\text{loss}} \approx 0.04$).
3. $P(\mathcal{A} \mid \mathcal{D})$: **Driver Attention / Auditory Perception**:
   Modeled via an acoustic spatial decay kernel over distance $d_{\text{amb}}$ to the approaching siren:
   $$P(\mathcal{A} \mid \mathcal{D}) = 1 - \exp\left( - \frac{\sigma_{\text{audio}}}{d_{\text{amb}} + \epsilon} \right)$$
   *(where $\sigma_{\text{audio}} \approx 300\text{ m}$ is the calibrated auditory threshold distance).*
4. $P(\mathcal{M} \mid \mathcal{A}) = \eta_{\text{compliance}}$: **Willingness to Comply** ($\eta \approx 0.82$ based on empirical simulator yielding distributions from Lidestam et al., 2020).
5. $P(\mathcal{G} \mid \mathcal{M})$: **Gap Acceptance Feasibility in Adjacent Lane**:
   A driver willing to yield cannot maneuver if the adjacent lane is saturated. Assuming adjacent lane traffic headways follow a Poisson arrival process with flow rate $q_{\text{adj}}$ (veh/s), the probability of finding a headway gap $h$ greater than or equal to the critical lane-changing gap $t_c$ ($t_c \approx 3.5\text{ s}$ per Highway Capacity Manual HCM 6th Edition) is:
   $$P(\mathcal{G} \mid \mathcal{M}) = \mathbb{P}(h \ge t_c) = \exp\left( - q_{\text{adj}} \cdot t_c \right)$$

Combining these stages yields a strictly grounded, non-heuristic compliance probability:

$$P(\text{yield}) = \rho_{\text{app}} \cdot (1 - P_{\text{loss}}) \cdot \left[ 1 - \exp\left( - \frac{\sigma_{\text{audio}}}{d_{\text{amb}} + \epsilon} \right) \right] \cdot \eta_{\text{compliance}} \cdot \exp\left( - q_{\text{adj}} \cdot t_c \right)$$

---

### 3.3 Stochastic Queue Modeling & The Chance-Constrained Invariant
Because each queued vehicle $i \in \{1, \dots, N_k\}$ independently yields with probability $P(\text{yield})$, the total number of yielding vehicles $Y_k$ is a **Binomial Random Variable**:

$$Y_k \sim \text{Binomial}\big(N_k, P(\text{yield})\big)$$

The residual blocking queue remaining in the lane is:

$$N_{\text{rem}, k} = N_k - Y_k$$

The expectation and variance of the residual queue are:
$$\mathbb{E}[N_{\text{rem}}] = N_k \cdot \big(1 - P(\text{yield})\big)$$
$$\operatorname{Var}(N_{\text{rem}}) = N_k \cdot P(\text{yield}) \cdot \big(1 - P(\text{yield})\big)$$

#### The Chance-Constrained Optimization Problem:
A deterministic controller using $\mathbb{E}[N_{\text{rem}}]$ carries a ~50% risk of underestimating queue clearance time, causing emergency vehicle deceleration. We formulate preemption as a **Chance-Constrained Safety Condition**:

$$\mathbb{P}\Big( T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}_k(t) \Big) \ge 1 - \varepsilon$$

Where:
- $\varepsilon \in (0, 1)$: Allowable risk tolerance (e.g., $\varepsilon = 0.01$ denotes a 99% safety guarantee).
- $T_{\text{transition}}$: Deterministic controller phase transition interlock.

Applying the Cantelli-Chebyshev inequality (or Normal approximation for $N_k \ge 10$), the $(1 - \varepsilon)$-quantile critical residual queue $N_{\text{crit}}$ is:

$$N_{\text{crit}} = \mathbb{E}[N_{\text{rem}}] + z_{1-\varepsilon} \cdot \sqrt{\operatorname{Var}(N_{\text{rem}})}$$
$$N_{\text{crit}} = N_k \cdot \big(1 - P(\text{yield})\big) + z_{1-\varepsilon} \cdot \sqrt{N_k \cdot P(\text{yield}) \cdot \big(1 - P(\text{yield})\big)}$$

*(where $z_{0.99} = 2.326$ for 99% confidence).*

The **Deterministic Equivalent Trigger Invariant** is:

$$\text{Trigger Green Preemption} \iff \text{ETA}_k(t) \le t_L + \frac{N_{\text{crit}}}{q_{\max}} + T_{\text{transition}}(k)$$

---

### 3.4 Signal Controller Safety Transition State Machine
The transition duration $T_{\text{transition}}$ is bounded by physical NEMA TS2 and MUTCD / Indian Road Congress (IRC:SP:41) clearance constraints:

$$T_{\text{transition}}(k) = \max\Big(0, g_{\min} - g_{\text{elapsed}}\Big) + t_{\text{yellow}} + t_{\text{all-red}} + \mathbb{I}_{\text{ped}} \cdot t_{\text{ped\_clear}}$$

Where:
- $g_{\min}$: Minimum green requirement of active conflicting phase ($5.0\text{--}8.0\text{ s}$).
- $g_{\text{elapsed}}$: Elapsed green time since phase initiation.
- $t_{\text{yellow}}$: Mandatory yellow change interval ($3.5\text{ s}$).
- $t_{\text{all-red}}$: Intersection clearance interval ($2.0\text{ s}$).
- $\mathbb{I}_{\text{ped}} \cdot t_{\text{ped\_clear}}$: Active pedestrian clearance interval if actuated.

---

### 3.5 Bounded Route Cost Evaluation (Application Layer)
To provide real-time corridor dispatch without claiming unproven routing novelty, we formulate a guaranteed non-negative edge traversal cost $\mathcal{J}(e)$ in units of seconds:

$$\mathcal{J}(e) = T_{\text{free}}(e) \cdot \left[ 1 + \beta \cdot \sum_{j \in \text{cross}(e)} \left( \frac{Q_j(t)}{C_j} \right)^2 \right] \cdot \left[ \frac{1}{1 + \gamma \cdot P(\text{yield})_e} \right]$$

- $T_{\text{free}}(e) > 0$: Free-flow travel time (seconds).
- $\left[ 1 + \beta (Q/C)^2 \right] \ge 1.0$: Dimensionless cross-street penalty scaling.
- $\frac{1}{1 + \gamma P(\text{yield})} \in (0, 1]$: Dimensionless citizen clearance discount.
- **Mathematical Invariant**: $\mathcal{J}(e) > 0 \; \forall e \in E$. Dijkstra's algorithm is guaranteed to converge with zero negative-weight cycles.

---

## 4. EXPERIMENTAL PROTOCOL & ABLATION METHODOLOGY

### 4.1 Simulation Environment Setup (SUMO Microscopic Simulator)
- **Simulator**: SUMO (Simulation of Urban MObility, v1.19.0) coupled via TraCI API.
- **Testbed Network**: Realistic multi-intersection urban corridor (5 consecutive 4-way signalized intersections, 3.2 km arterial road, cross-street saturation flows calibrated to 1800 veh/h/lane).
- **Vehicle Dynamics**: Krauss car-following model ($v_{\max} = 16.6\text{ m/s}$ civilian, $22.2\text{ m/s}$ emergency vehicle; $a_{\max} = 2.5\text{ m/s}^2$, $b_{\text{emergency}} = 4.5\text{ m/s}^2$).
- **Lane Changing Model**: LC2013 model extended with sublane resolution for lateral yielding maneuvers upon receiving simulated mobile V2X alerts.

### 4.2 Benchmark Controllers Evaluated
1. **Baseline 1 (Fixed-Distance EVP)**: Traditional optical/radio preemption triggered at static $d = 300\text{ m}$.
2. **Baseline 2 (Pure Queue-Discharge EVP - Obrusník et al., 2020)**: Dynamically clears observed queue $N_k$, but assumes $P(\text{yield}) = 0$.
3. **Proposed (Chance-Constrained CC-HLP)**: Evaluates $P(\text{yield})$ dynamically and enforces the 99% confidence invariant ($\varepsilon = 0.01$).

### 4.3 Experimental Variables & Metrics
- **Independent Variables**:
  - App Penetration Rate: $\rho_{\text{app}} \in \{0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6\}$.
  - Cross-Street Ambient Traffic Volume: Low (400 veh/h), Medium (800 veh/h), Saturated (1200 veh/h).
- **Evaluation Metrics (Evaluated across 50 Monte-Carlo seeds per configuration)**:
  1. **EV Mean Transit Time (s)** & **Number of EV Complete Stops**.
  2. **EV Deceleration Profile** (Root Mean Square of EV braking events $\ge 2.0\text{ m/s}^2$).
  3. **Average Cross-Street Civilian Delay (s/veh)**.
  4. **Post-Preemption Phase Recovery Duration (s)**.
  5. **Preemption Advance Window** ($\Delta t = \text{ETA} - t_{\text{trigger}}$: measuring how much unnecessary green time is saved).

---

## 5. SUMMARY OF SCIENTIFIC CONTRIBUTIONS
1. **Closing the Behavioral Loop**: First formal framework to mathematically couple in-cabin mobile notification telemetry with signal preemption timing, bridging the gap between Lidestam et al. (2020) and Obrusník et al. (2020).
2. **Analytical Gap-Acceptance Compliance**: Derivation of $P(\text{yield})$ using Poisson headway gap feasibility and acoustic decay, eliminating ad-hoc discount factors.
3. **Chance-Constrained Safety Assurance**: Formulates queue dissipation under human behavioral variance as a Binomial distribution, providing a provable $1 - \varepsilon$ safety guarantee that avoids EV deceleration while minimizing cross-street disruption.
================================================================================
