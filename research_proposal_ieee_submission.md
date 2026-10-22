# Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption: Integrating Mobile Participatory Alerts with Stochastic Queue Discharge Dynamics

**Authors**: Himanshu Singh et al.  
**Target Venue**: IEEE Transactions on Intelligent Transportation Systems (T-ITS) / IEEE International Conference on Intelligent Transportation Systems (ITSC)  
**Artifacts**: Public Open-Source Benchmark Suite and Per-Seed Telemetry Logs (`scratch/per_seed_benchmark_results.csv`)

---

## ABSTRACT
Emergency Vehicle Preemption (EVP) systems operate under an acute operational trade-off: triggering green waves prematurely induces severe cross-street civilian delay, while delaying activation forces emergency vehicles (EVs) to decelerate behind standing civilian queues. Classical queue-discharge preemption algorithms (e.g., Obrusník et al., 2020) adapt green onset to observed queues, but treat civilian traffic as purely passive agents that disperse only after the signal turns green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings induce voluntary lateral yielding, yet this behavioral response has remained uncoupled from signal preemption scheduling. Furthermore, emerging preemption frameworks increasingly rely on dedicated Connected Autonomous Vehicle (CAV) infrastructure, leaving mixed legacy human traffic unaddressed.

In this paper, we formulate and evaluate **Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**, a novel patentable framework that integrates time-feasible, alert-induced voluntary yielding into dynamic preemption scheduling. Each queued vehicle $i$ is modeled with an individualized yielding probability $p_i$, conditioned on dual-channel alert perception (mobile push notifications and acoustic sirens), gap acceptance, and strict maneuver deadline feasibility ($T_{\text{maneuver}} \le \Delta t_{\text{deadline}}(i)$). Because probabilities are heterogeneous, the residual blocking queue is formulated as a discrete Poisson-Binomial random variable, and preemption is scheduled via an exact discrete quantile over residual-blocker probabilities $1 - p_i$ to enforce a chance constraint: $\mathbb{P}(T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}) \ge 1 - \varepsilon$. 

We evaluate CC-HLP through an audited, 50-seed Monte Carlo microscopic discrete-event kinematic simulation across a 3.2 km, 5-intersection arterial corridor under a Common Random Numbers (CRN) paired experimental design. Benchmarking against static preemption, Obrusník et al.'s passive queue discharge, and a strictly causal 2.0-second sensor-driven reactive observer reveals a fundamental **Observer vs. Predictor Dilemma**: due to the $13\text{--}23\text{s}$ decision-horizon lag, a reactive observer that shortens preemption based on delayed physical detection experiences $3.50 \pm 0.93$ EV braking episodes per run ($a \le -2.0\text{ m/s}^2$). CC-HLP bridges this lag, reducing EV braking by **$73.7\%$** ($0.92 \pm 0.97$ episodes at $\varepsilon = 0.05$) while maintaining free-flow EV transit ($159.9 \pm 6.2\text{ s}$). Concurrently, CC-HLP saves **$11.33\text{ seconds}$ ($8.8\%$) of aggregate preemption green** ($2.27\text{ s}$ per junction) compared to Obrusník et al. ($p < 0.0001$), reducing cross-street civilian delay by **$10.09\%$** ($46.0 \pm 3.6\text{ s}$ vs. $51.2 \pm 4.7\text{ s/veh}$). System operators can tune $\varepsilon \in [0.01, 0.10]$ along an explicit Pareto frontier balancing progression safety against civilian delay.

---

## I. INTRODUCTION
Emergency service response times are critically linked to patient mortality and structure-fire survival rates. Consequently, Emergency Vehicle Preemption (EVP) has long been deployed to interrupt normal signal cycling and grant immediate right-of-way to approaching emergency vehicles (EVs). Traditional EVP architectures employ fixed optical strobe sensors, localized acoustic detectors, or static radio-frequency transponders that trigger green phases once an EV crosses a fixed distance threshold (typically 200–400 meters upstream). 

