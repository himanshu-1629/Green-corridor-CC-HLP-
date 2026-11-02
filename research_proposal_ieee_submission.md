# Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption: Integrating Mobile Participatory Alerts with Stochastic Queue Discharge Dynamics

**Author**: Himanshu Singh (himanshugangasingh12@gmail.com)  
**Affiliation**: Department of Computer Science and Engineering, Advanced Traffic and Cyber-Physical Systems Lab  
**Target Venue**: IEEE Transactions on Intelligent Transportation Systems (T-ITS) / IEEE International Conference on Intelligent Transportation Systems (ITSC)  
**Artifacts**: Public Open-Source Benchmark Suite and Per-Seed Telemetry Logs (`scratch/per_seed_benchmark_results.csv`)

---

## ABSTRACT
Emergency Vehicle Preemption (EVP) systems operate under an acute operational trade-off: triggering green waves prematurely induces severe cross-street civilian delay, while delaying activation forces emergency vehicles (EVs) to decelerate behind standing civilian queues. Classical queue-discharge preemption algorithms (e.g., Obrusník et al., 2020) adapt green onset to observed queues, but treat civilian traffic as purely passive agents that disperse only after the signal turns green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings significantly increase drivers' propensity to give way and reduce reaction latencies, yet this behavioral response has remained uncoupled from signal preemption scheduling. Furthermore, emerging preemption frameworks increasingly rely on dedicated Connected Autonomous Vehicle (CAV) infrastructure, leaving mixed legacy human traffic unaddressed.

In this paper, we formulate and evaluate **Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**, a stochastic preemption framework that integrates time-feasible, alert-induced voluntary yielding into dynamic preemption scheduling. Each queued vehicle $i$ is modeled with an individualized yielding probability $p_i$, conditioned on dual-channel alert perception (mobile push notifications and acoustic sirens), gap acceptance, and strict maneuver deadline feasibility ($T_{\text{maneuver}} \le \Delta t_{\text{deadline}}(i)$). Because probabilities are heterogeneous, the residual blocking queue is formulated as a discrete Poisson-Binomial random variable, and preemption is scheduled via an exact discrete quantile over residual-blocker probabilities $1 - p_i$ to enforce a model-based chance constraint: $\mathbb{P}(T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA}) \ge 1 - \varepsilon$. 

We evaluate CC-HLP through an audited, 50-seed Monte Carlo microscopic discrete-event kinematic simulation across a 3.2 km, 5-intersection arterial corridor under a Common Random Numbers (CRN) paired experimental design. Benchmarking against static preemption, Obrusník et al.'s passive queue discharge, and a strictly causal 2.0-second sensor-driven reactive observer reveals a fundamental **Observer vs. Predictor Dilemma**: due to the sequential decision horizon spanning $\Delta t_{\text{decision}} \in [11.0, 23.3]\text{ s}$ (nominal $\approx 13.0\text{ s}$, lookahead distance $220\text{ to } 466\text{ m}$, nominal $\approx 260\text{ m}$), a reactive observer that shortens preemption based on delayed physical detection experiences $3.50 \pm 0.93$ EV braking episodes per run ($a \le -2.0\text{ m/s}^2$). CC-HLP bridges this lag, establishing a balanced Pareto-optimal trade-off: it reduces EV braking by **$73.7\%$** ($0.92 \pm 0.97$ episodes at $\varepsilon = 0.05$) relative to the reactive observer while maintaining free-flow EV transit ($159.9 \pm 6.2\text{ s}$). Concurrently, CC-HLP saves **$11.33\text{ seconds}$ ($8.8\%$) of aggregate preemption green** ($2.27\text{ s}$ per junction) compared to Obrusník et al. ($p < 0.0001$), reducing cross-street civilian delay by **$10.09\%$** ($46.0 \pm 3.6\text{ s}$ vs. $51.2 \pm 4.7\text{ s/veh}$). System operators can tune $\varepsilon \in [0.01, 0.10]$ along an explicit Pareto frontier balancing progression safety against civilian delay.

