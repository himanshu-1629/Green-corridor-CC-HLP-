# PATENT SPECIFICATION

**TITLE OF THE INVENTION**:
SYSTEM AND METHOD FOR CHANCE-CONSTRAINED HUMAN-IN-THE-LOOP EMERGENCY VEHICLE PREEMPTION VIA OPPORTUNISTIC V2X TELEMETRY

**INVENTORS**:
Himanshu Singh et al.

**INTERNATIONAL PATENT CLASSIFICATION (IPC / CPC)**:
- **G08G 1/087**: Traffic control systems for road vehicles; override to give priority through intersections to emergency vehicles.
- **G08G 1/0967**: Systems for traffic information; systems sending variable information to vehicles.
- **H04W 4/02**: Services making use of location information for emergency dispatch and V2X.
- **G06N 7/00**: Probabilistic and stochastic reasoning models in control systems.

---

## 1. FIELD OF THE INVENTION
The present invention relates generally to intelligent transportation systems (ITS) and emergency traffic management. More particularly, the invention relates to an edge-cloud cyber-physical system (CPS) and algorithmic method that dynamically calculates signal preemption timing for emergency vehicles by predicting human driver yielding behavior in approach queues under stochastic chance constraints.

---

## 2. BACKGROUND OF THE INVENTION AND DEFICIENCIES OF PRIOR ART

### A. Background
Emergency services (ambulances, fire engines, police vehicles) require rapid arterial transit to minimize transit times during life-critical events. Traffic signal preemption systems interrupt normal cyclic operation at signalized intersections to display green phases along the emergency vehicle's approach. 

Standard signal preemption relies on static optical strobes, sirens, or localized radio triggers (e.g., Opticom™) that trigger green phases once an emergency vehicle crosses a static distance threshold (typically 200–400 meters upstream). 

### B. Deficiencies of the Prior Art
1. **The Over-Preemption / Under-Preemption Dilemma**:
   - When arterial traffic is light, static distance triggers initiate preemption far too early, needlessly holding cross streets at red and triggering severe civilian gridlock.
   - When the approach lane is heavily queued, static triggers initiate preemption too late, failing to clear standing queues before the emergency vehicle arrives. The emergency vehicle is forced to brake severely behind stationary civilian queues.
2. **Deficiencies of Queue-Discharge Preemption (e.g., Obrusník et al., 2020)**:
   - Dynamic queue-aware preemption methods (e.g., Obrusník et al., *IFAC-PapersOnLine*, 2020) estimate the number of queued vehicles $N$ at the stopline and calculate the green time required to flush the entire queue through the intersection: $T_{\text{clear}} = t_L + N \cdot h_s$.
   - **Critical Flaw**: Obrusník et al. treat all civilian drivers as **purely passive obstacles** that do not move until the signal turns green ($P_{\text{yield}} = 0$). In dense traffic ($N = 10\text{--}15\text{ vehicles}$), this requires 25–35 seconds of preemption green, causing severe cross-street oversaturation and queue spillback.
3. **Deficiencies of Open-Loop Route Alert Systems (e.g., Sony US Patent Application 2026/0188114 A1)**:
   - Systems such as Sony's US 2026/0188114 broadcast route notifications to civilian navigation smartphones near an emergency vehicle's path.
   - **Critical Flaw**: These systems are **strictly open-loop**. While civilian drivers may receive alerts and pull over, **the signal controller has zero awareness of voluntary yielding**. The traffic signal continues to assume the queue is fully blocked or static, failing to translate driver yielding into reduced preemption green duration.
4. **Deficiencies of Reactive Sensor Observation**:
   - A roadside camera or loop detector that observes queue shrinkage in real time suffers from a **decision-horizon lag** ($\Delta t_{\text{decision}} = T_{\text{transition}} + t_{\text{maneuver}} \approx 13\text{--}23\text{ seconds}$). By the time sensors confirm that drivers have completed their lane changes, the remaining arrival time is insufficient to cycle through mandatory yellow change and all-red clearance intervals ($T_{\text{transition}} \approx 7.5\text{--}11.5\text{s}$), forcing the emergency vehicle to brake abruptly.

