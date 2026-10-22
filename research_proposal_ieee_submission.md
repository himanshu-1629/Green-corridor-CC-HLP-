# IEEE TRANSACTIONS ON INTELLIGENT TRANSPORTATION SYSTEMS (T-ITS) / IEEE ITSC
## RESEARCH MANUSCRIPT PROPOSAL & MATHEMATICAL FORMULATION

```markdown
PROMPT FOR CHATGPT / AI PEER REVIEWER:
Act as an IEEE Senior Peer Reviewer and Area Editor for IEEE Transactions on Intelligent Transportation Systems (T-ITS) and IEEE ITSC.
Evaluate this final, publication-calibrated research proposal.
In this version, we have resolved all remaining methodological and arithmetic critiques:
1. Corrected the decision horizon arithmetic: T_trans (8-14s) + t_maneuver (5-9s) = 13-23s, resulting in a decision traversal distance d_horizon = v_EV * \Delta t \approx 260-460m (at 20 m/s), explicitly distinguished from kinematic braking distance d_brake = v^2 / 2b \approx 44.4m.
2. Added the 4th Benchmark Controller to the ablation matrix: "Continuously Updating Reactive Observer with Yielding" to empirically falsify/verify whether prediction provides an operational advantage over continuous queue observation with identical sensor access.
3. Cited and differentiated recent 2026 literature (e.g., ScienceDirect 2026 on EVP in mixed traffic environments), distinguishing CAV-dedicated infrastructure from our app-mediated human driver framework.
4. Formulated the preemption trigger as an event-driven boundary-crossing instant: \tau^* = \inf { t >= 0 | ETA_k(t) <= T_clear(N_crit) + T_trans }.
5. Explicitly specified that the 99% safety guarantee is a model-based chance constraint conditioned on Poisson-Binomial behavioral dynamics and negligible upstream arrival flow (q_in \approx 0) during corridor clearance.

Evaluate whether this finalized manuscript proposal provides a publication-ready scientific framework for IEEE ITSC / IEEE T-ITS.
```

================================================================================
TITLE:
Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption:
Integrating Mobile Participatory Alerts with Stochastic Queue Discharge Dynamics
================================================================================

## 1. ABSTRACT
Emergency Vehicle Preemption (EVP) controllers face a persistent trade-off: triggering green waves prematurely induces severe cross-street arterial gridlock, while triggering them too late forces emergency vehicles (EVs) to decelerate behind stationary civilian queues. While queue-discharge preemption algorithms (e.g., Obrusník et al., 2020) adapt green onset to observed stationary queues, they treat civilian traffic as purely passive agents that only disperse after the signal displays green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings induce earlier lateral yielding, yet this behavioral response has never been integrated into preemption scheduling. Furthermore, recent 2026 preemption frameworks rely on dedicated Connected Autonomous Vehicle (CAV) infrastructure, leaving mixed legacy human traffic unaddressed.

In this paper, we investigate whether empirically calibrated, alert-induced driver-yielding probabilities can improve queue-clearance prediction and emergency signal-preemption timing under stochastic uncertainty, while reducing cross-street disruption relative to existing queue-aware and continuous reactive control strategies. We formulate a five-stage conditional yielding probability chain that models alert delivery, auditory perception, driver compliance, and Poisson critical-gap acceptance in adjacent lanes. To overcome the Decision Horizon Lag inherent in reactive queue observation, we model the residual blocking queue as a discrete Binomial random variable and formulate an analytical Chance-Constrained Trigger Invariant using the exact discrete Binomial quantile function: P(T_clear(N_rem) + T_transition <= ETA) >= 1 - \epsilon. This guarantees preemption safety at a defined model confidence level (e.g., 99%) without relying on continuous-distribution approximations. We validate our framework through extensive microscopic simulation in SUMO (SL2015 sublane model) against three baselines, including a continuous reactive queue observer with identical simulated yielding behavior.

---

## 2. LITERATURE POSITIONING & THE "OBSERVER VS. PREDICTOR" HYPOTHESIS