While static preemption ensures right-of-way, it suffers from two major limitations:
1. **Severe Cross-Street Gridlock**: Initiating preemption too early truncates conflicting green phases, cutting pedestrian clearance and triggering oversaturation queue spillback along intersecting arterial roads.
2. **Standing Stopline Queues**: If the approach lane is heavily queued, a fixed-distance trigger fails to allocate sufficient lead time for stationary civilian vehicles to discharge, forcing the EV to brake severely or come to a complete halt behind blocked lanes.

To mitigate civilian disruption, queue-aware preemption methods (notably Obrusník et al., 2020) dynamically estimate the queue length at the stopline and calculate the time required for standing vehicles to discharge through the green signal before EV arrival. However, these classical models operate under the foundational assumption that civilian vehicles are **passive physical obstacles** that do not move until the traffic light turns green ($P_{\text{yield}} = 0$).

Simultaneously, transportation human-factors research (e.g., Lidestam et al., 2020; NHTSA Lane Change Reports) has demonstrated that auditory and in-cabin digital alerts prompt up to 80–90% of civilian drivers to yield laterally into adjacent lanes or shoulders well before an emergency vehicle arrives. Yet, in modern traffic engineering, **in-cabin participatory alert dynamics and signal controller preemption algorithms operate as completely disjoint systems**. Signal controllers remain oblivious to voluntary lane-clearing maneuvers, while navigation apps broadcast alerts without coordinating with intersection phase controllers.

### Scientific Contribution & Patentable Inventive Step
This paper bridges this fundamental gap by introducing **Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**. The core contributions and patentable aspects include:
1. **Coupled Behavioral-Kinematic Horizon**: Formulating a mathematical bridge between participatory mobile alerts (cellular/V2X) and signal controller preemption constraints, accounting for the physical $13\text{--}23\text{s}$ decision lag ($T_{\text{transition}} + t_{\text{maneuver}}$).
2. **Exact Poisson-Binomial Chance Constraint**: Deriving an analytical discrete quantile over heterogeneous residual-blocker probabilities $q_i = 1 - p_i$ via recursive convolution, guaranteeing model-based queue clearance safety at a defined risk tolerance $\varepsilon$.
3. **Empirical Characterization of the Observer vs. Predictor Dilemma**: Demonstrating through a strictly causal, paired Monte Carlo simulation that reactive queue observation fails due to sensor polling and maneuver completion latency, whereas predictive scheduling slashes EV deceleration by $73.7\%$ while reducing civilian cross-street delay by $10.09\%$ over passive queue discharge.

---

## II. RELATED WORK & PROBLEM FORMULATION

### A. Classical and Queue-Aware Emergency Preemption
Traditional EVP systems rely on NEMA TS2 or 170/2070 controller standards, enforcing minimum green ($g_{\min}$), yellow change ($t_{\text{yellow}}$), and all-red ($t_{\text{all-red}}$) clearance intervals. Static distance-based preemption triggers green at a constant distance $d_{\text{trigger}}$. When queue lengths fluctuate stochasticity, static triggers either under-preempt (causing EV stoppage) or over-preempt (causing cross-street gridlock).

Obrusník et al. (2020) resolved static trigger inefficiency by introducing dynamic queue-discharge preemption:
$$T_{\text{clear}} = t_L + N \cdot h_s$$
Where $t_L$ is startup lost time and $h_s$ is saturation departure headway. Preemption is initiated at $\text{ETA} \le T_{\text{clear}} + T_{\text{transition}}$. While mathematically sound, Obrusník et al. treat civilian traffic as passive agents, requiring sufficient green time to flush all $N$ vehicles across the stopline.

### B. In-Cabin Warnings and Connected Vehicle Yielding
Human-factors studies demonstrate that standard acoustic sirens suffer from high sound-attenuation in modern sound-insulated vehicle cabins (ISO 7731; NHTSA DOT HS 811 144). Digital in-vehicle chimes provide advance warning, increasing driver compliance and reducing reaction times. Emerging 2025–2026 frameworks explore cooperative preemption using Connected Autonomous Vehicles (CAVs) with dedicated trajectory coordination. However, these systems assume automated vehicle control and dedicated lanes, rendering them inapplicable to existing legacy urban arterials where human drivers make discretionary lane changes.