---

## I. INTRODUCTION
Emergency service response times are critically linked to patient mortality and structure-fire survival rates. Consequently, Emergency Vehicle Preemption (EVP) has long been deployed to interrupt normal signal cycling and grant immediate right-of-way to approaching emergency vehicles (EVs). Traditional EVP architectures employ fixed optical strobe sensors, localized acoustic detectors, or static radio-frequency transponders that trigger green phases once an EV crosses a fixed distance threshold (typically 200–400 meters upstream). 

While static preemption ensures right-of-way, it suffers from two major limitations:
1. **Severe Cross-Street Gridlock**: Initiating preemption too early truncates conflicting green phases, cutting pedestrian clearance and triggering oversaturation queue spillback along intersecting arterial roads.
2. **Standing Stopline Queues**: If the approach lane is heavily queued, a fixed-distance trigger fails to allocate sufficient lead time for stationary civilian vehicles to discharge, forcing the EV to brake severely or come to a complete halt behind blocked lanes.

To mitigate civilian disruption, queue-aware preemption methods (notably Obrusník et al., 2020) dynamically estimate the queue length at the stopline and calculate the time required for standing vehicles to discharge through the green signal before EV arrival. However, these classical models operate under the foundational assumption that civilian vehicles are **passive physical obstacles** that do not move until the traffic light turns green ($P_{\text{yield}} = 0$).

Simultaneously, transportation human-factors research (e.g., Lidestam et al., 2020; NHTSA reports) has demonstrated that auditory and in-cabin digital alerts significantly increase drivers' propensity to give way and reduce reaction latencies compared to conventional sirens alone, prompting voluntary lateral lane changes into adjacent lanes or shoulders before the emergency vehicle arrives. Yet, in modern traffic engineering, **in-cabin participatory alert dynamics and signal controller preemption algorithms operate as completely disjoint systems**. Signal controllers remain oblivious to voluntary lane-clearing maneuvers, while navigation apps broadcast alerts without coordinating with intersection phase controllers.

### Scientific Contribution
This paper bridges this fundamental gap by introducing **Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**. The core contributions include:
1. **Coupled Behavioral-Kinematic Horizon**: Formulating a mathematical bridge between participatory mobile alerts (cellular/V2X) and signal controller preemption constraints, accounting for the physical sequential decision horizon spanning $\Delta t_{\text{decision}} \in [11.0, 23.3]\text{ s}$ ($T_{\text{transition}} + t_{\text{maneuver}}$, nominal $\approx 13.0\text{ s}$).
2. **Exact Poisson-Binomial Chance Constraint**: Deriving an analytical discrete quantile over heterogeneous residual-blocker probabilities $q_i = 1 - p_i$ via recursive convolution, guaranteeing model-based queue clearance safety at a defined risk tolerance $\varepsilon$.
3. **Empirical Characterization of the Observer vs. Predictor Dilemma**: Demonstrating through a strictly causal, paired Monte Carlo simulation that reactive queue observation fails due to sensor polling and maneuver completion latency, whereas predictive scheduling achieves a Pareto-optimal trade-off slashing EV deceleration by $73.7\%$ while reducing civilian cross-street delay by $10.09\%$ over passive queue discharge.

---

## II. RELATED WORK & PROBLEM FORMULATION

### A. Classical and Queue-Aware Emergency Preemption
Traditional EVP systems rely on NEMA TS2 or 170/2070 controller standards, enforcing minimum green ($g_{\min}$), yellow change ($t_{\text{yellow}}$), and all-red ($t_{\text{all-red}}$) clearance intervals. Static distance-based preemption triggers green at a constant distance $d_{\text{trigger}}$, typically utilizing optical strobe sensors or roadside cameras (e.g., vision-based emergency light-bar detection and priority override frameworks; Sharma et al., IEEE Access 2026). When queue lengths fluctuate stochastically, static triggers either under-preempt (causing EV stoppage) or over-preempt (causing cross-street gridlock) because they possess no lookahead knowledge of standing stopline queues or civilian maneuver delays.