### 2.1 Prior Art Dissection
1. **Queue-Aware Preemption**: Obrusník et al. (2020, IFAC) established preemption timing based on queue dissipation and acceleration headways. However, their model is reactive: it assumes zero lateral movement prior to green onset ($P_{\text{yield}} = 0$).
2. **In-Cabin Emergency Warnings**: Lidestam et al. (2020, Frontiers in Psych.) proved in driving simulators that advance warnings induce earlier driver yielding (~88% compliance under test conditions). However, these studies remain isolated in human-factors psychology without interfacing with signal controllers.
3. **CAV-Dedicated Preemption Frameworks**: Recent 2026 literature (e.g., *ScienceDirect*, 2026) investigates cooperative yielding and preemption in mixed traffic, but relies on Connected Autonomous Vehicles (CAVs) and dedicated lane reservations. Our work specifically targets legacy human-driven traffic mediated by mobile participatory alerts.

### 2.2 The "Observer vs. Predictor" Falsifiable Hypothesis
A fundamental scientific challenge is whether predicting future yielding behavior provides a measurable operational advantage over a controller that continuously observes the physically shrinking queue.

**Hypothesis Formulation:**
> *Under realistic sensing latencies and mandatory signal-transition safety constraints, an event-triggered controller that predicts alert-induced yielding during the lookahead approach horizon will safely delay preemption green onset—reducing cross-street civilian delay without increasing EV deceleration events—compared to a reactive controller that continuously updates its queue estimate using the same sensor measurements.*

**Physical Basis of the Decision Horizon Lag:**
1. **Signal Transition Latency ($T_{\text{transition}}$)**: Mandatory clearance intervals (minimum conflicting green, yellow change, all-red clearance) require $8\text{ to }14\text{ seconds}$ before the corridor signal can physically turn green.
2. **Human Maneuver Latency ($t_{\text{maneuver}}$)**: For a civilian driver to perceive an alert, check mirrors, find an adjacent gap, and execute a lateral lane change requires $5\text{ to }9\text{ seconds}$.
3. **Combined Lookahead Horizon ($\Delta t_{\text{decision}} = T_{\text{transition}} + t_{\text{maneuver}} = 13\text{ to }23\text{ seconds}$)**:
   An EV traveling at $72\text{ km/h}$ ($20\text{ m/s}$) traverses **$d_{\text{horizon}} = v_{\text{EV}} \cdot \Delta t_{\text{decision}} \approx 260\text{ to }460\text{ meters}$** during this combined window.
   *(Note: This is the decision traversal distance, distinct from the physical emergency braking distance $d_{\text{brake}} = \frac{v^2}{2b} \approx 44.4\text{ m}$ at $b = 4.5\text{ m/s}^2$).*
   - If a controller waits until drivers have physically completed their lane change to *observe* the reduced queue, the remaining arrival time is insufficient to complete the mandatory $8\text{--}14\text{s}$ yellow/red clearance sequence without forcing the EV to brake.
   - If an observer triggers early based on the un-yielded queue, it cuts off cross-traffic $13\text{--}23\text{ seconds}$ prematurely.
   - **Predictive preemption bridges this decision gap by evaluating the probability distribution of queue clearance across the lookahead horizon.**

---

## 3. MATHEMATICAL FORMULATION

### 3.1 Tail-of-Queue Kinematic Motion Model
To avoid EV deceleration, the civilian queue does not need to fully exit the intersection; rather, the **tail vehicle (the $N$-th vehicle)** must accelerate to cruise velocity $v_{\text{cruise}}$ before the EV catches up to it.

Assuming upstream arrival flow is negligible during corridor clearance ($q_{\text{in}} \approx 0$), the time required for the $N$-th queued vehicle to begin accelerating and clear the conflict point is:

$$T_{\text{clear}}(N) = t_L + \frac{N}{q_{\max}}$$

Where:
- $t_L$: Excess startup lost time of the lead vehicle beyond steady saturation headway ($t_L \approx 2.0\text{ s}$).
- $q_{\max}$: Saturation flow rate ($q_{\max} \approx 0.5\text{ veh/s} \implies h_s = 2.0\text{ s/veh}$).

---

### 3.2 Five-Stage Conditional Driver Yielding Chain
The probability that an arbitrary queued driver successfully yields, $P(\text{yield})$, is structured as a conditional event chain:

$$P(\text{yield}) = P(\mathcal{C}) \cdot P(\mathcal{D} \mid \mathcal{C}) \cdot P(\mathcal{A} \mid \mathcal{C}, \mathcal{D}) \cdot P(\mathcal{M} \mid \mathcal{C}, \mathcal{D}, \mathcal{A}) \cdot P(\mathcal{G} \mid \mathcal{C}, \mathcal{D}, \mathcal{A}, \mathcal{M})$$

Where:
1. $P(\mathcal{C}) = \rho_{\text{app}}$: **App Penetration Rate** ($\rho_{\text{app}} \in [0, 1]$, observed via platform telemetry).
2. $P(\mathcal{D} \mid \mathcal{C}) = (1 - P_{\text{loss}})$: **Network Delivery Reliability** ($P_{\text{loss}} \approx 0.04$).
3. $P(\mathcal{A} \mid \mathcal{D})$: **Driver Auditory / In-Cabin Attention Decay**:
   Modeled via an acoustic spatial decay kernel over distance $d_{\text{amb}}$ to the approaching siren:
   $$P(\mathcal{A} \mid \mathcal{D}) = 1 - \exp\left( - \frac{\sigma_{\text{audio}}}{d_{\text{amb}} + \epsilon} \right) \quad (\sigma_{\text{audio}} \approx 300\text{ m})$$
4. $P(\mathcal{M} \mid \mathcal{A}) = \eta_{\text{compliance}}$: **Driver Willingness to Comply** (calibrated as a sensitivity parameter $\eta \in [0.70, 0.90]$, referencing Lidestam et al., 2020).
5. $P(\mathcal{G} \mid \mathcal{M})$: **Poisson Critical Gap Acceptance in Adjacent Lane**:
   Under a Poisson arrival headway distribution with adjacent flow rate $q_{\text{adj}}$ (veh/s) and critical lane-changing headway $t_c = t_{\text{lead}} + t_{\text{lag}} \approx 3.5\text{ s}$ (HCM 6th Edition):
   $$P(\mathcal{G} \mid \mathcal{M}) = \mathbb{P}(h \ge t_c) = \exp\left( - q_{\text{adj}} \cdot t_c \right)$$

Combining these yields the operational yielding probability:

$$P(\text{yield}) = \rho_{\text{app}} \cdot (1 - P_{\text{loss}}) \cdot \left[ 1 - \exp\left( - \frac{\sigma_{\text{audio}}}{d_{\text{amb}} + \epsilon} \right) \right] \cdot \eta_{\text{compliance}} \cdot \exp\left( - q_{\text{adj}} \cdot t_c \right)$$

---

### 3.3 Exact Discrete Binomial Chance-Constrained Invariant
Assuming independent yielding trials among queued vehicles, the residual blocking queue $N_{\text{rem}}$ follows a Binomial distribution:

$$N_{\text{rem}} \sim \operatorname{Binomial}\big(N_k, \, 1 - P(\text{yield})\big)$$

#### The Model-Based Chance Constraint:
$$\mathbb{P}\Big( T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}_k(t) \Big) \ge 1 - \varepsilon$$

Where $\varepsilon \in (0, 1)$ is the chosen model risk tolerance (e.g., $\varepsilon = 0.01$ denotes a 99% safety confidence bound under the assumed distribution).

#### Exact Discrete Quantile Evaluation:
The critical residual queue $N_{\text{crit}}$ is evaluated directly via the **Exact Binomial Inverse Cumulative Distribution Function**:

$$N_{\text{crit}} = F^{-1}_{\text{Bin}}\big(1 - \varepsilon \;\big|\; N_k, 1 - P(\text{yield})\big) = \min \left\{ n \in \{0, \dots, N_k\} \;\middle|\; \sum_{i=0}^n \binom{N_k}{i} \big(1 - P_{\text{yield}}\big)^i P_{\text{yield}}^{N_k - i} \ge 1 - \varepsilon \right\}$$

#### Event-Driven Trigger Condition:
Preemption is initiated at the first boundary-crossing instant $\tau^*$:

$$\tau^* = \inf \left\{ t \ge 0 \;\middle|\; \text{ETA}_k(t) \le t_L + \frac{N_{\text{crit}}}{q_{\max}} + T_{\text{transition}}(k) \right\}$$

---

### 3.4 Signal Controller Safety Transition Constraints (NEMA TS2 / IRC:SP:41)
$$T_{\text{transition}}(k) = \max\Big(0, g_{\min} - g_{\text{elapsed}}\Big) + t_{\text{yellow}} + t_{\text{all-red}} + \mathbb{I}_{\text{ped}} \cdot t_{\text{ped\_clear}}$$

Where $t_{\text{yellow}} = 3.5\text{ s}$, $t_{\text{all-red}} = 2.0\text{ s}$, and $g_{\min} \in [5, 8]\text{ s}$ per site-specific timing cards.

---

### 3.5 Bounded Route Cost Evaluation (Application Layer)
$$\mathcal{J}(e) = T_{\text{free}}(e) \cdot \left[ 1 + \beta \cdot \sum_{j \in \text{cross}(e)} \left( \frac{Q_j(t)}{C_j} \right)^2 \right] \cdot \left[ \frac{1}{1 + \gamma \cdot P(\text{yield})_e} \right]$$

Strictly positive: $\mathcal{J}(e) > 0 \; \forall e \in E$, guaranteeing Dijkstra convergence without negative cycles.

---

## 4. EXPERIMENTAL PROTOCOL & ABLATION METHODOLOGY

### 4.1 Simulation Environment Setup (SUMO Microscopic Simulator)
- **Simulator**: SUMO (Simulation of Urban MObility, v1.19.0) coupled via TraCI API.
- **Sublane Model**: Explicitly configured with the **SL2015 sublane model** (Erdmann, 2015) enabling continuous lateral yielding maneuvers across sublanes.
- **Car Following**: Krauss car-following model ($v_{\max} = 16.6\text{ m/s}$ civilian, $22.2\text{ m/s}$ EV; $a_{\max} = 2.5\text{ m/s}^2$, $b_{\text{emergency}} = 4.5\text{ m/s}^2$).
- **Testbed Network**: 5 consecutive signalized 4-way intersections along a 3.2 km arterial corridor with varying cross-street detector loops.

### 4.2 Benchmark Controllers Evaluated
To rigorously isolate the scientific contribution, four controllers are evaluated under identical traffic scenarios and identical driver behavioral mechanics:
1. **Baseline 1 (Fixed-Distance EVP)**: Static optical/radio preemption triggered at static $d = 300\text{ m}$.
2. **Baseline 2 (Pure Queue-Discharge EVP - Obrusník et al., 2020)**: Dynamically clears observed queue $N_k$, but assumes $P(\text{yield}) = 0$ during lookahead scheduling.
3. **Baseline 3 (Continuously Updating Reactive Observer with Yielding)**: Evaluates queue discharge continuously as vehicles yield in real-time, but lacks lookahead yielding prediction.
4. **Proposed (Chance-Constrained CC-HLP)**: Evaluates $P(\text{yield})$ dynamically and enforces the exact discrete 99% Binomial confidence quantile ($\varepsilon = 0.01$) across the lookahead horizon.

### 4.3 Evaluation Metrics (50 Paired Monte-Carlo Seeds per Configuration)
1. **EV Transit Time (s)** & **Number of EV Decelerations / Complete Stops**.
2. **Average Cross-Street Civilian Delay (s/veh)**.
3. **Actual Preemption Duration** ($t_{\text{EV\_exit}} - t_{\text{green\_onset}}$: measuring total corridor preemption duration).
4. **Post-Preemption Arterial Recovery Time (s)**.

---

## 5. SUMMARY OF SCIENTIFIC CONTRIBUTIONS
1. **Falsifiable Observer vs. Predictor Formulation**: Explicitly tests whether predictive human yielding estimation outperforms continuous reactive queue observation during signal transition decision windows.
2. **Exact Binomial Chance-Constraint**: Eliminates continuous approximation errors by applying discrete Binomial inverse CDF quantiles for small queue safety guarantees.
3. **Closing the Behavioral Loop**: First formal mathematical bridge coupling in-cabin participatory alert dynamics with traffic signal controller preemption.
================================================================================
