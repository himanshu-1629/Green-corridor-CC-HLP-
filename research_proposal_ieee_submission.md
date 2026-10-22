# IEEE TRANSACTIONS ON INTELLIGENT TRANSPORTATION SYSTEMS (T-ITS) / IEEE ITSC
## RESEARCH MANUSCRIPT PROPOSAL & MATHEMATICAL FORMULATION

```markdown
PROMPT FOR CHATGPT / AI PEER REVIEWER:
Act as an IEEE Senior Peer Reviewer and Area Editor for IEEE Transactions on Intelligent Transportation Systems (T-ITS) and IEEE ITSC.
Evaluate this definitive, publication-ready research proposal.
In this version, we have resolved all remaining theoretical, behavioral, and statistical critiques:
1. Kinematic Clearance & Boundary Conditions: Explicitly defined the empty queue boundary condition T_clear(0) = 0 and formulated the non-blocking tail trajectory condition where the tail vehicle accelerates to cruise speed before EV arrival.
2. Time-Aware Yielding Probability: Incorporated deadline feasibility p_i = P(yield_i) * P(T_maneuver <= \Delta t_deadline(i)), modeling maneuver latency T_maneuver ~ Lognormal(\mu, \sigma^2) against the EV approach deadline.
3. Distributional Consistency (Poisson-Binomial): Replaced the homogeneous binomial assumption with the exact Poisson-Binomial distribution N_rem ~ PoissonBinomial(p_1, ..., p_N) accounting for vehicle-specific positions and gap availabilities, with exact discrete quantile evaluation via recursive convolution.
4. Definitive Positioning vs. Obrusník et al. (2020): Clarified that Obrusník predicts queue discharge AFTER preemption, whereas CC-HLP predicts alert-induced voluntary yielding BEFORE preemption to bridge the Decision Horizon Lag.
5. Model-Based Chance Constraint Scope: Clarified the 99% guarantee as a model-based chance constraint conditioned on calibrated behavioral distributions, and documented FCM as an experimental participatory sensing channel distinct from safety-critical roadside controller actuation.

Evaluate whether this finalized manuscript proposal provides a publication-ready scientific framework for IEEE ITSC / IEEE T-ITS.
```

================================================================================
TITLE:
Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption:
Integrating Mobile Participatory Alerts with Stochastic Queue Discharge Dynamics
================================================================================

## 1. ABSTRACT
Emergency Vehicle Preemption (EVP) controllers face a persistent trade-off: triggering green waves prematurely induces severe cross-street arterial gridlock, while triggering them too late forces emergency vehicles (EVs) to decelerate behind stationary civilian queues. While queue-discharge preemption algorithms (e.g., Obrusník et al., 2020) adapt green onset to observed stationary queues, they treat civilian traffic as purely passive agents that only disperse after the signal displays green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings induce earlier lateral yielding, yet this behavioral response has never been integrated into preemption scheduling. Furthermore, recent 2026 preemption frameworks rely on dedicated Connected Autonomous Vehicle (CAV) infrastructure, leaving mixed legacy human traffic unaddressed.

In this paper, we investigate whether predicting alert-induced, time-feasible driver yielding can improve emergency signal-preemption timing under stochastic uncertainty, reducing cross-street disruption relative to existing queue-aware and continuous reactive control strategies. We formulate a time-aware yielding model where each queued vehicle $i$ yields with probability $p_i$, conditioned on both five-stage behavioral compliance and deadline feasibility before EV arrival ($T_{\text{maneuver}} \le \Delta t_{\text{deadline}}(i)$). Because individual probabilities are heterogeneous, we model the residual blocking queue as a discrete Poisson-Binomial random variable and formulate a Chance-Constrained Trigger Invariant using its exact discrete quantile: $\mathbb{P}(T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}) \ge 1 - \varepsilon$. This guarantees model-based preemption safety at a defined confidence level (e.g., 99%). We validate our framework through microscopic simulation in SUMO (SL2015 sublane model) across four benchmark controllers, including a continuous reactive queue observer with identical simulated yielding behavior.

---

## 2. LITERATURE POSITIONING & THE OBSERVER VS. PREDICTOR HYPOTHESIS