Obrusník et al. (2020) resolved static trigger inefficiency by introducing dynamic queue-discharge preemption:
$$T_{\text{clear}} = t_L + N \cdot h_s$$
Where $t_L$ is startup lost time and $h_s$ is saturation departure headway. Preemption is initiated at $\text{ETA} \le T_{\text{clear}} + T_{\text{transition}}$. While mathematically sound, Obrusník et al. treat civilian traffic as passive agents, requiring sufficient green time to flush all $N$ vehicles across the stopline.

### B. In-Cabin Warnings and Connected Vehicle Yielding
Human-factors studies demonstrate that standard acoustic sirens suffer from high sound-attenuation in modern sound-insulated vehicle cabins (ISO 7731), while driver lateral maneuver execution times and headway acceptance are documented in light-vehicle crash analysis (NHTSA). In a dedicated empirical investigation, Lidestam et al. (2020) showed that in-car auditory and visual warnings markedly enhance driver yielding compliance and situational awareness.

Recent connected vehicle frameworks investigate automated preemption: Ding et al. (2024) formulate V2X-supported, deep reinforcement learning (DRL)-assisted mobility-aware lane changing for emergency vehicle preemption in connected autonomous transport systems. While demonstrating substantial progression benefits for automated fleets, their focus is on autonomous vehicle control rather than modeling the stochastic perception latencies and voluntary compliance of human drivers in mixed legacy traffic. In the patent literature, Sony Group Corporation's patent application US 2026/0188114 A1 describes distributing emergency-route notifications to navigation client devices to prompt cooperative vehicle maneuvers. However, its claims focus on client-side route messaging and cooperative maneuvering instructions, without incorporating deadline-conditioned human yielding probabilities or a chance-constrained signal preemption trigger. Furthermore, earlier patent disclosures such as Bachelder's cellular-based preemption system (US 7,868,783 B2) demonstrate that utilizing vehicle position reports, estimated arrival times, and probabilistic preemption criteria is established in general emergency signal priority. Similarly, recent route-level priority frameworks (e.g., Heusser et al., US 2026/0266618 A1) coordinate dynamic emergency routing with signal priority across multiple upcoming intersections, while probabilistic arrival studies (e.g., Roja Ramani et al., ICOEI 2026) evaluate arrival-time uncertainty using Monte Carlo simulation. However, these prior approaches address arrival uncertainty or static queue clearing under passive traffic; they do not model the deadline-constrained probability of individual human drivers yielding along approach queues or formulate roadside preemption via a chance-constrained residual-queue quantile. Within the prior works reviewed, we found no study that models the stochastic maneuver deadline feasibility of human drivers and couples an exact discrete residual-queue quantile into roadside traffic-signal controller transition constraints across the critical sequential decision horizon spanning $\Delta t_{\text{decision}} \in [11.0, 23.3]\text{ s}$ (nominal $\approx 13.0\text{ s}$).

### C. The Observer vs. Predictor Dilemma
A critical question in intelligent signal control is whether predictive estimation of yielding offers any genuine benefit over continuous reactive sensing (e.g., roadside cameras or loop detectors). 

Consider the sequence of events required to safely clear an intersection:
1. **Signal Transition Latency ($T_{\text{transition}}$)**:
   $$T_{\text{transition}} = \max(0, g_{\min} - g_{\text{elapsed}}) + t_{\text{yellow}} + t_{\text{all-red}}$$
   With $g_{\min} \in [6.0, 8.0]\text{ s}$, $t_{\text{yellow}} = 3.5\text{ s}$, and $t_{\text{all-red}} = 2.0\text{ s}$, transition latency spans $T_{\text{transition}} \in [5.5, 13.5]\text{ s}$ (with average $\approx 8.0\text{ s}$).