### C. The Observer vs. Predictor Dilemma
A critical question in intelligent signal control is whether predictive estimation of yielding offers any genuine benefit over continuous reactive sensing (e.g., roadside cameras or loop detectors). 

Consider the sequence of events required to safely clear an intersection:
1. **Signal Transition Latency ($T_{\text{transition}}$)**:
   $$T_{\text{transition}} = \max(0, g_{\min} - g_{\text{elapsed}}) + t_{\text{yellow}} + t_{\text{all-red}} \approx 7.5\text{ to } 11.5\text{ s}$$
2. **Human Maneuver Latency ($t_{\text{maneuver}}$)**:
   Civilians require perception-reaction time plus lateral steering time: $T_{\text{maneuver}} \sim \operatorname{Lognormal}(\mu_m = 1.705, \sigma_m = 0.35)$, with median $5.5\text{ s}$ and 90th percentile $9.8\text{ s}$.
3. **Sequential Decision Horizon**:
   $$\Delta t_{\text{decision}} = T_{\text{transition}} + t_{\text{maneuver}} \approx 13.0\text{ to } 21.0\text{ s}$$

At an emergency cruising speed $v_{\text{EV}} = 20\text{ m/s}$ ($72\text{ km/h}$), this decision horizon corresponds to a lookahead distance $d_{\text{decision}} = v_{\text{EV}} \cdot \Delta t \approx 260\text{ to } 420\text{ meters}$.
- If a reactive observer waits until drivers physically complete their lane changes before shortening preemption, the remaining arrival time is already less than $T_{\text{transition}} + T_{\text{clear}}$, forcing the EV to brake severely.
- If an observer acts conservatively on un-cleared queues, it cuts off cross-traffic prematurely.
- **Predictive preemption overcomes this limitation by evaluating the probability distribution of future queue clearance across the lookahead horizon.**

---

## III. THE CC-HLP MATHEMATICAL FRAMEWORK

### A. Macroscopic Stopline Queue Clearance
The physical time required for $N$ standing vehicles to fully discharge across the stopline conflict boundary is modeled with an explicit boundary condition:

$$T_{\text{clear}}(N) = \begin{cases} 0, & \text{if } N = 0 \\ t_L + N \cdot h_s, & \text{if } N \ge 1 \end{cases}$$

Where:
- $t_L = 2.0\text{ s}$: Startup lost time.
- $h_s = 2.0\text{ s/veh}$: Saturation departure headway ($q_{\max} = 0.5\text{ veh/s} = 1800\text{ veh/h}$).

### B. Time-Aware Heterogeneous Yielding Probability Model
Let the intersection stopline be at position $x = 0$. Each queued vehicle $i \in \{1, \dots, N\}$ has longitudinal position $x_i(t) \le 0$ ($x_1$ closest to the stopline, $x_N$ at the queue tail). Let the ambulance be at position $x_{\text{amb}}(t) < x_i(t)$ with speed $v_{\text{EV}}$.

The distance separating the ambulance from vehicle $i$ is:
$$\Delta x_i(t) = x_i(t) - x_{\text{amb}}(t)$$

The time remaining before the ambulance reaches vehicle $i$'s safety buffer $d_{\text{safe}} = 15.0\text{ m}$ is:
$$\Delta t_{\text{deadline}}(i) = \frac{\Delta x_i(t) - d_{\text{safe}}}{v_{\text{EV}}}$$

**Strict Expiration Rule:** If $\Delta t_{\text{deadline}}(i) \le 0$, vehicle $i$'s maneuver window has expired, and its feasible yielding probability is strictly zero:
$$P(\text{feasible}_i) = \begin{cases} 0.0, & \text{if } \Delta t_{\text{deadline}}(i) \le 0 \\ \Phi_{\text{standard}}\left( \frac{\ln \Delta t_{\text{deadline}}(i) - \mu_m}{\sigma_m} \right), & \text{if } \Delta t_{\text{deadline}}(i) > 0 \end{cases}$$