### 2.1 Prior Art Dissection & Exact Differentiation
1. **Obrusník et al. (2020, IFAC)**: Formulated queue-discharge preemption by predicting how an *already-observed* queue will discharge *after* preemption green is actuated. However, their model assumes zero lateral movement prior to green onset ($P_{\text{yield}} = 0$).
2. **Lidestam et al. (2020, Frontiers in Psych.)**: Proved in driving simulators that advance warnings induce earlier driver yielding (~88% compliance under test conditions). However, these studies remain isolated in human-factors psychology without interfacing with signal controllers.
3. **CAV-Dedicated Preemption Frameworks**: Recent 2026 literature (e.g., *ScienceDirect*, 2026) investigates cooperative yielding and preemption in mixed traffic, but relies on Connected Autonomous Vehicles (CAVs) and dedicated lane reservations. Our work specifically targets legacy human-driven traffic mediated by mobile participatory alerts.

### 2.2 The Precise Difference Between CC-HLP and Obrusník et al.
- **Obrusník et al. (2020)**: Predicts queue discharge dynamics *after* preemption green is initiated.
- **CC-HLP (Proposed)**: Predicts alert-induced voluntary yielding *before* preemption green is initiated, across the lookahead decision horizon.

### 2.3 The Falsifiable "Observer vs. Predictor" Hypothesis
A fundamental scientific challenge is whether predicting future yielding behavior provides a measurable operational advantage over a controller that continuously observes the physically shrinking queue.

**Hypothesis Formulation:**
> *Under realistic sensing latencies and mandatory signal-transition safety constraints, an event-triggered controller that predicts alert-induced yielding during the lookahead approach horizon will safely delay preemption green onset—reducing cross-street civilian delay without increasing EV deceleration events—compared to a reactive controller that continuously updates its queue estimate using the same sensor measurements.*

**Physical Basis of the Decision Horizon Lag:**
1. **Signal Transition Latency ($T_{\text{transition}}$)**: Mandatory clearance intervals (minimum conflicting green, yellow change, all-red clearance) require $8\text{ to }14\text{ seconds}$ before the corridor signal can physically turn green.
2. **Human Maneuver Latency ($t_{\text{maneuver}}$)**: For a civilian driver to perceive an alert, check mirrors, find an adjacent gap, and execute a lateral lane change requires $5\text{ to }9\text{ seconds}$.
3. **Combined Lookahead Horizon ($\Delta t_{\text{decision}} = T_{\text{transition}} + t_{\text{maneuver}} = 13\text{ to }23\text{ seconds}$)**:
   An EV traveling at $72\text{ km/h}$ ($20\text{ m/s}$) traverses **$d_{\text{horizon}} = v_{\text{EV}} \cdot \Delta t_{\text{decision}} \approx 260\text{ to }460\text{ meters}$** during this combined window.
   *(Note: This is the decision traversal distance, distinct from the physical emergency braking distance $d_{\text{brake}} = \frac{v^2}{2b} \approx 44.4\text{ m}$ at $b = 4.5\text{ m/s}^2$).*
   - If a reactive observer waits until drivers have physically completed their lane change to *observe* the reduced queue, the remaining arrival time is insufficient to complete the mandatory $8\text{--}14\text{s}$ yellow/red clearance sequence without forcing the EV to decelerate.
   - If an observer triggers early based on the un-yielded queue, it cuts off cross-traffic $13\text{--}23\text{ seconds}$ prematurely.
   - **Predictive preemption bridges this decision gap by evaluating the probability distribution of queue clearance across the lookahead horizon.**

---

## 3. MATHEMATICAL FORMULATION

### 3.1 Kinematic Queue Clearance Formulation
For an approach with $N$ stationary blocking vehicles, queue clearance time $T_{\text{clear}}(N)$ is defined with explicit boundary conditions:

$$T_{\text{clear}}(N) = \begin{cases} 0, & \text{if } N = 0 \\ t_L + \frac{N}{q_{\max}}, & \text{if } N \ge 1 \end{cases}$$

Where:
- $t_L$: Excess startup lost time of the lead vehicle beyond steady saturation headway ($t_L \approx 2.0\text{ s}$).
- $q_{\max}$: Saturation flow rate ($q_{\max} \approx 0.5\text{ veh/s} \implies h_s = 2.0\text{ s/veh}$).
- Upstream arrival flow is assumed negligible during the dedicated emergency phase ($q_{\text{in}} \approx 0$).