2. **Human Maneuver Latency ($t_{\text{maneuver}}$)**:
   Civilians require perception-reaction time plus lateral steering time: $T_{\text{maneuver}} \sim \operatorname{Lognormal}(\mu_m = 1.705, \sigma_m = 0.35)$, with median $\exp(\mu_m) = 5.5\text{ s}$, 90th percentile $8.6\text{ s}$, and 95th percentile $\exp(\mu_m + 1.645\sigma_m) = 9.8\text{ s}$.
3. **Sequential Decision Horizon**:
   $$\Delta t_{\text{decision}} = T_{\text{transition}} + t_{\text{maneuver}} \in [11.0, 23.3]\text{ s}$$
   spanning an absolute minimum of $11.0\text{ s}$ ($T_{\text{transition}}^{\min} + t_{\text{maneuver}}^{\text{median}} = 5.5 + 5.5\text{ s}$), a nominal operating horizon of $\approx 13.0\text{ s}$ ($T_{\text{transition}}^{\text{nom}} + t_{\text{maneuver}}^{\text{median}} = 7.5 + 5.5\text{ s}$), up to a conservative worst-case bound of $23.3\text{ s}$ ($T_{\text{transition}}^{\max} + t_{\text{maneuver}}^{\text{95th}} = 13.5 + 9.8\text{ s}$).

At an emergency cruising speed $v_{\text{EV}} = 20\text{ m/s}$ ($72\text{ km/h}$), this decision horizon corresponds to a lookahead distance $d_{\text{decision}} = v_{\text{EV}} \cdot \Delta t \approx 220\text{ to } 466\text{ meters}$ (nominal $\approx 260\text{ m}$).
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

Where $\Phi_{\text{standard}}(\cdot)$ is the standard normal cumulative distribution function, and $T_{\text{maneuver}}$ is modeled via an assumed lognormal distribution $\operatorname{Lognormal}(\mu_m = 1.705, \sigma_m = 0.35)$ (median $5.5\text{ s}$, 90th percentile $8.6\text{ s}$, 95th percentile $9.8\text{ s}$) calibrated to reflect empirical bounds for typical human perception-reaction and discretionary lateral steering execution times (cf. NHTSA light vehicle lane change observations).

#### Dual-Channel Alert Perception:
We decouple acoustic siren perception from in-cabin digital mobile notifications:
$$P(\text{alert}_i) = 1 - (1 - P_{\text{mobile}}) \cdot (1 - P_{\text{acoustic}}(\Delta x_i(t)))$$

Where:
- $P_{\text{mobile}} = \rho_{\text{app}} \cdot (1 - P_{\text{loss}})$, with app adoption $\rho_{\text{app}} \in [0, 1]$ and network packet loss $P_{\text{loss}} = 0.04$ calibrated to 3GPP cellular-V2X (C-V2X) urban communication standards.
- $P_{\text{acoustic}}(\Delta x_i) = \frac{1}{1 + \exp\left( \frac{\Delta x_i - d_{\text{mid}}}{\sigma_{\text{audio}}} \right)}$, a phenomenological logistic attenuation kernel with midpoint $d_{\text{mid}} = 180\text{ m}$ and scale $\sigma_{\text{audio}} = 30\text{ m}$ chosen to represent rapid acoustic detection degradation in modern sound-insulated passenger cabins under urban ambient background noise (informed by auditory danger signal principles in ISO 7731).

#### Individual Yielding Probability & Parameter Calibration:
$$p_i = P(\text{alert}_i) \cdot c_{\text{base}} \cdot P(\text{gap}) \cdot P(\text{feasible}_i)$$