Where $\Phi_{\text{standard}}(\cdot)$ is the standard normal cumulative distribution function, and $T_{\text{maneuver}} \sim \operatorname{Lognormal}(\mu_m = 1.705, \sigma_m = 0.35)$.

#### Dual-Channel Alert Perception:
We decouple acoustic siren perception from in-cabin digital mobile notifications:
$$P(\text{alert}_i) = 1 - (1 - P_{\text{mobile}}) \cdot (1 - P_{\text{acoustic}}(\Delta x_i(t)))$$

Where:
- $P_{\text{mobile}} = \rho_{\text{app}} \cdot (1 - P_{\text{loss}})$, with app adoption $\rho_{\text{app}} \in [0, 1]$ and network packet loss $P_{\text{loss}} = 0.04$.
- $P_{\text{acoustic}}(\Delta x_i) = \frac{1}{1 + \exp\left( \frac{\Delta x_i - d_{\text{mid}}}{\sigma_{\text{audio}}} \right)}$, calibrated with $d_{\text{mid}} = 180\text{ m}$ and $\sigma_{\text{audio}} = 30\text{ m}$.

#### Individual Yielding Probability:
$$p_i = P(\text{alert}_i) \cdot c_{\text{base}} \cdot P(\text{gap}) \cdot P(\text{feasible}_i)$$

Where $c_{\text{base}} = 0.92$ (driver willingness) and $P(\text{gap}) = 0.82$ (lateral gap availability in adjacent lanes/shoulders).

---

### C. Poisson-Binomial Stochastic Queue Distribution & Exact Quantile
Because individual probabilities $p_i$ vary with longitudinal position, the residual blocking queue $N_{\text{rem}}$ is the sum of non-identical Bernoulli trials:

$$N_{\text{rem}} = \sum_{i=1}^{N} (1 - X_i), \quad X_i \sim \operatorname{Bernoulli}(p_i)$$
$$N_{\text{rem}} \sim \operatorname{PoissonBinomial}\big(1 - p_1, \, 1 - p_2, \, \dots, \, 1 - p_{N}\big)$$

Where $q_i = 1 - p_i$ represents the probability that vehicle $i$ fails to yield and remains a blocker.

#### The Model-Based Chance Constraint:
$$\mathbb{P}\Big( T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}(t) \Big) \ge 1 - \varepsilon$$

Where $\varepsilon \in (0, 1)$ is the design risk tolerance (e.g., $\varepsilon = 0.05$ represents a 95% safety confidence bound).

#### Exact Discrete Quantile Evaluation via Recursive Convolution:
The critical residual queue $N_{\text{crit}}$ is evaluated directly via the exact Poisson-Binomial inverse cumulative distribution function over blocker probabilities $q_i = 1 - p_i$:

$$N_{\text{crit}} = F^{-1}_{\text{PB}}\big(1 - \varepsilon \;\big|\; 1 - p_1, \, \dots, \, 1 - p_{N}\big) = \min \left\{ n \in \{0, \dots, N\} \;\middle|\; F_{\text{PB}}(n \mid 1 - p_1, \dots, 1 - p_{N}) \ge 1 - \varepsilon \right\}$$

The discrete probability mass function (PMF) is computed via recursive convolution:
$$P_0(0) = 1.0$$
$$P_k(n) = P_{k-1}(n) \cdot p_k + P_{k-1}(n-1) \cdot (1 - p_k), \quad \forall n \in \{0, \dots, k\}$$

#### Boundary-Crossing Trigger Invariant:
Preemption is initiated at the first boundary-crossing instant $\tau^*$:
$$\tau^* = \inf \left\{ t \ge 0 \;\middle|\; \text{ETA}(t) \le T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}} \right\}$$

---

## IV. EXPERIMENTAL METHODOLOGY & CAUSAL BENCHMARK DESIGN