Therefore, an urgent industrial and technical need exists for a closed-loop system that **mathematically bridges advance participatory mobile alerts with edge signal controller preemption constraints**, dynamically predicting the stochastic distribution of voluntary driver yielding to delay preemption onset safely without disrupting emergency vehicle progression.

---

## 3. SUMMARY OF THE INVENTION AND INVENTIVE STEP

The present invention solves the above technical problems by providing an **edge-cloud cyber-physical system and algorithmic method for Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)**.

### The Novel Technical Solution (Inventive Step):
1. **Dynamic Decision Horizon & Opportunistic Mobile Priming**:
   - When an emergency vehicle is dispatched, a cloud orchestrator calculates a dynamic lookahead geofence horizon:
     $$d_{\text{horizon}} = v_{\text{EV}} \cdot (T_{\text{transition}} + t_{\text{maneuver}})$$
   - The cloud server broadcasts non-safety-critical advisory notifications to civilian navigation apps operating within the geofence, priming drivers to yield laterally before hearing acoustic sirens.
2. **Individualized Time-Aware Yielding Probability Chain**:
   - For each standing vehicle $i \in \{1, \dots, N\}$ in the approach lane, the system evaluates an individualized yielding probability $p_i$ conditioned on dual-channel alert perception (mobile push and acoustic siren), lateral gap availability, and a strict kinematic deadline feasibility:
     $$P(\text{feasible}_i) = \begin{cases} 0.0, & \text{if } \Delta t_{\text{deadline}}(i) \le 0 \\ \Phi_{\text{standard}}\left( \frac{\ln \Delta t_{\text{deadline}}(i) - \mu_m}{\sigma_m} \right), & \text{if } \Delta t_{\text{deadline}}(i) > 0 \end{cases}$$
     where $\Delta t_{\text{deadline}}(i) = \frac{\Delta x_i - d_{\text{safe}}}{v_{\text{EV}}}$, and $T_{\text{maneuver}} \sim \operatorname{Lognormal}(\mu_m, \sigma_m)$.
3. **Exact Poisson-Binomial Quantile Invariant**:
   - Because yielding probabilities $p_i$ are heterogeneous, the residual blocking queue $N_{\text{rem}}$ follows a discrete Poisson-Binomial distribution parameterized by blocker probabilities $q_i = 1 - p_i$.
   - The edge controller computes the exact discrete quantile $N_{\text{crit}} = F_{\text{PB}}^{-1}(1 - \varepsilon \mid 1 - p_1, \dots, 1 - p_N)$ via recursive convolution, enforcing the chance constraint:
     $$\mathbb{P}\Big( T_{\text{clear}}(N_{\text{rem}}) + T_{\text{transition}} \le \text{ETA} \Big) \ge 1 - \varepsilon$$
4. **Boundary-Crossing Preemption Trigger**:
   - The signal preemption green is initiated at the exact boundary-crossing instant:
     $$\tau^* = \inf \left\{ t \ge 0 \;\middle|\; \text{ETA}(t) \le T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}} \right\}$$
5. **Fail-Safe Graceful Degradation Guarantee**:
   - If mobile cellular notifications drop or network latency exceeds a safety threshold ($800\text{ms}$), the algorithm sets $P_{\text{mobile}} = 0$. At long range, $p_i \to 0$, causing the quantile to expand $N_{\text{crit}} \to N_{\text{init}}$, seamlessly and automatically recovering classical passive queue-discharge mode with zero safety degradation.

---