Parameters represent nominal simulation calibrations:
- $c_{\text{base}} = 0.92$: Nominal assumed baseline compliance parameter. While empirical in-vehicle alert studies (Lidestam et al., 2020) confirm that warning displays significantly improve yielding propensity, we treat $c_{\text{base}}$ as a simulation parameter representing high driver willingness in unobstructed conditions.
- $P(\text{gap}) = 0.82$: Nominal assumed gap availability parameter, representing the probability that a yielding driver finds a suitable adjacent lane gap or traversable shoulder under moderate arterial traffic demand (consistent with Poisson headway acceptance $P(\text{gap}) = \exp(-q_{\text{adj}} t_c / 3600) \approx 0.82$ under $q_{\text{adj}} \approx 200\text{--}250\text{ veh/h}$ and critical gap $t_c = 3.5\text{ s}$ per HCM).
Section VI provides sensitivity analysis across app adoption $\rho_{\text{app}} \in [0.0, 1.0]$ and risk tolerance $\varepsilon \in [0.01, 0.10]$ to evaluate robustness under parameter variation.

---

### C. Poisson-Binomial Stochastic Queue Distribution & Exact Quantile

Assumption 1 (Conditional Independence): Conditional on individual maneuver deadlines $\Delta t_{\text{deadline}}(i)$, ambient gap arrival rates, and alert delivery, individual driver yielding decisions are modeled as conditionally independent Bernoulli trials. While correlated yielding behavior (e.g., platooned lateral clearing) may occur in dense congestion, the independent formulation provides a tractable discrete distribution that accurately captures longitudinal heterogeneity along the queue.

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

The discrete probability mass function (PMF) is computed via exact $O(N^2)$ recursive discrete convolution:
$$P_0(0) = 1.0$$
$$P_k(n) = P_{k-1}(n) \cdot p_k + P_{k-1}(n-1) \cdot (1 - p_k), \quad \forall n \in \{0, \dots, k\}$$

#### Boundary-Crossing Trigger Invariant:
Preemption is initiated at the first boundary-crossing instant $\tau^*$:
$$\tau^* = \inf \left\{ t \ge 0 \;\middle|\; \text{ETA}(t) \le T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}} \right\}$$

### D. Theoretical Guarantee: Zero-Adoption Baseline Recovery (Proposition 1)
A foundational property of CC-HLP is its provable finite-queue convergence to the passive queue-discharge baseline when connected advisory penetration is absent ($\rho_{\text{app}} = 0.0$):

**Proposition 1 (Zero-Adoption Fallback Equivalence):**
*Let connected participatory app adoption be absent ($\rho_{\text{app}} = 0.0$), such that warning delivery relies exclusively on localized acoustic siren perception ($P(\text{alert}_i) = P_{\text{acoustic}}(\Delta x_i)$). Let $N \in \mathbb{N}_0$ queued vehicles occupy positions $x_i \in [-N \cdot l_{\text{veh}}, 0]$ upstream of the stopline ($x = 0$), with queue tail at $x_N = -N \cdot l_{\text{veh}}$ and slot length $l_{\text{veh}} = 7.5\text{ m}$. For any physically admissible signal transition latency $T_{\text{transition}} \ge T_{\text{transition}}^{\min} = 5.5\text{ s}$, lost time $t_L = 2.0\text{ s}$, saturation headway $h_s = 2.0\text{ s/veh}$, and EV speed $v_{\text{EV}} = 20\text{ m/s}$:*
1. **Monotonic Spatial Separation:** At the preemption decision horizon $\text{ETA} = T_{\text{clear}}(N) + T_{\text{transition}}$, the physical separation from the EV to every queued vehicle $i \in \{1, \dots, N\}$ satisfies:
   $$\Delta x_i(N) \ge \Delta x_{\text{tail}}(N) = v_{\text{EV}} \cdot (T_{\text{transition}} + t_L) + N \cdot (v_{\text{EV}} \cdot h_s - l_{\text{veh}}) \ge 150.0 + 32.5 \cdot N\text{ meters}$$
   yielding a strictly positive longitudinal separation gradient of $+32.5\text{ m}$ per queued vehicle.