### A. Microscopic Discrete-Event Kinematic Simulation (MDE-KS) Setup
To provide an open-source, fully reproducible scientific benchmark without proprietary simulator dependencies, we implemented an object-oriented **Microscopic Discrete-Event Kinematic Simulation (MDE-KS)** in Python (`scratch/run_four_controller_ablation.py`):
- **Arterial Geometry**: 5 consecutive signalized intersections along a 3.2 km corridor (spacing $640\text{ m}$).
- **Continuous Kinematic Integration**: Longitudinal EV trajectory integrated at $\Delta t = 0.1\text{ s}$ time steps:
  $$a(t) = \frac{v(t) - v(t - \Delta t)}{\Delta t}$$
- **Kinematic Limits**: $v_{\text{desired}} \sim \mathcal{N}(20.0, 0.85^2)\text{ m/s}$ (bounded in $[17.5, 22.2]\text{ m/s}$ / $80\text{ km/h}$), $a_{\max} = 2.2\text{ m/s}^2$, $b_{\text{service}} = 2.5\text{ m/s}^2$, $b_{\text{emergency}} = 4.5\text{ m/s}^2$.
- **Signal Parameters**: Cycle length $C = 90\text{ s}$, nominal cross green $g_c = 35\text{ s}$, saturation flow $s = 0.50\text{ veh/s}$, cross-street demand $\lambda_{\text{cross}} = 0.16\text{ veh/s}$ ($576\text{ veh/h}$).
- **Transient Cycle-by-Cycle Webster Delay**: Cross-street delay is evaluated across the preemption cycle and subsequent recovery cycles using queue area integration $\int Q(t) dt$.
- **Common Random Numbers (CRN)**: Across each seed, identical initial queues ($N \sim \operatorname{Poisson}(\lambda=8.0)$), phase offsets ($g_{\text{elapsed}} \sim \operatorname{Uniform}(0, 20\text{s})$), EV cruising speeds, and individual driver behavioral attributes are sampled **once**. All four controllers are evaluated on the exact same physical traffic stream.

### B. Four Benchmark Controllers Evaluated
1. **Baseline 1 (Fixed-Distance EVP)**: Preemption triggers strictly when $d_{\text{EV}} \le 300\text{ m}$.
2. **Baseline 2 (Pure Queue-Discharge - Obrusník et al., 2020)**: Assumes passive traffic ($P_{\text{yield}} = 0$), calculating lead time to clear all $N_{\text{init}}$ vehicles through green.
3. **Baseline 3 (Strictly Causal Sensor-Driven Reactive Observer)**: Polls approach queue at discrete intervals ($\Delta t_{\text{sensor}} = 2.0\text{ s}$) with zero future knowledge. At each tick $t_{\text{poll}}$, counts only vehicles that have *already vacated* ($t_{\text{poll}} \ge t_{\text{vacate}}$). Triggers at the first tick where remaining ETA $\le T_{\text{clear}}(N_{\text{detected}}) + T_{\text{transition}}$.
4. **Proposed CC-HLP**: Evaluates $p_i$ dynamically and enforces the exact discrete Poisson-Binomial quantile over residual blockers.

---

## V. EXPERIMENTAL RESULTS & PAIRED STATISTICAL ANALYSIS

### A. Audited Benchmark Results (50 Seeds, \rho_app = 0.60, \varepsilon = 0.05, ddof = 1)

All metrics report sample mean $\pm$ sample standard deviation ($s$, $\text{ddof} = 1$) across $M = 50$ paired Monte Carlo seeds. Raw seed logs (200 rows) are exported to `scratch/per_seed_benchmark_results.csv`.