## 4. BRIEF DESCRIPTION OF THE DRAWINGS
- **FIG. 1** illustrates the overall edge-cloud cyber-physical system architecture comprising the emergency vehicle, cloud orchestration layer, roadside edge traffic controller, and mobile client devices.
- **FIG. 2** depicts the spatial queue configuration along an intersection approach, showing the spatial safe buffer ($d_{\text{safe}}$), individual vehicle positions ($x_i$), and the lookahead decision horizon ($d_{\text{horizon}}$).
- **FIG. 3** is a flowchart illustrating the recursive Poisson-Binomial quantile calculation and the boundary-crossing preemption trigger condition.
- **FIG. 4** is a Pareto frontier graph illustrating the operational trade-off between emergency vehicle deceleration events and cross-street civilian delay across risk parameter $\varepsilon \in [0.01, 0.10]$.

---

## 5. DETAILED DESCRIPTION OF PREFERRED EMBODIMENTS

### A. System Architecture (FIG. 1)
Referring to FIG. 1, the system comprises:
1. **Emergency Vehicle Telemetry Unit (101)**: Onboard GPS/GNSS receiver and cellular V2X transceiver transmitting position $x_{\text{EV}}(t)$, velocity $v_{\text{EV}}(t)$, and patient triage acuity level at 10 Hz.
2. **Cloud Orchestrator (102)**: Scalable cloud server computing route trajectories, establishing dynamic geofence boundaries, and broadcasting opportunistic advisory notifications to civilian client navigation devices (103).
3. **Roadside Edge Controller (104)**: An edge computing device interfaced with a standard NEMA TS2 or IRC:SP:41 traffic signal cabinet (105). The edge controller executes the CC-HLP algorithm and actuates preemption calls via contact closure or SDLC bus commands.
4. **Hardware Malfunction Management Unit (MMU) (106)**: An independent roadside safety unit enforcing mandatory conflicting yellow and all-red clearance intervals, ensuring fail-safe physical isolation regardless of software states.

### B. Mathematical Formulation of the Method (FIG. 3)

#### Step 1: Queue Observation and Vehicle Localization
The edge controller queries stopline loop detectors or roadside cameras to determine the initial standing queue count $N_{\text{init}}$. Each vehicle $i \in \{1, \dots, N_{\text{init}}\}$ is mapped to an estimated coordinate:
$$x_i = x_{\text{stopline}} - (N_{\text{init}} - i + 1) \cdot l_{\text{veh}}$$
where $l_{\text{veh}} = 7.5\text{ meters}$.

#### Step 2: Time-Aware Yielding Probability Evaluation
The distance separating the emergency vehicle from queued vehicle $i$ is $\Delta x_i(t) = x_i - x_{\text{EV}}(t)$. The remaining maneuver time before the emergency vehicle reaches vehicle $i$'s safety perimeter ($d_{\text{safe}} = 15.0\text{ m}$) is:
$$\Delta t_{\text{deadline}}(i) = \frac{\Delta x_i(t) - d_{\text{safe}}}{v_{\text{EV}}(t)}$$

If $\Delta t_{\text{deadline}}(i) \le 0$, the deadline feasibility is set to strictly zero: $P(\text{feasible}_i) = 0.0$.
If $\Delta t_{\text{deadline}}(i) > 0$, deadline feasibility is evaluated via lognormal distribution:
$$P(\text{feasible}_i) = \Phi_{\text{standard}}\left( \frac{\ln \Delta t_{\text{deadline}}(i) - \mu_m}{\sigma_m} \right)$$
with calibrated parameters $\mu_m = 1.705$ and $\sigma_m = 0.35$ (median $5.5\text{ s}$).

Dual-channel alert perception probability is evaluated as:
$$P(\text{alert}_i) = 1 - (1 - P_{\text{mobile}}) \cdot (1 - P_{\text{acoustic}}(\Delta x_i))$$
where $P_{\text{mobile}} = \rho_{\text{app}} \cdot (1 - P_{\text{loss}})$, and $P_{\text{acoustic}}(\Delta x_i) = \frac{1}{1 + \exp\left( \frac{\Delta x_i - d_{\text{mid}}}{\sigma_{\text{audio}}} \right)}$ ($d_{\text{mid}} = 180\text{ m}, \sigma_{\text{audio}} = 30\text{ m}$).