2. **Universal Quantile Invariance:** Across all queue sizes $N \ge 1$ and design risk tolerances $\varepsilon \in [0.01, 0.10]$, individual yielding probabilities are bounded by the strictly decreasing $N$-dependent upper bound:
   $$p_i \le \bar{p}(N) \equiv 0.755 \cdot \frac{1}{1 + \exp\left( \frac{32.5 N - 30.0}{30.0} \right)}$$
   ensuring that the product of residual-blocker probabilities $q_i = 1 - p_i$ satisfies:
   $$\prod_{i=1}^N q_i \ge [1 - \bar{p}(N)]^N > \varepsilon \quad \Longleftrightarrow \quad F_{\text{PB}}(N - 1) < 1 - \varepsilon$$

   Specifically:
   - For $N = 1$: $\Delta x_{\text{tail}}(1) \ge 182.5\text{ m} \implies \bar{p}(1) \approx 0.3618$, yielding $q_1 \ge 0.6382 \gg \varepsilon = 0.05$. Hence $F_{\text{PB}}(0) \le 0.3618 < 1 - \varepsilon$, forcing $N_{\text{crit}} = 1$.
   - For $N = 2$: $\Delta x_{\text{tail}}(2) \ge 215.0\text{ m} \implies \bar{p}(2) \approx 0.1793$, yielding $\prod_{i=1}^2 q_i \ge (1 - 0.1793)^2 \approx 0.6736 \gg \varepsilon$. Thus $F_{\text{PB}}(1) \le 0.3264 < 1 - \varepsilon$, forcing $N_{\text{crit}} = 2$.
   - For $N = 3$: $\Delta x_{\text{tail}}(3) \ge 247.5\text{ m} \implies \bar{p}(3) \approx 0.0720$, yielding $\prod_{i=1}^3 q_i \ge (1 - 0.0720)^3 \approx 0.7992 \gg \varepsilon$. Thus $F_{\text{PB}}(2) \le 0.2008 < 1 - \varepsilon$, forcing $N_{\text{crit}} = 3$.
   - For $N = 4$: $\Delta x_{\text{tail}}(4) \ge 280.0\text{ m} \implies \bar{p}(4) \approx 0.026006$, yielding $\prod_{i=1}^4 q_i \ge (1 - 0.026006)^4 \approx 0.89996 > 0.10 \ge \varepsilon$. Thus $F_{\text{PB}}(3) \le 0.10004 \le 1 - \varepsilon$, forcing $N_{\text{crit}} = 4$.
   - For $N \ge 5$: utilizing the inequality $1 + e^z > e^z$, individual yielding is bounded by $\bar{p}(N) < 0.755 e^{-(32.5 N - 30)/30} = 0.755 e^{1 - 13N/12}$. The product bound $g(N) = N \bar{p}(N) \le 0.755 N e^{1 - 13N/12}$ is strictly decreasing for integer $N \ge 5$, with $g(5) \le 3.775 e^{-53/12} \approx 0.0456$. By Bernoulli's inequality, for all $N \ge 5$:
     $$\prod_{i=1}^N q_i \ge [1 - \bar{p}(N)]^N \ge 1 - N \bar{p}(N) \ge 1 - 0.0456 = 0.9544 > 0.10 \ge \varepsilon$$
     strictly ensuring $F_{\text{PB}}(N - 1) \le 0.0456 \ll 1 - \varepsilon$ and $N_{\text{crit}} \equiv N$ for all $N \ge 5$.
   Consequently, the chance-constrained discrete quantile resolves identically to the initial un-cleared queue across all $N \ge 0$:
   $$N_{\text{crit}} \equiv N_{\text{init}}, \quad \forall N \ge 0$$
   and the preemption trigger instant and clearance duration collapse identically to the Obrusník-inspired passive baseline:
   $$\tau^*_{\text{CC-HLP}} \equiv \tau^*_{\text{passive}}, \quad T_{\text{clear}}(N_{\text{crit}}) \equiv T_{\text{clear}}(N_{\text{init}})$$
   yielding identical signal preemption schedules $T_{\text{preempt}, k} \equiv T_{\text{transition}, k} + T_{\text{clear}}(N_{\text{init}, k})$ at every intersection $k$.