| Controller Strategy | EV Corridor Travel Time (s) | Braking Episodes ($a \le -2.0\text{ m/s}^2$) | Complete Stops ($v < 0.05\text{ m/s}$) | Clearance Headroom Violations | Total Corridor Preemption (s) | Cross-Street Delay (s/veh) |
|---|---|---|---|---|---|---|
| **1. Fixed-Distance (300m Static)** | $164.2\text{ s}$ ($\pm 6.4$) | $3.76$ ($\pm 1.08$) | $0.06$ ($\pm 0.24$) | $1.14$ ($\pm 0.95$) | $89.5\text{ s}$ ($\pm 3.7$) | $34.1\text{ s}$ ($\pm 1.3$)* |
| **2. Queue-Discharge (Obrusník 2020)** | $159.6\text{ s}$ ($\pm 6.2$) | $0.32$ ($\pm 0.55$) | $0.00$ ($\pm 0.00$) | $0.00$ ($\pm 0.00$) | $128.8\text{ s}$ ($\pm 11.0$) | $51.2\text{ s}$ ($\pm 4.7$) |
| **3. Reactive Observer (2s Sensor Polling)** | $162.3\text{ s}$ ($\pm 6.5$) | $3.50$ ($\pm 0.93$) | $0.00$ ($\pm 0.00$) | $0.42$ ($\pm 0.57$) | $102.5\text{ s}$ ($\pm 14.1$) | $40.5\text{ s}$ ($\pm 5.8$) |
| **4. Proposed CC-HLP ($\varepsilon = 0.05$)** | $159.9\text{ s}$ ($\pm 6.2$) | $0.92$ ($\pm 0.97$) | $0.00$ ($\pm 0.00$) | $0.00$ ($\pm 0.00$) | **$117.5\text{ s}$ ($\pm 8.5$)** | **$46.0\text{ s}$ ($\pm 3.6$)** |

*\*Note: Fixed-Distance EVP reports the lowest cross-street delay solely because it severely under-preempts, resulting in $3.76$ severe braking episodes and $1.14$ clearance violations per run.*

---

### B. Paired Student-t Hypothesis Testing (df = 49, N = 50)
Because Common Random Numbers were enforced across all 50 seeds, we evaluated paired differences:

$$\Delta X_s = X_{s, \text{Baseline}} - X_{s, \text{CC-HLP}}$$

1. **Cross-Street Delay Savings vs. Obrusník et al. (2020)**:
   $$\Delta \text{Delay} = 5.16\text{ s/veh} \quad [95\%\text{ CI: } 4.71, 5.61\text{ s/veh}], \quad t = 23.01, \quad p < 0.0001$$
   **CC-HLP delivers a statistically significant $10.09\%$ reduction in cross-street delay.**
2. **Preemption Duration Saved vs. Obrusník et al. (2020)**:
   $$\Delta \text{Preempt} = 11.33\text{ s} \quad [95\%\text{ CI: } 10.36, 12.30\text{ s}], \quad t = 23.44, \quad p < 0.0001$$
   **CC-HLP saves $2.27\text{ seconds}$ of preemption green per intersection ($11.33\text{s}$ total along corridor).**
3. **Braking Episodes Avoided vs. Reactive Observer**:
   $$\Delta \text{Braking} = 2.58\text{ episodes} \quad [95\%\text{ CI: } 2.24, 2.92\text{ episodes}], \quad t = 15.22, \quad p < 0.0001$$
   **CC-HLP slashes EV deceleration episodes by $73.7\%$ compared to the reactive observer.**
4. **EV Travel Time Saved vs. Reactive Observer**:
   $$\Delta \text{Time} = 2.40\text{ s} \quad [95\%\text{ CI: } 1.94, 2.87\text{ s}], \quad t = 10.32, \quad p < 0.0001$$
   **CC-HLP eliminates transit lag, matching free-flow speed ($159.9\text{s}$ vs $159.6\text{s}$).**

---

## VI. SENSITIVITY ANALYSIS & THE PARETO FRONTIER

### A. The Explicit Pareto Frontier: Risk Tuning Across \varepsilon

By adjusting the risk tolerance parameter $\varepsilon \in [0.01, 0.10]$, system operators navigate a smooth Pareto frontier balancing civilian delay against emergency progression:

| Risk Parameter ($\varepsilon$) | Confidence Bound ($1 - \varepsilon$) | EV Travel Time (s) | Braking Episodes ($a \le -2.0\text{ m/s}^2$) | Complete Stops | Clearance Headroom Violations | Total Preemption (s) | Cross-Street Delay (s/veh) |
|---|---|---|---|---|---|---|---|
| **$\varepsilon = 0.01$ (Ultra-Safe)** | $99\%$ | $159.6\text{ s}$ ($\pm 6.2$) | $0.36$ ($\pm 0.63$) | $0.00$ | $0.00$ | $125.1\text{ s}$ | $49.5\text{ s}$ |
| **$\varepsilon = 0.02$ (Conservative)** | $98\%$ | $159.7\text{ s}$ ($\pm 6.2$) | $0.60$ ($\pm 0.81$) | $0.00$ | $0.00$ | $121.0\text{ s}$ | $47.6\text{ s}$ |
| **$\varepsilon = 0.05$ (Balanced Target)** | $95\%$ | $159.9\text{ s}$ ($\pm 6.2$) | $0.92$ ($\pm 0.97$) | $0.00$ | $0.00$ | $117.5\text{ s}$ | $46.0\text{ s}$ |
| **$\varepsilon = 0.10$ (Delay-Minimizing)** | $90\%$ | $160.0\text{ s}$ ($\pm 6.3$) | $1.12$ ($\pm 1.02$) | $0.00$ | $0.00$ | $114.2\text{ s}$ | $44.5\text{ s}$ |

- At $\varepsilon = 0.01$ (99% confidence), CC-HLP operates ultra-conservatively, achieving identical travel time to Obrusník ($159.6\text{s}$) with near-zero braking ($0.36$ episodes), while still saving $3.7\text{s}$ of preemption green.
- As $\varepsilon$ relaxes to $0.05$, preemption duration falls by $11.33\text{s}$, reducing civilian delay by $10.09\%$ with zero stops and zero clearance violations.

### B. App Penetration Sweep (\rho_app \in [0.0, 1.0])

| App Penetration ($\rho_{\text{app}}$) | Cross-Street Delay (s/veh) | Preemption Duration (s) | Deceleration Episodes | Complete Stops |
|---|---|---|---|---|
| **$\rho = 0.00$ (Siren Only, Legacy)** | $51.2\text{ s}$ ($\pm 4.7$) | $128.8\text{ s}$ ($\pm 11.0$) | $0.32$ | $0.00$ |
| **$\rho = 0.20$ (Early Adoption)** | $49.6\text{ s}$ ($\pm 4.3$) | $125.3\text{ s}$ ($\pm 10.1$) | $0.52$ | $0.00$ |
| **$\rho = 0.40$ (Moderate Adoption)** | $47.8\text{ s}$ ($\pm 3.9$) | $121.4\text{ s}$ ($\pm 9.2$) | $0.74$ | $0.00$ |
| **$\rho = 0.60$ (Nominal Target)** | $46.0\text{ s}$ ($\pm 3.6$) | $117.5\text{ s}$ ($\pm 8.5$) | $0.92$ | $0.00$ |
| **$\rho = 0.80$ (High Connectedness)** | $43.2\text{ s}$ ($\pm 3.1$) | $110.8\text{ s}$ ($\pm 7.4$) | $0.98$ | $0.00$ |
| **$\rho = 1.00$ (Full V2X Saturation)** | $39.8\text{ s}$ ($\pm 2.6$) | $103.2\text{ s}$ ($\pm 6.8$) | $1.02$ | $0.00$ |

- **Zero-Adoption Fallback**: When $\rho_{\text{app}} = 0.00$, the chance constraint sets $p_i \to 0$ and $N_{\text{crit}} \to N_{\text{init}}$, seamlessly recovering Obrusník's passive queue discharge.
- **Monotonic Efficiency Gain**: Full participatory penetration ($\rho = 1.0$) reduces preemption duration by $25.6\text{ seconds}$ ($19.9\%$), saving $22.3\%$ in civilian delay.

---

## VII. SYSTEM SAFETY ARCHITECTURE & FAIL-SAFE MECHANISMS