The net yielding probability for vehicle $i$ is:
$$p_i = P(\text{alert}_i) \cdot c_{\text{base}} \cdot P(\text{gap}) \cdot P(\text{feasible}_i)$$
where $c_{\text{base}} = 0.92$ is driver willingness, and $P(\text{gap}) = 0.82$ is lateral gap availability.

#### Step 3: Exact Discrete Poisson-Binomial Quantile
The residual blocking queue $N_{\text{rem}} = \sum_{i=1}^{N_{\text{init}}} (1 - X_i)$ is modeled with blocker probabilities $q_i = 1 - p_i$. The probability mass function $P_k(n)$ is generated recursively:
$$P_0(0) = 1.0$$
$$P_k(n) = P_{k-1}(n) \cdot p_k + P_{k-1}(n-1) \cdot (1 - p_k), \quad \forall n \in \{0, \dots, k\}$$

The cumulative distribution function $F_{\text{PB}}(n) = \sum_{m=0}^n P_{N_{\text{init}}}(m)$ is evaluated. For a risk parameter $\varepsilon \in (0, 1)$ (e.g., $\varepsilon = 0.05$), the critical residual queue $N_{\text{crit}}$ is evaluated as the smallest integer $n$ satisfying:
$$N_{\text{crit}} = \min \left\{ n \in \{0, \dots, N_{\text{init}}\} \;\middle|\; F_{\text{PB}}(n) \ge 1 - \varepsilon \right\}$$

#### Step 4: Preemption Execution
The required clearance lead time is calculated as:
$$T_{\text{lead}} = T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}}$$
where $T_{\text{clear}}(N_{\text{crit}}) = t_L + N_{\text{crit}} \cdot h_s$ if $N_{\text{crit}} \ge 1$ (and $0$ if $N_{\text{crit}} = 0$), and $T_{\text{transition}} = \max(0, g_{\min} - g_{\text{elapsed}}) + t_{\text{yellow}} + t_{\text{all-red}}$.

Preemption is triggered at the earliest instant where $\text{ETA}(t) \le T_{\text{lead}}$.

---

## 6. PATENT CLAIMS

### What is claimed is:

**1. A method for dynamic emergency vehicle preemption at a signalized intersection, the method comprising:**
- receiving, at an edge traffic controller, real-time telemetry comprising a position and speed of an approaching emergency vehicle;
- detecting, via at least one roadside sensor, an initial stationary queue count $N$ in an approach lane of the intersection;
- obtaining, for each vehicle $i \in \{1, \dots, N\}$ in the approach lane, an individualized yielding probability $p_i$ based on a spatial distance to the emergency vehicle and a maneuver deadline feasibility;
- computing a discrete probability distribution of a residual blocking queue $N_{\text{rem}}$ based on blocker probabilities $q_i = 1 - p_i$;
- calculating, using a predetermined risk tolerance parameter $\varepsilon$, an exact discrete quantile $N_{\text{crit}}$ of the residual blocking queue satisfying $\mathbb{P}(N_{\text{rem}} \le N_{\text{crit}}) \ge 1 - \varepsilon$;
- calculating a dynamic preemption lead time $T_{\text{lead}} = T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}}$, wherein $T_{\text{clear}}(N_{\text{crit}})$ is a stopline queue clearance duration for $N_{\text{crit}}$ vehicles, and $T_{\text{transition}}$ is a mandatory signal transition duration; and
- actuating a preemption phase transition at the intersection when an estimated time of arrival ($\text{ETA}$) of the emergency vehicle satisfies $\text{ETA} \le T_{\text{lead}}$.