*Proof Summary:* Follows directly from items (1) and (2). Because the roadside traffic controller locks phase transitions upon trigger evaluation $\tau^*$, subsequent acoustic siren perception occurring when the EV arrives within 180 m cannot retroactively shorten the locked signal schedule. Thus, in the absence of participatory advisory communication ($\rho_{\text{app}} = 0$), CC-HLP intrinsically recovers the passive queue-discharge baseline schedule under its stated model assumptions, providing an inherent fail-safe fallback without requiring manual override.

---

## IV. EXPERIMENTAL METHODOLOGY & CAUSAL BENCHMARK DESIGN

### A. Microscopic Discrete-Event Kinematic Simulation (MDE-KS) Setup
To provide an open-source, fully reproducible scientific benchmark without proprietary simulator dependencies, we implemented an object-oriented **Microscopic Discrete-Event Kinematic Simulation (MDE-KS)** in Python (`scratch/run_four_controller_ablation.py`):
- **Arterial Geometry**: 5 consecutive signalized intersections along a 3.2 km arterial corridor. The emergency vehicle begins at dispatch origin $x = 0$ with an initial 640 m approach to the first intersection at $x = 640\text{ m}$, followed by 4 inter-intersection links of 640 m each (intersections located at $x = 640\text{ m}, 1280\text{ m}, 1920\text{ m}, 2560\text{ m},$ and $3200\text{ m}$). The inter-intersection span between the first and fifth signal is $4 \times 640\text{ m} = 2.56\text{ km}$, yielding a total corridor transit run of $3200\text{ m} = 3.2\text{ km}$.
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

- **Mathematical Recovery of Zero-Adoption Fallback (Proposition 1)**: As formally proven in Proposition 1, when app adoption is zero ($\rho_{\text{app}} = 0.00$), acoustic siren attenuation at the preemption decision horizon ($\Delta x_i \ge 150.0 + 32.5 N\text{ m}$) bounds individual yielding by the strictly decreasing upper bound $\bar{p}(N)$, ensuring $\prod_{i=1}^N q_i \ge [1 - \bar{p}(N)]^N > \varepsilon$ and $F_{\text{PB}}(N - 1) < 1 - \varepsilon$. Consequently, the chance constraint resolves strictly to $N_{\text{crit}} \equiv N_{\text{init}}$ across all queue sizes, and the controller schedule $T_{\text{clear}}(N_{\text{crit}}) \equiv T_{\text{clear}}(N_{\text{init}})$ locks identically into the passive queue-discharge schedule (recovering the $128.8\text{ s}$ empirical mean preemption duration and $51.2\text{ s/veh}$ civilian delay). Later acoustic detection occurring when the EV arrives within 180 m cannot retroactively shorten the locked signal transition.
- **Monotonic Efficiency Gain**: Full participatory penetration ($\rho = 1.0$) reduces preemption duration by $25.6\text{ seconds}$ ($19.9\%$), saving $22.3\%$ in civilian delay.

---

## VII. SYSTEM SAFETY ARCHITECTURE & FAIL-SAFE MECHANISMS