In accordance with safety engineering best practices and commercial mobile API terms of service (such as Firebase Cloud Messaging terms restricting life-critical actuation):
1. **Supplementary Advisory Role**: Mobile push notifications serve strictly as an **opportunistic driver-priming channel**, alerting drivers in advance to voluntary yielding opportunities.
2. **Fail-Safe Physical Enforcement**: Life-critical preemption execution and conflict monitoring remain exclusively under the control of the **roadside traffic signal controller** (NEMA TS2 / IRC:SP:41 standard cabinet) equipped with an independent hardware Malfunction Management Unit (MMU) / Conflict Monitor Unit (CMU). Standard emergency vehicle acoustic sirens (120 dB wail/yelp) and optical strobe emitters operate continuously as the fail-safe primary warning system.
3. **Graceful Degradation Guarantee**: If cellular communications drop or network latency spikes ($P_{\text{mobile}} = 0$), the acoustic siren remains active ($P_{\text{alert}} = P_{\text{acoustic}}$). At long distances where acoustic sirens are silent, $p_i \to 0$, causing $N_{\text{crit}} \to N_{\text{init}}$ and guaranteeing that the controller allocates full clearance green with zero safety compromise.

---

## VIII. CONCLUSION & FUTURE WORK
This paper addressed the persistent conflict between civilian traffic disruption and emergency progression by introducing **Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**. By coupling in-cabin participatory notifications with stopline queue discharge dynamics through an exact Poisson-Binomial discrete quantile, CC-HLP bridges the physical $13\text{--}23\text{s}$ decision-horizon lag.

Rigorous paired Monte Carlo evaluation under Common Random Numbers demonstrated that:
1. A sensor-driven reactive observer fails due to sensor polling and maneuver lag, suffering $3.50$ braking episodes per run.
2. CC-HLP slashes EV braking by $73.7\%$ ($0.92$ episodes) and matches free-flow transit ($159.9\text{s}$).
3. CC-HLP saves $11.33\text{ seconds}$ ($8.8\%$) of aggregate preemption green ($2.27\text{s}$ per junction, $p < 0.0001$), reducing cross-street delay by $10.09\%$ compared to passive queue discharge (Obrusník et al., 2020).
4. System operators can tune performance along an explicit Pareto frontier across $\varepsilon \in [0.01, 0.10]$.

Future work will expand CC-HLP to network-wide grid coordination and multi-agency preemption (simultaneous police and medical preemption) using macroscopic corridor testbeds.

---

## REFERENCES
1. J. Obrusník, M. Hrstka, and M. Šimůnek, "Queue-aware emergency vehicle preemption with adaptive green phase initiation," *IFAC-PapersOnLine*, vol. 53, no. 2, pp. 15321–15326, 2020.
2. B. Lidestam, R. Granlund, and M. Alfredson, "Auditory and in-vehicle visual warnings for emergency vehicle approach: Effects on driver yielding behavior and gaze distribution," *Frontiers in Psychology*, vol. 11, p. 1823, 2020.
3. National Highway Traffic Safety Administration (NHTSA), "Analysis of light vehicle lane change crashes and potential active safety system approaches," U.S. Dept. of Transportation, Tech. Rep. DOT HS 811 144, 2009.
4. Federal Highway Administration (FHWA), *Highway Capacity Manual (HCM)*, 6th ed., Transportation Research Board, Washington, DC, 2016.
5. National Electrical Manufacturers Association, *Traffic Controller Assemblies with NEMA TS 2 Requirements*, NEMA Standard TS 2-2016, Rosslyn, VA, 2016.
6. International Organization for Standardization, *Ergonomics — Danger signals for public and work areas — Auditory danger signals*, ISO Standard 7731:2003, Geneva, Switzerland, 2003.
7. F. V. Webster, "Traffic signal settings," *Road Research Technical Paper No. 39*, Her Majesty's Stationery Office, London, UK, 1958.
8. Y. Hong, "On computing the distribution function for the Poisson binomial distribution," *Computational Statistics & Data Analysis*, vol. 59, pp. 41–51, 2013.
9. Indian Roads Congress, *Guidelines on Design for Signalized Intersections*, IRC:SP:41-1994, New Delhi, India, 1994.
10. D. Krajzewicz, J. Erdmann, M. Behrisch, and L. Bieker, "Recent development and applications of SUMO - Simulation of Urban MObility," *International Journal On Advances in Systems and Measurements*, vol. 5, no. 3&4, pp. 128–138, 2012.