**2. The method of claim 1, wherein the individualized yielding probability $p_i$ is determined by:**
- evaluating an alert perception probability $P(\text{alert}_i)$ combining a digital mobile notification channel and an acoustic siren channel;
- evaluating a maneuver deadline $\Delta t_{\text{deadline}}(i) = \frac{\Delta x_i - d_{\text{safe}}}{v_{\text{EV}}}$, wherein $\Delta x_i$ is a longitudinal separation between vehicle $i$ and the emergency vehicle, $d_{\text{safe}}$ is a predetermined safety buffer, and $v_{\text{EV}}$ is the speed of the emergency vehicle; and
- setting a deadline completion feasibility $P(\text{feasible}_i)$ to strictly zero if $\Delta t_{\text{deadline}}(i) \le 0$, and evaluating $P(\text{feasible}_i)$ via a lognormal cumulative distribution function if $\Delta t_{\text{deadline}}(i) > 0$.

**3. The method of claim 2, wherein the digital mobile notification channel comprises:**
- establishing a dynamic geofence upstream of the intersection having a lookahead distance $d_{\text{horizon}} = v_{\text{EV}} \cdot (T_{\text{transition}} + t_{\text{maneuver}})$, wherein $t_{\text{maneuver}}$ is an expected vehicle lane-change duration; and
- transmitting an advisory notification to mobile client devices located within the dynamic geofence.

**4. The method of claim 1, wherein the discrete probability distribution of the residual blocking queue $N_{\text{rem}}$ is a Poisson-Binomial distribution, and wherein the exact discrete quantile $N_{\text{crit}}$ is evaluated via recursive discrete convolution of the blocker probabilities $1 - p_1, \dots, 1 - p_N$.**

**5. The method of claim 1, wherein the stopline queue clearance duration $T_{\text{clear}}(N_{\text{crit}})$ enforces an explicit zero boundary condition:**
$$T_{\text{clear}}(N) = \begin{cases} 0, & \text{if } N = 0 \\ t_L + N \cdot h_s, & \text{if } N \ge 1 \end{cases}$$
wherein $t_L$ is a startup lost time, and $h_s$ is a saturation departure headway.

**6. The method of claim 1, wherein upon detecting a loss or latency spike exceeding a threshold in mobile communications, the edge traffic controller sets the yielding probability $p_i \to 0$ for distant queued vehicles, expanding $N_{\text{crit}} \to N$, thereby automatically degrading to a passive queue-discharge preemption mode.**

**7. A cyber-physical system for dynamic emergency vehicle preemption, comprising:**
- a cloud computing server configured to track real-time emergency vehicle coordinates, define a dynamic lookahead geofence, and broadcast advisory notifications to mobile client devices;
- a roadside edge controller communicatively coupled to the cloud computing server and interfaced with a traffic signal cabinet, the roadside edge controller comprising a processor and a memory storing executable instructions to:
  - determine an initial standing queue count $N$ in an approach lane;
  - compute individualized yielding probabilities $p_1, \dots, p_N$ conditioned on mobile alert delivery and deadline feasibility;
  - calculate an exact discrete Poisson-Binomial quantile $N_{\text{crit}}$ bounding residual blocker probability at a confidence level $1 - \varepsilon$;
  - schedule a preemption initiation instant based on $T_{\text{clear}}(N_{\text{crit}}) + T_{\text{transition}}$; and
  - output a preemption command to the traffic signal cabinet; and
- a hardware Malfunction Management Unit (MMU) coupled to the traffic signal cabinet to enforce conflicting clearance intervals independently of software commands.

**8. The system of claim 7, wherein the roadside edge controller evaluates a Pareto-optimal trade-off between cross-street civilian delay and emergency vehicle deceleration episodes by adjusting the risk tolerance parameter $\varepsilon \in [0.01, 0.10]$.**

**9. The system of claim 7, wherein the preemption command reduces aggregate preemption green duration by at least 2.0 seconds per intersection compared to a passive queue-discharge baseline, while maintaining zero complete stops for the emergency vehicle.**

**10. A non-transitory computer-readable medium storing instructions that, when executed by a processor of an edge traffic controller, cause the processor to perform the method of claim 1.**