To ensure robust cyber-physical deployment, the CC-HLP control architecture explicitly separates normal predictive operation from fail-safe degraded states:
1. **Normal Connected Mode ($\rho_{\text{app}} > 0$, Active Telemetry)**: In the presence of active participatory telemetry, CC-HLP operates as a predictive chance-constrained controller. Individual yielding probabilities $p_i$ are dynamically evaluated from the deadline-feasibility, gap-acceptance, and alert-delivery models. The roadside edge controller calculates the exact Poisson-Binomial quantile $N_{\text{crit}}$ under risk tolerance $\varepsilon$, shortening preemption lead time and capturing the documented 8.8% green savings and 10.09% civilian delay reduction.
2. **Advisory Failure and Zero-Adoption Fallback Mode ($\rho_{\text{app}} = 0$ or Latency $> 800\text{ ms}$)**: If cellular telemetry drops, latency exceeds $800\text{ ms}$, or app penetration is absent ($\rho_{\text{app}} = 0$), the digital advisory channel is disabled ($P_{\text{mobile}} = 0$). Warning delivery reverts exclusively to localized acoustic sirens. Under this degraded state, Proposition 1 guarantees that the chance constraint mathematically collapses to $N_{\text{crit}} \equiv N_{\text{init}}$. The controller automatically reverts to the conservative passive queue-discharge schedule $T_{\text{clear}}(N_{\text{init}}) = t_L + N_{\text{init}} h_s$, ensuring complete stopline queue clearance without relying on unconfirmed voluntary driver yielding.
3. **Hardware-Level Conflict Interlock (MMU/CMU)**: All physical signal actuations remain subordinate to the roadside controller cabinet (NEMA TS2 / IRC:SP:41 standard), where an independent hardware Malfunction Management Unit (MMU) or Conflict Monitor Unit (CMU) physically enforces minimum clearance intervals ($t_{\text{yellow}} \ge 3.5\text{ s}, t_{\text{all-red}} \ge 2.0\text{ s}$) and prevents conflicting greens. Emergency vehicle acoustic sirens (120 dB) and optical strobe emitters operate continuously as the primary fail-safe warning system.

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
1. V. Obrusník, I. Herman, and Z. Hurák, "Queue discharge-based emergency vehicle traffic signal preemption," *IFAC-PapersOnLine*, vol. 53, no. 2, pp. 14997–15002, 2020. doi: 10.1016/j.ifacol.2020.12.1998.
2. B. Lidestam, B. Thorslund, H. Selander, D. Näsman, and J. Dahlman, "In-car warnings of emergency vehicles approaching: Effects on car drivers' propensity to give way," *Frontiers in Sustainable Cities*, vol. 2, art. 19, 2020. doi: 10.3389/frsc.2020.00019.
3. National Highway Traffic Safety Administration (NHTSA), "Analysis of light vehicle lane change crashes and potential active safety system approaches," U.S. Dept. of Transportation, Tech. Rep. DOT HS 811 144, 2009.
4. Federal Highway Administration (FHWA), *Highway Capacity Manual (HCM)*, 6th ed., Transportation Research Board, Washington, DC, 2016.
5. National Electrical Manufacturers Association, *Traffic Controller Assemblies with NEMA TS 2 Requirements*, NEMA Standard TS 2-2016, Rosslyn, VA, 2016.
6. International Organization for Standardization, *Ergonomics — Danger signals for public and work areas — Auditory danger signals*, ISO Standard 7731:2003, Geneva, Switzerland, 2003.
7. F. V. Webster, "Traffic signal settings," *Road Research Technical Paper No. 39*, Her Majesty's Stationery Office, London, UK, 1958.
8. Y. Hong, "On computing the distribution function for the Poisson binomial distribution," *Computational Statistics & Data Analysis*, vol. 59, pp. 41–51, 2013.
9. Indian Roads Congress, *Guidelines on Design for Signalized Intersections*, IRC:SP:41-1994, New Delhi, India, 1994.
10. D. Krajzewicz, J. Erdmann, M. Behrisch, and L. Bieker, "Recent development and applications of SUMO - Simulation of Urban MObility," *International Journal On Advances in Systems and Measurements*, vol. 5, no. 3&4, pp. 128–138, 2012.
11. Z. Ding, C. Chen, X. Zhang, and Y. Wang, "V2X-enabled mobility-aware lane changing for emergency-vehicle preemption in connected autonomous transport systems," *IEEE Transactions on Intelligent Transportation Systems*, vol. 25, no. 6, pp. 5420–5432, 2024. doi: 10.1109/TITS.2023.3341200.
12. S. Tanaka and K. Yamamoto, "Information processing apparatus, system, and method for emergency vehicle route clearance," U.S. Patent Application 2026/0188114 A1, Aug. 2026.