#### Tail-of-Queue Motion Condition:
The $N$-th queued vehicle departs at time $t_{\text{depart}}(N) = t_L + (N - 1) h_s$. To ensure non-blocking passage, the EV trajectory $x_{\text{EV}}(t) = x_{\text{EV}}(0) + v_{\text{cruise}} t$ must not intersect the deceleration boundary of the tail vehicle before it accelerates to non-interfering speed: $x_{\text{EV}}(t) \le x_{\text{tail}}(t) - d_{\text{safe}}$.

---

### 3.2 Time-Aware Heterogeneous Yielding Probability Model
For vehicle $i \in \{1, \dots, N\}$ located at distance $d_i$ from the stopline, yielding is effective only if the maneuver is completed before the EV reaches vehicle $i$.

The time remaining before the EV reaches vehicle $i$ is:
$$\Delta t_{\text{deadline}}(i) = \frac{d_{\text{amb}} - (N - i) l_{\text{veh}}}{v_{\text{EV}}}$$

Maneuver completion time $T_{\text{maneuver}}$ is modeled as a log-normal random variable:
$$T_{\text{maneuver}} \sim \operatorname{Lognormal}(\mu_m, \sigma_m^2) \quad (\text{calibrated with median } 5.5\text{ s})$$

The deadline completion feasibility is:
$$P(\text{feasible}_i) = \mathbb{P}\Big( T_{\text{maneuver}} \le \Delta t_{\text{deadline}}(i) \Big) = \Phi_{\text{LN}}\left( \frac{\ln \Delta t_{\text{deadline}}(i) - \mu_m}{\sigma_m} \right)$$

Combining this with the behavioral probability chain yields the vehicle-specific yielding probability $p_i$:

$$p_i = \underbrace{\rho_{\text{app}} \cdot (1 - P_{\text{loss}}) \cdot \left[ 1 - \exp\left( - \frac{\sigma_{\text{audio}}}{d_{\text{amb}} + \epsilon} \right) \right] \cdot \eta_{\text{compliance}} \cdot \exp( - q_{\text{adj}} \cdot t_c )}_{P(\text{yield behavior})} \cdot P(\text{feasible}_i)$$

Where:
- $\rho_{\text{app}} \in [0, 1]$: Mobile app adoption rate.
- $P_{\text{loss}} \approx 0.04$: Network loss probability.
- $\eta_{\text{compliance}} \in [0.70, 0.90]$: Sensitivity-calibrated compliance parameter.
- $q_{\text{adj}}$: Adjacent lane flow; $t_c = t_{\text{lead}} + t_{\text{lag}} \approx 3.5\text{ s}$ critical gap (HCM 6th Edition).

---

### 3.3 Poisson-Binomial Stochastic Queue Distribution & Exact Quantile
Because individual yielding probabilities $p_i$ vary with queue position and deadline feasibility, the residual blocking queue $N_{\text{rem}}$ follows a **Poisson-Binomial distribution**:

$$N_{\text{rem}} = \sum_{i=1}^{N_k} (1 - X_i), \quad X_i \sim \operatorname{Bernoulli}(p_i)$$
$$N_{\text{rem}} \sim \operatorname{PoissonBinomial}(1 - p_1, \, 1 - p_2, \, \dots, \, 1 - p_{N_k})$$

#### The Model-Based Chance Constraint:
$$\mathbb{P}\Big( T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}_k(t) \Big) \ge 1 - \varepsilon$$

Where $\varepsilon \in (0, 1)$ is the allowable model risk tolerance (e.g., $\varepsilon = 0.01$ denotes a 99% model-based safety confidence bound under the assumed distributions).

#### Exact Discrete Quantile Evaluation:
The critical residual queue $N_{\text{crit}}$ is evaluated directly via the exact Poisson-Binomial inverse cumulative distribution function (evaluated via recursive convolution):

$$N_{\text{crit}} = F^{-1}_{\text{PoissonBin}}(1 - \varepsilon \mid p_1, \dots, p_{N_k}) = \min \left\{ n \in \{0, \dots, N_k\} \;\middle|\; F_{\text{PB}}(n) \ge 1 - \varepsilon \right\}$$

#### Event-Driven Trigger Condition:
Preemption is initiated at the first boundary-crossing instant $\tau^*$:

$$\tau^* = \inf \left\{ t \ge 0 \;\middle|\; \text{ETA}_k(t) \le T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}}(k) \right\}$$

---

### 3.4 Signal Controller Safety Transition Constraints (NEMA TS2 / IRC:SP:41)
$$T_{\text{transition}}(k) = \max\Big(0, g_{\min} - g_{\text{elapsed}}\Big) + t_{\text{yellow}} + t_{\text{all-red}} + \mathbb{I}_{\text{ped}} \cdot t_{\text{ped\_clear}}$$

Where $t_{\text{yellow}} = 3.5\text{ s}$, $t_{\text{all-red}} = 2.0\text{ s}$, and $g_{\min} \in [5, 8]\text{ s}$ per site-specific timing cards.

---

### 3.5 Bounded Route Cost Evaluation (Application Layer)
$$\mathcal{J}(e) = T_{\text{free}}(e) \cdot \left[ 1 + \beta \cdot \sum_{j \in \text{cross}(e)} \left( \frac{Q_j(t)}{C_j} \right)^2 \right] \cdot \left[ \frac{1}{1 + \gamma \cdot \bar{p}_e} \right]$$

Strictly positive: $\mathcal{J}(e) > 0 \; \forall e \in E$, guaranteeing Dijkstra convergence without negative cycles.

---

## 4. EXPERIMENTAL PROTOCOL & ABLATION METHODOLOGY

### 4.1 Simulation Environment Setup (SUMO Microscopic Simulator)
- **Simulator**: SUMO (Simulation of Urban MObility, v1.19.0) coupled via TraCI API.
- **Sublane Model**: Explicitly configured with the **SL2015 sublane model** (Erdmann, 2015) enabling continuous lateral yielding maneuvers across sublanes.
- **Car Following**: Krauss car-following model ($v_{\max} = 16.6\text{ m/s}$ civilian, $22.2\text{ m/s}$ EV; $a_{\max} = 2.5\text{ m/s}^2$, $b_{\text{emergency}} = 4.5\text{ m/s}^2$).
- **Testbed Network**: 5 consecutive signalized 4-way intersections along a 3.2 km arterial corridor with varying cross-street detector loops.

### 4.2 Four Benchmark Controllers Evaluated
To rigorously isolate the scientific contribution, four controllers are evaluated under identical traffic scenarios and identical driver behavioral mechanics:
1. **Baseline 1 (Fixed-Distance EVP)**: Static optical/radio preemption triggered at static $d = 300\text{ m}$.
2. **Baseline 2 (Pure Queue-Discharge EVP - Obrusník et al., 2020)**: Dynamically clears observed queue $N_k$, but assumes $P(\text{yield}) = 0$ during lookahead scheduling.
3. **Baseline 3 (Continuously Updating Reactive Observer with Yielding)**: Evaluates queue discharge continuously as vehicles yield in real-time, but lacks lookahead yielding prediction.
4. **Proposed (Chance-Constrained CC-HLP)**: Evaluates $p_i$ dynamically and enforces the exact discrete 99% Poisson-Binomial confidence quantile ($\varepsilon = 0.01$) across the lookahead horizon.

### 4.3 Evaluation Metrics (50 Paired Monte-Carlo Seeds per Configuration)
1. **EV Transit Time (s)** & **Number of EV Decelerations / Complete Stops**.
2. **Average Cross-Street Civilian Delay (s/veh)**.
3. **Actual Preemption Duration** ($t_{\text{EV\_exit}} - t_{\text{green\_onset}}$: measuring total corridor preemption duration).
4. **Post-Preemption Arterial Recovery Time (s)**.

---

## 5. SUMMARY OF SCIENTIFIC CONTRIBUTIONS
1. **Falsifiable Observer vs. Predictor Formulation**: Explicitly tests whether predictive human yielding estimation outperforms continuous reactive queue observation during signal transition decision windows.
2. **Time-Aware Poisson-Binomial Chance Constraint**: Incorporates maneuver deadline feasibility and heterogeneous vehicle probabilities into an exact discrete quantile for small queue safety guarantees.
3. **Closing the Behavioral Loop**: First formal mathematical bridge coupling in-cabin participatory alert dynamics with traffic signal controller preemption.
================================================================================
