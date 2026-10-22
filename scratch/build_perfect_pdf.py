import os
import subprocess
import base64
import Quartz
from Foundation import NSURL

# 1. Read figure and encode to base64
img_path = "/Users/himanshusingh/project/green_corridor/four_controller_ablation_results.png"
with open(img_path, "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode("utf-8")

# 2. Build the complete HTML document without f-string escaping hazards
raw_html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption</title>
<style>
@page {
  size: letter;
  margin: 0.55in 0.55in 0.65in 0.55in;
  @bottom-right {
    content: "Page " counter(page);
    font-family: 'Times New Roman', serif;
    font-size: 8.5pt;
  }
  @top-left {
    content: "PRE-SUBMISSION WORKING DRAFT FOR ACADEMIC REVIEW / FORMAL PATENT SPECIFICATION (CC-HLP)";
    font-family: 'Times New Roman', serif;
    font-size: 8pt;
    font-style: italic;
    color: #444;
  }
}

body {
  font-family: 'Times New Roman', 'Nimbus Roman No9 L', serif;
  font-size: 10pt;
  line-height: 1.42;
  color: #111;
  margin: 0;
  padding: 0;
}

.title-container {
  text-align: center;
  margin-bottom: 14px;
  border-bottom: 2px solid #0b2240;
  padding-bottom: 10px;
}

.doc-badge {
  font-size: 9pt;
  font-weight: bold;
  color: #a31515;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  margin-bottom: 6px;
}

h1.paper-title {
  font-size: 17.5pt;
  font-weight: bold;
  line-height: 1.22;
  margin: 0 0 8px 0;
  color: #0b2240;
}

.author-line {
  font-size: 10.5pt;
  font-weight: bold;
  margin-bottom: 3px;
}

.affiliation-line {
  font-size: 9pt;
  font-style: italic;
  color: #333;
  margin-bottom: 8px;
}

.meta-tags {
  display: flex;
  justify-content: center;
  gap: 10px;
  flex-wrap: wrap;
  font-size: 8pt;
  font-family: Arial, sans-serif;
  font-weight: bold;
}

.tag {
  background: #eef2f7;
  border: 1px solid #c0d0e0;
  padding: 2px 7px;
  border-radius: 3px;
  color: #1b365d;
}

.abstract-box {
  background: #fbfbfb;
  border: 1px solid #d8d8d8;
  border-left: 3.5px solid #0b2240;
  padding: 10px 14px;
  margin: 12px 0 16px 0;
  font-size: 9pt;
  line-height: 1.38;
  text-align: justify;
}

.abstract-box b.heading {
  text-transform: uppercase;
  font-size: 9pt;
  color: #0b2240;
}

.content-columns {
  column-count: 2;
  column-gap: 0.26in;
  column-rule: 1px solid #e2e2e2;
  text-align: justify;
}

h2 {
  font-size: 11pt;
  font-weight: bold;
  text-transform: uppercase;
  color: #0b2240;
  border-bottom: 1.2px solid #0b2240;
  padding-bottom: 2px;
  margin-top: 14px;
  margin-bottom: 6px;
  break-after: avoid;
}

h3 {
  font-size: 10pt;
  font-weight: bold;
  color: #1b365d;
  margin-top: 10px;
  margin-bottom: 4px;
  break-after: avoid;
}

h4 {
  font-size: 9.5pt;
  font-weight: bold;
  font-style: italic;
  margin-top: 8px;
  margin-bottom: 3px;
  break-after: avoid;
}

p {
  margin: 0 0 6px 0;
  text-indent: 12pt;
}

p.no-indent {
  text-indent: 0;
}

ul, ol {
  margin: 0 0 6px 0;
  padding-left: 16px;
}

li {
  margin-bottom: 3px;
}

.eq-block {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 3px;
  padding: 6px 10px;
  margin: 8px 0;
  font-size: 9pt;
  text-align: center;
  break-inside: avoid;
  position: relative;
}

.eq-block .eq-num {
  float: right;
  font-weight: bold;
  color: #444;
}

.callout {
  background: #f4f7fb;
  border: 1px solid #b8cde3;
  border-left: 3.5px solid #0056b3;
  padding: 8px 10px;
  margin: 8px 0;
  font-size: 9pt;
  line-height: 1.34;
  break-inside: avoid;
}

.callout.prop {
  background: #f8faf6;
  border: 1px solid #c2dbbe;
  border-left: 3.5px solid #2e7d32;
}

.callout.legal {
  background: #fdfaf3;
  border: 1px solid #eed8b3;
  border-left: 3.5px solid #b37400;
}

.callout-title {
  font-weight: bold;
  font-size: 9.5pt;
  margin-bottom: 4px;
  color: #0b2240;
}

.span-all-block {
  column-span: all;
  width: 100%;
  margin: 12px 0;
  break-inside: avoid;
}

table.styled-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 7.2pt;
  line-height: 1.2;
  margin: 8px 0;
  break-inside: avoid;
}

table.styled-table th, table.styled-table td {
  padding: 3px 2.5px;
  text-align: left;
}

.span-all-block table.styled-table {
  font-size: 8pt;
  line-height: 1.25;
}

.span-all-block table.styled-table th, .span-all-block table.styled-table td {
  padding: 4px 5px;
}

table.styled-table th {
  border-top: 1.8px solid #222;
  border-bottom: 1px solid #222;
  font-weight: bold;
  background-color: #f7f9fb;
}

table.styled-table tr:last-child td {
  border-bottom: 1.8px solid #222;
}

table.styled-table tr.highlight td {
  background-color: #edf5ff;
  font-weight: bold;
}

.tbl-caption {
  font-size: 8.5pt;
  font-weight: bold;
  text-align: center;
  margin-bottom: 4px;
  break-after: avoid;
}

.claim-block {
  margin-bottom: 9px;
  font-size: 9pt;
  line-height: 1.32;
  break-inside: avoid;
}

.claim-id {
  font-weight: bold;
  color: #0b2240;
}

.ref-list {
  font-size: 8pt;
  line-height: 1.28;
  padding-left: 18px;
}

.ref-list li {
  margin-bottom: 4px;
}

.fig-box {
  text-align: center;
  margin: 10px 0;
  break-inside: avoid;
}

.fig-box img {
  width: 100%;
  height: auto;
  border: 1px solid #ccc;
  border-radius: 3px;
}

.fig-caption {
  font-size: 8.5pt;
  font-style: italic;
  margin-top: 4px;
  color: #333;
}

pre.code-box {
  background: #f8f9fa;
  border: 1px solid #e2e8f0;
  border-left: 3px solid #0056b3;
  padding: 6px 8px;
  font-family: 'Courier New', Courier, monospace;
  font-size: 7.5pt;
  line-height: 1.25;
  margin: 6px 0;
  overflow-x: auto;
  break-inside: avoid;
}
</style>
</head>
<body>

<div class="title-container">
  <div class="doc-badge">Comprehensive Research Manuscript & Formal Complete Patent Specification (Claims 1–15)</div>
  <h1 class="paper-title">Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption: Integrating Mobile Participatory Alerts with Stochastic Queue Discharge Dynamics</h1>
  <div class="author-line">Himanshu Singh, Student Member, IEEE</div>
  <div class="affiliation-line">Department of Computer Science and Engineering, Advanced Traffic and Cyber-Physical Systems Lab<br>Email: himanshugangasingh12@gmail.com</div>
  <div class="meta-tags">
    <span class="tag">Pre-Submission Working Draft (Target: IEEE Transactions on Intelligent Transportation Systems)</span>
    <span class="tag">Patent Status: Complete Specification (15 Claims)</span>
    <span class="tag">Jurisdiction: USPTO (35 U.S.C. 101/102/103) & IPO (Section 39 / 2025 CRI Guidelines)</span>
    <span class="tag">Reproducibility: Git Commit e3a77c5 (Seeds 1001–1050)</span>
  </div>
</div>

<div class="abstract-box">
  <b class="heading">Executive Abstract&mdash;</b>Emergency Vehicle Preemption (EVP) systems operate under an acute operational trade-off: triggering green waves prematurely induces severe cross-street civilian delay and arterial queue spillback, while delaying activation forces emergency vehicles (EVs) to decelerate behind standing civilian queues. Classical queue-discharge preemption algorithms (e.g., Obrusn&iacute;k et al., 2020) adapt green onset to observed queues, but treat civilian traffic as purely passive agents that disperse only after the signal turns green. Conversely, human-factors research (e.g., Lidestam et al., 2020) demonstrates that advance in-vehicle warnings significantly increase drivers' propensity to give way and reduce reaction latencies, yet this behavioral response has remained uncoupled from signal preemption scheduling. Furthermore, emerging preemption frameworks increasingly rely on dedicated Connected Autonomous Vehicle (CAV) infrastructure, leaving mixed legacy human traffic unaddressed.
  <br><br>
  In this paper, we formulate, analyze, and benchmark <b>Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)</b>, an integrated cyber-physical preemption architecture that bridges mobile participatory alerts with roadside traffic signal controllers. Each queued vehicle <i>i</i> is modeled with an individualized yielding probability <i>p<sub>i</sub></i>, conditioned on dual-channel alert perception (mobile push notifications and acoustic sirens), adjacent lane gap acceptance, and strict kinematic maneuver deadline feasibility (<i>T</i><sub>maneuver</sub> &le; &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>)). Because individual probabilities are heterogeneous, the residual blocking queue is formulated as a discrete Poisson-Binomial random variable, and preemption is scheduled via an exact discrete quantile over residual-blocker probabilities 1 &minus; <i>p<sub>i</sub></i> to enforce a model-based chance constraint: <i>P</i>(<i>T</i><sub>clear</sub>(<i>N</i><sub>rem</sub>) + <i>T</i><sub>transition</sub> &le; ETA) &ge; 1 &minus; &epsilon;.
  <br><br>
  We evaluate CC-HLP through an audited, 50-seed Monte Carlo microscopic discrete-event kinematic simulation across a 3.2&nbsp;km, 5-intersection arterial corridor under a Common Random Numbers (CRN) paired experimental design (seeds 1001--1050). Benchmarking against static distance preemption, an Obrusn&iacute;k-inspired passive queue-discharge baseline, and a strictly causal 2.0-second sensor-driven reactive observer reveals a fundamental <i>Observer vs. Predictor Dilemma</i>: due to the physical sequential decision horizon spanning &Delta;<i>t</i><sub>decision</sub> &in; [11.0, 23.3]&nbsp;s (nominal &approx; 13.0&nbsp;s, corresponding to lookahead distance 220 to 466&nbsp;m, nominal &approx; 260&nbsp;m), a reactive observer that shortens preemption based on delayed physical detection experiences 3.52 &plusmn; 1.11 EV braking episodes per run (<i>a</i> &le; &minus;2.0&nbsp;m/s<sup>2</sup>). CC-HLP bridges this lag, establishing a balanced empirical trade-off: it slashes EV braking by <b>54.0%</b> (1.62 &plusmn; 1.24 episodes at &epsilon; = 0.05, <i>p</i> &lt; 10<sup>&minus;12</sup>) relative to the reactive observer while achieving fastest corridor transit (161.4 &plusmn; 7.5&nbsp;s) with zero complete stops. Concurrently, CC-HLP saves <b>22.88 seconds (15.8%) of aggregate preemption green</b> (4.58&nbsp;s per junction) compared to the passive queue-discharge baseline (<i>p</i> &lt; 10<sup>&minus;30</sup>), reducing cross-street civilian delay by <b>16.7%</b> (47.4 &plusmn; 4.2&nbsp;s vs. 56.9 &plusmn; 5.5&nbsp;s/veh). We derive an exact, finite-queue proof demonstrating that when mobile connectivity is absent (&rho;<sub>app</sub> = 0.0), CC-HLP provably recovers the conservative passive queue schedule across all <i>N</i> &ge; 0. Finally, we formulate a 15-claim formal patent disclosure defining the cyber-physical apparatus, method, and fail-safe watchdog interlocks.
  <br><br>
  <i><b>Index Terms&mdash;</b>Emergency Vehicle Preemption, Intelligent Transportation Systems, Chance-Constrained Optimization, Poisson-Binomial Distribution, Mobile Participatory Sensing, Cyber-Physical Systems, Fail-Safe Traffic Control, Patent Specification, Inventive Step.</i>
</div>

<div class="content-columns">

<h2>I. Introduction and Operational Context</h2>

<p class="no-indent">Emergency Medical Service (EMS) response intervals and fire rescue progression speeds are directly linked to patient survival rates and structural casualty mitigation. Consequently, Emergency Vehicle Preemption (EVP) has long been deployed to interrupt normal cyclic signal operation and grant immediate right-of-way to approaching emergency vehicles (EVs). Traditional EVP architectures employ fixed optical strobe sensors, localized acoustic detectors, or static radio-frequency transponders that trigger green phases once an EV crosses a fixed distance threshold upstream (typically 200–400 meters).</p>

<p>While static distance-based preemption guarantees right-of-way, it induces two severe and opposing operational failure modes:</p>
<ul>
  <li><b>Premature Preemption Gridlock:</b> Initiating preemption too early truncates conflicting cross-street phases, cutting pedestrian clearance intervals and triggering oversaturation queue spillback along intersecting arterial roads.</li>
  <li><b>Standing Stopline Queues:</b> If the approach lane is heavily queued, a fixed-distance trigger fails to allocate sufficient lead time for stationary civilian vehicles to discharge, forcing the EV to decelerate severely behind blocked lanes.</li>
</ul>

<p>To overcome this trade-off, dynamic queue-aware preemption algorithms (notably Obrusn&iacute;k et al., 2020) adapt preemption lead time based on the estimated queue length at the stopline. However, these classical models operate under the foundational assumption that civilian vehicles are <i>purely passive obstacles</i> that disperse only after the signal turns green (<i>P</i><sub>yield</sub> = 0).</p>

<p>Simultaneously, transportation human-factors research (Lidestam et al., 2020) demonstrates that advance in-vehicle warnings significantly increase drivers' propensity to give way and reduce reaction latencies compared to conventional sirens alone, prompting voluntary lateral lane changes into adjacent lanes or shoulders before the emergency vehicle arrives. Yet, in modern traffic engineering, <b>in-cabin participatory alert dynamics and signal controller preemption algorithms operate as completely disjoint systems</b>. Signal controllers remain oblivious to voluntary lane-clearing maneuvers, while navigation apps broadcast alerts without coordinating with intersection phase controllers.</p>

<h3>A. The Observer vs. Predictor Dilemma</h3>
<p class="no-indent">A critical technical question in intelligent traffic signal control is whether predictive estimation of voluntary yielding offers any genuine operational benefit over continuous reactive sensing (e.g., roadside cameras, radar, or inductive loop detectors).</p>

<p>Consider the physical sequence of events required to safely transition an intersection phase and clear an approach queue:</p>
<ol>
  <li><b>Signal Transition Latency (<i>T</i><sub>transition</sub>):</b>
  <div class="eq-block">
    <i>T</i><sub>transition</sub> = max(0, <i>g</i><sub>min</sub> &minus; <i>g</i><sub>elapsed</sub>) + <i>t</i><sub>yellow</sub> + <i>t</i><sub>all-red</sub>
    <span class="eq-num">(1)</span>
  </div>
  With minimum green remainder <i>g</i><sub>min</sub> &minus; <i>g</i><sub>elapsed</sub> &in; [0.0, 8.0]&nbsp;s, yellow change <i>t</i><sub>yellow</sub> = 3.5&nbsp;s, and all-red clearance <i>t</i><sub>all-red</sub> = 2.0&nbsp;s, transition latency spans <i>T</i><sub>transition</sub> &in; [5.5, 13.5]&nbsp;s (nominal &approx; 7.5 to 8.0&nbsp;s).</li>
  <li><b>Human Maneuver Latency (<i>t</i><sub>maneuver</sub>):</b> Civilians require perception-reaction time plus lateral steering time: <i>T</i><sub>maneuver</sub> &sim; Lognormal(&mu;<sub><i>m</i></sub> = 1.705, &sigma;<sub><i>m</i></sub> = 0.35), with median exp(&mu;<sub><i>m</i></sub>) = 5.5&nbsp;s, 90th percentile 8.6&nbsp;s, and 95th percentile exp(&mu;<sub><i>m</i></sub> + 1.645&sigma;<sub><i>m</i></sub>) = 9.8&nbsp;s (NHTSA, 2009).</li>
  <li><b>Sequential Decision Horizon:</b>
  <div class="eq-block">
    &Delta;<i>t</i><sub>decision</sub> = <i>T</i><sub>transition</sub> + <i>t</i><sub>maneuver</sub> &in; [11.0, 23.3]&nbsp;s
    <span class="eq-num">(2)</span>
  </div>
  spanning an absolute minimum of 11.0&nbsp;s (5.5 + 5.5&nbsp;s), a nominal operating horizon of &approx; 13.0&nbsp;s (7.5 + 5.5&nbsp;s), up to a conservative worst-case bound of 23.3&nbsp;s (13.5 + 9.8&nbsp;s).</li>
</ol>

<p>At an emergency cruising speed <i>v</i><sub>EV</sub> = 20&nbsp;m/s (72&nbsp;km/h), this decision horizon corresponds to a physical lookahead distance:</p>
<div class="eq-block">
  <i>d</i><sub>decision</sub> = <i>v</i><sub>EV</sub> &middot; &Delta;<i>t</i><sub>decision</sub> &approx; 220 to 466 meters &nbsp;&nbsp; (nominal &approx; 260 m)
  <span class="eq-num">(3)</span>
</div>

<p>This creates an acute engineering dilemma: if a roadside observer waits until drivers physically complete their lateral maneuvers before shortening preemption lead time, the remaining arrival time is already less than <i>T</i><sub>transition</sub> + <i>T</i><sub>clear</sub>, forcing the EV into severe emergency braking (<i>a</i> &le; &minus;2.0&nbsp;m/s<sup>2</sup>). Conversely, if the controller acts conservatively assuming zero yielding, it holds cross-traffic at red for excessive durations, causing civilian gridlock. CC-HLP resolves this dilemma by modeling the probability distribution of future queue clearance across the lookahead horizon, triggering signal transitions at the mathematically exact instant required to guarantee safe queue clearance at risk tolerance &epsilon;.</p>

<h3>B. Summary of Scientific & Patent Contributions</h3>
<ol>
  <li><b>Coupled Behavioral-Kinematic Horizon:</b> Formulating a rigorous mathematical bridge between participatory mobile alerts (cellular/V2X) and roadside signal controller transition constraints across the [11.0, 23.3]&nbsp;s sequential decision horizon.</li>
  <li><b>Exact Poisson-Binomial Chance Constraint:</b> Deriving an exact discrete quantile over heterogeneous residual-blocker probabilities <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i> via recursive <i>O</i>(<i>N</i><sup>2</sup>) convolution, enforcing provable clearance safety at a calibrated risk tolerance &epsilon; &in; [0.01, 0.10].</li>
  <li><b>Two-Stage Hybrid Architecture with Latency Watchdog:</b> Formulating an operational cyber-physical architecture combining a-priori predictive scheduling with a-posteriori opportunistic telemetry verification, backed by an 800-ms network latency watchdog.</li>
  <li><b>Provable Zero-Adoption Fallback Equivalence (Proposition 1):</b> Proving mathematically that when connected penetration drops to zero (&rho;<sub>app</sub> = 0.0), acoustic siren attenuation naturally forces the chance constraint to recover the conservative passive baseline schedule across all <i>N</i> &ge; 0.</li>
  <li><b>Formal Patent Claims & Prior Art Differentiation:</b> Providing a 15-claim formal patent disclosure and an exhaustive comparison matrix distinguishing CC-HLP from prior art under 35 U.S.C. &sect;&sect; 101, 102, and 103.</li>
</ol>

<h2>II. Related Work & Prior Art Matrix</h2>

<p class="no-indent">Existing emergency preemption literature falls into four distinct technological paradigms:</p>

<h3>A. Classical and Queue-Aware Preemption</h3>
<p>Traditional EVP systems rely on NEMA TS2 or 170/2070 controller standards, enforcing minimum green (<i>g</i><sub>min</sub>), yellow change (<i>t</i><sub>yellow</sub>), and all-red (<i>t</i><sub>all-red</sub>) clearance intervals. Static distance-based preemption triggers green at a constant distance <i>d</i><sub>trigger</sub>, typically utilizing optical strobe emitters or roadside video sensors (e.g., YOLO-based emergency light-bar detection frameworks; Lamrabet et al., 2026). When queue lengths fluctuate stochastically, static triggers either under-preempt or over-preempt because they possess no lookahead knowledge of standing queues.</p>

<p>Obrusn&iacute;k, Herman, and Hur&aacute;k (2020) advanced preemption design by introducing dynamic queue-discharge preemption: <i>T</i><sub>clear</sub> = <i>t<sub>L</sub></i> + <i>N</i> &middot; <i>h<sub>s</sub></i>, where <i>t<sub>L</sub></i> = 2.0&nbsp;s is startup lost time and <i>h<sub>s</sub></i> = 2.0&nbsp;s/veh is saturation departure headway (1800&nbsp;veh/h/lane). Preemption is initiated when ETA &le; <i>T</i><sub>clear</sub> + <i>T</i><sub>transition</sub>. While mathematically sound, Obrusn&iacute;k et al. treat civilian traffic as passive agents (<i>P</i><sub>yield</sub> = 0).</p>

<h3>B. Connected Vehicle Preemption and Advisory Telematics</h3>
<p>Human-factors studies demonstrate that standard acoustic sirens suffer from high sound attenuation in modern sound-insulated vehicle cabins (ISO 7731). Lidestam et al. (2020) demonstrated that in-car auditory and visual warnings markedly enhance driver yielding compliance and situational awareness.</p>

<p>Recent connected vehicle frameworks investigate automated preemption: Ding et al. (2024) formulate V2X-supported, deep reinforcement learning (DRL)-assisted mobility-aware lane changing for emergency preemption in connected autonomous transport systems. While demonstrating substantial progression benefits for automated fleets, their focus is on autonomous vehicle control (CAVs) rather than modeling the stochastic perception latencies and voluntary compliance of human drivers in mixed legacy traffic. Similarly, Zhang et al. (2024) developed a collaborative control framework optimizing automated vehicle trajectories jointly with signal preemption phases; however, this framework presumes deterministic vehicular obedience rather than deadline-conditioned human behavioral compliance. At the corridor level, Wang et al. (2026) proposed distributed optimization for multi-intersection coordinated preemption with transition recovery, yet their formulation models queues through macroscopic shockwave approximations without capturing dynamic lane vacancies created by pre-signal in-vehicle yielding.</p>

<p>In the patent literature, Sony Group Corporation's patent application US 2026/0188114 A1 describes distributing emergency-route notifications to client navigation devices and coordinating with roadside infrastructure to prompt cooperative vehicle maneuvers. However, its claims focus on client-side route messaging and cooperative maneuvering instructions, without incorporating deadline-conditioned human yielding probabilities or deriving a chance-constrained signal preemption trigger for roadside traffic controllers.</p>

<p>Furthermore, earlier patent disclosures such as Bachelder's cellular-based preemption system (US 7,868,783 B2) demonstrate that utilizing vehicle position reports, estimated arrival times, and probabilistic preemption criteria is established in general emergency signal priority. Similarly, recent route-level priority frameworks (e.g., Heusser et al., US 2026/0266618 A1) coordinate dynamic emergency routing with signal priority across multiple upcoming intersections, while probabilistic arrival studies (e.g., Roja Ramani et al., 2026) evaluate arrival-time uncertainty using Monte Carlo simulation.</p>

<p>However, these prior approaches address arrival uncertainty, macroscopic coordination, or static queue clearing under passive traffic; they do not model the deadline-constrained probability of individual human drivers yielding along approach queues or formulate roadside preemption via a chance-constrained residual-queue quantile.</p>

<div class="span-all-block">
<div class="tbl-caption">TABLE I: Selected Prior Art Comparison and Methodological Differentiation</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>System / Reference</th>
      <th>Driver Model</th>
      <th>Advisory Channel</th>
      <th>Decision Horizon</th>
      <th>Stochastic Quantile</th>
      <th>Cabinet Interface</th>
      <th>Degraded Fallback Mode</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>Fixed Distance EVP</b></td>
      <td>Unmodeled</td>
      <td>Strobe / Siren</td>
      <td>None (300 m)</td>
      <td>Deterministic</td>
      <td>Optical Relay</td>
      <td>None</td>
    </tr>
    <tr>
      <td><b>Obrusn&iacute;k et al. (2020)</b></td>
      <td>Passive (<i>P</i><sub>yield</sub>=0)</td>
      <td>None</td>
      <td><i>T</i><sub>trans</sub>+<i>T</i><sub>clear</sub></td>
      <td>Deterministic</td>
      <td>Roadside Cabinet</td>
      <td>Fixed time fallback</td>
    </tr>
    <tr>
      <td><b>Ding et al. (2024)</b></td>
      <td>100% CAVs</td>
      <td>V2X Slot</td>
      <td>Trajectory Plan</td>
      <td>DRL Policy</td>
      <td>Central Controller</td>
      <td>Emergency stop</td>
    </tr>
    <tr>
      <td><b>Sony US 2026/0188114</b></td>
      <td>Cooperative Nav</td>
      <td>Client Push</td>
      <td>Open-Loop Nav</td>
      <td>Unmodeled</td>
      <td>Route messaging to infra</td>
      <td>Stale map display</td>
    </tr>
    <tr>
      <td><b>Bachelder US 7,868,783</b></td>
      <td>Passive Traffic</td>
      <td>Cellular ETA</td>
      <td>Arrival Window</td>
      <td>Arrival Probability</td>
      <td>Cellular Relay</td>
      <td>Timeout fallback</td>
    </tr>
    <tr>
      <td><b>Heusser US 2026/0266618</b></td>
      <td>Passive Traffic</td>
      <td>Route Telematics</td>
      <td>Corridor Schedule</td>
      <td>Deterministic ETA</td>
      <td>Central Priority</td>
      <td>Static priority</td>
    </tr>
    <tr class="highlight">
      <td><b>Proposed CC-HLP</b></td>
      <td><b>Stochastic Human <i>p<sub>i</sub></i>(<i>t</i>)</b></td>
      <td><b>Mobile Push + Siren</b></td>
      <td><b>[11.0, 23.3] s</b></td>
      <td><b>Poisson-Binomial Quantile</b></td>
      <td><b>NEMA TS2 + MMU</b></td>
      <td><b>Provable Passive Fallback</b></td>
    </tr>
  </tbody>
</table>
</div>

<h3>C. Objective Evidence of Non-Obviousness</h3>
<p class="no-indent">Under 35 U.S.C. &sect; 103 and <i>Graham v. John Deere Co.</i>, non-obviousness is firmly established through objective secondary considerations:</p>

<ol>
  <li><b>Teaching Away from Reactive Observation:</b> Prior art in traffic surveillance teaches that controllers should verify vehicle clearance via sensors before altering signal phases. CC-HLP proves that following this teaching causes catastrophic operational failure: the reactive observer suffers 3.52 &plusmn; 1.11 severe braking episodes per run due to the [11.0, 23.3]&nbsp;s decision lag. CC-HLP explicitly teaches away from reactive sensing by establishing that stochastic predictive scheduling is required.</li>
  <li><b>Unexpected Superior Technical Results:</b> CC-HLP slashes emergency vehicle braking episodes by 54.0% (1.62 vs. 3.52 episodes, <i>p</i> &lt; 10<sup>&minus;12</sup>) with zero complete stops, while saving 22.88 seconds of aggregate preemption green (15.8%, 4.58 s per junction, <i>p</i> &lt; 10<sup>&minus;30</sup>) and cutting cross-street civilian delay by 16.7% (47.4 vs. 56.9 s/veh, <i>p</i> = 1.78 &times; 10<sup>&minus;15</sup>). Such multi-objective synergy across conflicting criteria is entirely unexpected from the mere juxtaposition of mobile alerts and traffic signals.</li>
  <li><b>Long-Felt Unsolved Need:</b> For over two decades since Bachelder (2004), the field has struggled with the binary trade-off between cross-street queue spillback and emergency vehicle stoppage. CC-HLP resolves this long-standing dilemma.</li>
  <li><b>Commercial and Practical Viability:</b> Direct integration into NEMA TS2 cabinets via SDLC Port 1 without replacing existing signal controllers or vehicle fleets.</li>
</ol>

<h2>III. Cyber-Physical Architecture</h2>

<p class="no-indent">The CC-HLP cyber-physical apparatus comprises four interconnected layers:</p>

<ol>
  <li><b>Emergency Vehicle Subsystem (101):</b> An onboard unit (OBU) comprising a multi-constellation GNSS receiver (10&nbsp;Hz update, &lt;1.5&nbsp;m CEP accuracy), an inertial measurement unit (IMU), and a cellular-V2X (C-V2X / 5G-NR) transceiver transmitting real-time kinematic state vectors <b>x</b><sub>EV</sub>(<i>t</i>) = [<i>x</i><sub>EV</sub>, <i>y</i><sub>EV</sub>, <i>v</i><sub>EV</sub>, <i>a</i><sub>EV</sub>]<sup><i>T</i></sup>.</li>
  <li><b>Cloud Geofence Orchestration Layer (102):</b> A distributed cloud service that tracks EV dispatch trajectories, calculates dynamic lookahead geofence polygons, and broadcasts non-safety-critical advisory notifications to civilian client navigation devices (103).</li>
  <li><b>Roadside Edge Controller (104):</b> An industrial computing processor (e.g., quad-core ARM Cortex-A72 / Intel Atom x6425RE running RT-PREEMPT Linux) co-located inside the intersection traffic cabinet. The edge controller executes the CC-HLP quantile algorithm at 100&nbsp;ms cycles.</li>
  <li><b>Roadside Traffic Controller Cabinet (105):</b> A standard NEMA TS2 Type 1 / Type 2 or ATC 5301 cabinet housing the main phase controller, Bus Interface Units (BIUs), detector racks, and an independent hardware Malfunction Management Unit (MMU-16LE / CMU) (106).</li>
</ol>

<h3>A. Hardware Cabinet Interface & Interlocks</h3>
<p>The edge controller interfaces with the NEMA TS2 cabinet via a Synchronous Data Link Control (SDLC) Port 1 bus operating at 153.6&nbsp;kbps, or via opto-isolated 24&nbsp;V DC contact closure inputs on the cabinet detector rack. Preemption actuation is strictly subordinate to the hardware MMU/CMU. If software attempts an invalid green transition, the MMU physically forces the intersection into flash within 450&nbsp;ms, guaranteeing fail-safe operation.</p>

<h3>B. Latency Watchdog Monitor</h3>
<p>The edge controller executes an asynchronous watchdog timer. Every incoming mobile advisory message carries a 64-bit UTC timestamp <i>t</i><sub>msg</sub> synchronized via Network Time Protocol (NTP) or cellular base-station clocks. The edge controller computes instantaneous latency: &tau;<sub>latency</sub> = <i>t</i><sub>edge</sub> &minus; <i>t</i><sub>msg</sub>. If &tau;<sub>latency</sub> &gt; 800&nbsp;ms, or if no telematics heartbeat is received for &tau;<sub>timeout</sub> &gt; 800&nbsp;ms, the watchdog trips, forcing <i>P</i><sub>mobile</sub> &equiv; 0 and transitioning the controller into conservative fallback mode.</p>

<h2>IV. Mathematical Framework</h2>

<h3>A. Macroscopic Stopline Queue Clearance</h3>
<p class="no-indent">The physical clearance duration for <i>N</i> standing vehicles across the stopline conflict boundary is modeled with an explicit zero boundary condition (Webster, 1958):</p>
<div class="eq-block">
  <i>T</i><sub>clear</sub>(<i>N</i>) = 0 &nbsp;&nbsp; if <i>N</i> = 0; &nbsp;&nbsp;&nbsp;&nbsp; <i>T</i><sub>clear</sub>(<i>N</i>) = <i>t<sub>L</sub></i> + <i>N</i> &middot; <i>h<sub>s</sub></i> &nbsp;&nbsp; if <i>N</i> &ge; 1
  <span class="eq-num">(4)</span>
</div>
<p>where <i>t<sub>L</sub></i> = 2.0&nbsp;s represents startup lost time and <i>h<sub>s</sub></i> = 2.0&nbsp;s/veh represents saturation departure headway (<i>q</i><sub>max</sub> = 0.5&nbsp;veh/s = 1800&nbsp;veh/h).</p>

<h3>B. Time-Aware Heterogeneous Yielding</h3>
<p class="no-indent">Let the intersection stopline be at position <i>x</i> = 0. Each queued vehicle <i>i</i> &in; {1, &hellip;, <i>N</i>} has longitudinal position <i>x<sub>i</sub></i>(<i>t</i>) &le; 0 (<i>x</i><sub>1</sub> closest to the stopline, <i>x<sub>N</sub></i> at the queue tail). Let the ambulance be at position <i>x</i><sub>amb</sub>(<i>t</i>) &lt; <i>x<sub>i</sub></i>(<i>t</i>) with speed <i>v</i><sub>EV</sub>. The distance separating the ambulance from vehicle <i>i</i> is: &Delta;<i>x<sub>i</sub></i>(<i>t</i>) = <i>x<sub>i</sub></i>(<i>t</i>) &minus; <i>x</i><sub>amb</sub>(<i>t</i>).</p>

<p>The time remaining before the ambulance reaches vehicle <i>i</i>'s safety perimeter (<i>d</i><sub>safe</sub> = 15.0&nbsp;m) is:</p>
<div class="eq-block">
  &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) = (&Delta;<i>x<sub>i</sub></i>(<i>t</i>) &minus; <i>d</i><sub>safe</sub>) / <i>v</i><sub>EV</sub>
  <span class="eq-num">(5)</span>
</div>

<p><b>Strict Expiration Rule:</b> If &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &le; 0, vehicle <i>i</i>'s maneuver window has expired, and its feasible yielding probability is strictly zero:</p>
<div class="eq-block">
  <i>P</i>(feasible<sub><i>i</i></sub>) = 0.0 &nbsp; if &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &le; 0; &nbsp;&nbsp;&nbsp;
  &Phi;(([ln &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>)] &minus; &mu;<sub><i>m</i></sub>) / &sigma;<sub><i>m</i></sub>) &nbsp; if &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &gt; 0
  <span class="eq-num">(6)</span>
</div>
<p>where &Phi;(&middot;) is the standard normal cumulative distribution function, and <i>T</i><sub>maneuver</sub> &sim; Lognormal(&mu;<sub><i>m</i></sub> = 1.705, &sigma;<sub><i>m</i></sub> = 0.35) (median 5.5&nbsp;s, 90th percentile 8.6&nbsp;s, 95th percentile 9.8&nbsp;s) calibrated to empirical bounds for human perception-reaction and discretionary lateral steering times (NHTSA, 2009).</p>

<h3>C. Dual-Channel Alert Perception</h3>
<p class="no-indent">We decouple localized acoustic siren perception from in-cabin digital mobile notifications:</p>
<div class="eq-block">
  <i>P</i>(alert<sub><i>i</i></sub>) = 1 &minus; (1 &minus; <i>P</i><sub>mobile</sub>) &middot; (1 &minus; <i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>(<i>t</i>)))
  <span class="eq-num">(7)</span>
</div>
<p>where:</p>
<ul>
  <li><i>P</i><sub>mobile</sub> = &rho;<sub>app</sub> &middot; (1 &minus; <i>P</i><sub>loss</sub>), with app adoption &rho;<sub>app</sub> &in; [0, 1] and network packet loss <i>P</i><sub>loss</sub> = 0.04 calibrated to 3GPP cellular-V2X (C-V2X) urban communication standards.</li>
  <li><i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>) = 1 / [1 + exp((&Delta;<i>x<sub>i</sub></i> &minus; 180.0) / 30.0)], a phenomenological logistic attenuation kernel with midpoint <i>d</i><sub>mid</sub> = 180&nbsp;m and scale &sigma;<sub>audio</sub> = 30&nbsp;m representing rapid acoustic detection degradation in modern sound-insulated cabins under ambient urban noise (ISO 7731).</li>
</ul>

<h3>D. Individual Yielding Probability & Calibration</h3>
<div class="eq-block">
  <i>p<sub>i</sub></i> = <i>P</i>(alert<sub><i>i</i></sub>) &middot; <i>c</i><sub>base</sub> &middot; <i>P</i>(gap) &middot; <i>P</i>(feasible<sub><i>i</i></sub>)
  <span class="eq-num">(8)</span>
</div>
<p>Parameters represent nominal simulation calibrations:</p>
<ul>
  <li><i>c</i><sub>base</sub> = 0.92: Nominal baseline driver willingness parameter in unobstructed conditions (Lidestam et al., 2020).</li>
  <li><i>P</i>(gap) = 0.82: Nominal assumed gap availability parameter, representing adjacent lane acceptance under moderate arterial demand (<i>q</i><sub>adj</sub> &approx; 200–250&nbsp;veh/h, critical gap <i>t<sub>c</sub></i> = 3.5&nbsp;s per HCM).</li>
</ul>

<h3>E. Poisson-Binomial Queue Distribution & Quantile</h3>
<p><b>Assumption 1 (Conditional Independence):</b> <i>Conditional on individual maneuver deadlines &Delta;t<sub>deadline</sub>(i), ambient gap arrival rates, and alert delivery, individual driver yielding decisions are modeled as conditionally independent Bernoulli trials. While correlated yielding behaviors (e.g., platooned lateral clearing) can occur in dense traffic, this formulation provides a mathematically tractable discrete distribution capturing longitudinal variance along the approach queue.</i></p>

<p>Because individual probabilities <i>p<sub>i</sub></i> vary with longitudinal position, the residual blocking queue <i>N</i><sub>rem</sub> = &sum;<sub><i>i</i>=1</sub><sup><i>N</i><sub>init</sub></sup> (1 &minus; <i>X<sub>i</sub></i>) is the sum of non-identical Bernoulli trials, where <i>X<sub>i</sub></i> &sim; Bernoulli(<i>p<sub>i</sub></i>). Thus, <i>N</i><sub>rem</sub> follows a Poisson-Binomial distribution parameterized by blocker probabilities <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i>.</p>

<p>The exact probability mass function <i>P<sub>k</sub></i>(<i>n</i>) = <i>P</i>(<i>N</i><sub>rem, <i>k</i></sub> = <i>n</i>) is computed via recursive discrete convolution in <i>O</i>(<i>N</i><sup>2</sup>) time (Hong, 2013):</p>
<div class="eq-block">
  <i>P</i><sub>0</sub>(0) = 1.0, &nbsp;&nbsp;&nbsp; <i>P</i><sub>0</sub>(<i>n</i>) = 0.0 &nbsp; (&forall; <i>n</i> &gt; 0) <br>
  <i>P<sub>k</sub></i>(<i>n</i>) = <i>P</i><sub><i>k</i>&minus;1</sub>(<i>n</i>) &middot; <i>p<sub>k</sub></i> + <i>P</i><sub><i>k</i>&minus;1</sub>(<i>n</i> &minus; 1) &middot; (1 &minus; <i>p<sub>k</sub></i>)
  <span class="eq-num">(9)</span>
</div>
<p>for <i>k</i> &in; {1, &hellip;, <i>N</i><sub>init</sub>} and <i>n</i> &in; {0, &hellip;, <i>k</i>}.</p>

<p>The cumulative distribution function is: <i>F</i><sub>PB</sub>(<i>n</i>) = <i>P</i>(<i>N</i><sub>rem</sub> &le; <i>n</i>) = &sum;<sub><i>m</i>=0</sub><sup><i>n</i></sup> <i>P</i><sub><i>N</i><sub>init</sub></sub>(<i>m</i>).</p>

<p>For a user-selected risk tolerance &epsilon; &in; [0.01, 0.10], the critical queue quantile <i>N</i><sub>crit</sub> is the smallest integer satisfying:</p>
<div class="eq-block">
  <i>N</i><sub>crit</sub> = min { <i>n</i> &in; {0, &hellip;, <i>N</i><sub>init</sub>} &nbsp;|&nbsp; <i>F</i><sub>PB</sub>(<i>n</i>) &ge; 1 &minus; &epsilon; }
  <span class="eq-num">(10)</span>
</div>

<p>Preemption is initiated at the first boundary-crossing instant &tau;*:</p>
<div class="eq-block">
  &tau;* = inf { <i>t</i> &ge; 0 &nbsp;|&nbsp; ETA(<i>t</i>) &le; <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) + <i>T</i><sub>transition</sub> }
  <span class="eq-num">(11)</span>
</div>

<h3>F. Two-Stage Hybrid Controller Operation</h3>
<p class="no-indent">The controller implements a two-stage hybrid policy:</p>
<ul>
  <li><b>Stage 1 (A-Priori Predictive Scheduling):</b> When the EV enters the dynamic geofence, the edge controller calculates a-priori yielding probabilities <i>p<sub>i</sub></i> and evaluates <i>N</i><sub>crit</sub> via the quantile formula. Preemption timing is scheduled based on this stochastic estimate.</li>
  <li><b>Stage 2 (A-Posteriori Opportunistic Telemetry Update):</b> If client devices transmit verified lateral maneuver telemetry (e.g., C-ITS Cooperative Awareness Messages confirming &Delta;<i>y</i> &ge; 2.5&nbsp;m), the controller updates <i>p<sub>i</sub></i> &leftarrow; 1.0. This collapses remaining variance in real time without causing signal flutter.</li>
</ul>

<h2>V. Theoretical Guarantee: Zero-Adoption Fallback</h2>

<div class="callout prop">
  <div class="callout-title">Proposition 1 (Model-Based Fallback Equivalence)</div>
  Let connected participatory app adoption be absent (&rho;<sub>app</sub> = 0.0), such that warning delivery relies exclusively on localized acoustic siren perception (<i>P</i>(alert<sub><i>i</i></sub>) = <i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>)). 
  Let <i>N</i> &in; &naturals;<sub>0</sub> queued vehicles occupy positions <i>x<sub>i</sub></i> &in; [&minus;<i>N</i> &middot; <i>l</i><sub>veh</sub>, 0] upstream of the stopline (<i>x</i> = 0), with queue tail at <i>x<sub>N</sub></i> = &minus;<i>N</i> &middot; <i>l</i><sub>veh</sub> and slot length <i>l</i><sub>veh</sub> = 7.5&nbsp;m.
  Under Assumption 1, for any physically admissible signal transition latency <i>T</i><sub>transition</sub> &ge; <i>T</i><sub>transition</sub><sup>min</sup> = 5.5&nbsp;s, lost time <i>t<sub>L</sub></i> = 2.0&nbsp;s, saturation headway <i>h<sub>s</sub></i> = 2.0&nbsp;s/veh, and EV speed <i>v</i><sub>EV</sub> = 20&nbsp;m/s:
  <ol>
    <li><b>Monotonic Spatial Separation:</b> At the preemption decision horizon ETA = <i>T</i><sub>clear</sub>(<i>N</i>) + <i>T</i><sub>transition</sub>, the physical separation from the EV to every queued vehicle <i>i</i> &in; {1, &hellip;, <i>N</i>} satisfies:
    <div class="eq-block">
      &Delta;<i>x<sub>i</sub></i>(<i>N</i>) &ge; &Delta;<i>x</i><sub>tail</sub>(<i>N</i>) = <i>v</i><sub>EV</sub> &middot; (<i>T</i><sub>transition</sub> + <i>t<sub>L</sub></i>) + <i>N</i> &middot; (<i>v</i><sub>EV</sub> &middot; <i>h<sub>s</sub></i> &minus; <i>l</i><sub>veh</sub>) &ge; 150.0 + 32.5 &middot; <i>N</i> meters
      <span class="eq-num">(12)</span>
    </div>
    yielding a strictly positive longitudinal separation gradient of +32.5&nbsp;m per queued vehicle.</li>
    <li><b>Universal Quantile Invariance:</b> Across all queue sizes <i>N</i> &ge; 1 and design risk tolerances &epsilon; &in; [0.01, 0.10], individual yielding probabilities are bounded by the strictly decreasing <i>N</i>-dependent upper bound:
    <div class="eq-block">
      <i>p<sub>i</sub></i> &le; <i>p&#772;</i>(<i>N</i>) &equiv; 0.755 / [1 + exp((32.5 <i>N</i> &minus; 30.0) / 30.0)]
      <span class="eq-num">(13)</span>
    </div>
    ensuring that the product of residual-blocker probabilities <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i> satisfies:
    <div class="eq-block">
      &prod;<sub><i>i</i>=1</sub><sup><i>N</i></sup> <i>q<sub>i</sub></i> &ge; [1 &minus; <i>p&#772;</i>(<i>N</i>)]<sup><i>N</i></sup> &gt; &epsilon; &nbsp;&nbsp;&hArr;&nbsp;&nbsp; <i>F</i><sub>PB</sub>(<i>N</i> &minus; 1) &lt; 1 &minus; &epsilon;
      <span class="eq-num">(14)</span>
    </div>
    Consequently, the chance-constrained discrete quantile resolves identically to the initial un-cleared queue:
    <div class="eq-block">
      <i>N</i><sub>crit</sub> &equiv; <i>N</i><sub>init</sub>, &nbsp;&nbsp; &forall; <i>N</i> &ge; 0
      <span class="eq-num">(15)</span>
    </div>
    and the preemption trigger instant and clearance duration collapse identically to the Obrusn&iacute;k-inspired passive baseline:
    <div class="eq-block">
      &tau;*<sub>CC-HLP</sub> &equiv; &tau;*<sub>passive</sub>, &nbsp;&nbsp;&nbsp; <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) &equiv; <i>T</i><sub>clear</sub>(<i>N</i><sub>init</sub>)
      <span class="eq-num">(16)</span>
    </div>
    yielding identical signal preemption schedules <i>T</i><sub>preempt, <i>k</i></sub> &equiv; <i>T</i><sub>transition, <i>k</i></sub> + <i>T</i><sub>clear</sub>(<i>N</i><sub>init, <i>k</i></sub>) at every intersection <i>k</i>.</li>
  </ol>
</div>

<h3>A. Proof of Proposition 1</h3>
<p class="no-indent"><i>Proof:</i> For <i>N</i> = 0, <i>T</i><sub>clear</sub>(0) = 0, yielding <i>N</i><sub>crit</sub> = 0 = <i>N</i><sub>init</sub> identically.</p>

<p>For <i>N</i> &ge; 1, each queued vehicle yields with probability <i>p<sub>i</sub></i> = <i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>) &middot; <i>c</i><sub>base</sub> &middot; <i>P</i>(gap) &middot; <i>P</i>(feasible<sub><i>i</i></sub>) &le; 0.755 &middot; <i>P</i><sub>acoustic</sub>(&Delta;<i>x</i><sub>tail</sub>(<i>N</i>)) &equiv; <i>p&#772;</i>(<i>N</i>), with blocker probability <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i> &ge; 1 &minus; <i>p&#772;</i>(<i>N</i>). To establish <i>N</i><sub>crit</sub> = <i>N</i>, it is necessary and sufficient that <i>F</i><sub>PB</sub>(<i>N</i> &minus; 1) = <i>P</i>(<i>N</i><sub>rem</sub> &le; <i>N</i> &minus; 1) &lt; 1 &minus; &epsilon;, which is equivalent to &prod;<sub><i>i</i>=1</sub><sup><i>N</i></sup> <i>q<sub>i</sub></i> &gt; &epsilon;:</p>

<ul>
  <li>For <i>N</i> = 1: &Delta;<i>x</i><sub>tail</sub>(1) &ge; 182.5&nbsp;m &rArr; <i>p&#772;</i>(1) &approx; 0.3618, yielding <i>q</i><sub>1</sub> &ge; 0.6382 &gt; 0.10 &ge; &epsilon;. Hence <i>F</i><sub>PB</sub>(0) &le; 0.3618 &lt; 1 &minus; &epsilon;, forcing <i>N</i><sub>crit</sub> = 1.</li>
  <li>For <i>N</i> = 2: &Delta;<i>x</i><sub>tail</sub>(2) &ge; 215.0&nbsp;m &rArr; <i>p&#772;</i>(2) &approx; 0.1793, yielding &prod;<sub><i>i</i>=1</sub><sup>2</sup> <i>q<sub>i</sub></i> &ge; (1 &minus; 0.1793)<sup>2</sup> &approx; 0.6736 &gt; 0.10 &ge; &epsilon;. Thus <i>F</i><sub>PB</sub>(1) &le; 0.3264 &lt; 1 &minus; &epsilon;, forcing <i>N</i><sub>crit</sub> = 2.</li>
  <li>For <i>N</i> = 3: &Delta;<i>x</i><sub>tail</sub>(3) &ge; 247.5&nbsp;m &rArr; <i>p&#772;</i>(3) &approx; 0.0720, yielding &prod;<sub><i>i</i>=1</sub><sup>3</sup> <i>q<sub>i</sub></i> &ge; (1 &minus; 0.0720)<sup>3</sup> &approx; 0.7992 &gt; 0.10 &ge; &epsilon;. Thus <i>F</i><sub>PB</sub>(2) &le; 0.2008 &lt; 1 &minus; &epsilon;, forcing <i>N</i><sub>crit</sub> = 3.</li>
  <li>For <i>N</i> = 4: &Delta;<i>x</i><sub>tail</sub>(4) &ge; 280.0&nbsp;m &rArr; <i>p&#772;</i>(4) &approx; 0.026006, yielding &prod;<sub><i>i</i>=1</sub><sup>4</sup> <i>q<sub>i</sub></i> &ge; (1 &minus; 0.026006)<sup>4</sup> &approx; 0.89996 &gt; 0.10 &ge; &epsilon;. Thus <i>F</i><sub>PB</sub>(3) &le; 0.10004 &lt; 1 &minus; &epsilon;, forcing <i>N</i><sub>crit</sub> = 4.</li>
  <li>For <i>N</i> &ge; 5: utilizing the inequality 1 + <i>e<sup>z</sup></i> &gt; <i>e<sup>z</sup></i>, individual yielding is bounded by <i>p&#772;</i>(<i>N</i>) &lt; 0.755 <i>e</i><sup>&minus;(32.5 <i>N</i> &minus; 30)/30</sup> = 0.755 <i>e</i><sup>1 &minus; 13<i>N</i>/12</sup>. The product bound <i>g</i>(<i>N</i>) = <i>N</i> <i>p&#772;</i>(<i>N</i>) &le; 0.755 <i>N</i> <i>e</i><sup>1 &minus; 13<i>N</i>/12</sup> is strictly decreasing for integer <i>N</i> &ge; 5 (since <i>d</i>/<i>dN</i>[<i>N</i> <i>e</i><sup>&minus;13<i>N</i>/12</sup>] &lt; 0 for all <i>N</i> &ge; 1), with <i>g</i>(5) &le; 3.775 <i>e</i><sup>&minus;53/12</sup> &approx; 0.0456. By Bernoulli's inequality, for all <i>N</i> &ge; 5:
  <div class="eq-block">
    &prod;<sub><i>i</i>=1</sub><sup><i>N</i></sup> <i>q<sub>i</sub></i> &ge; [1 &minus; <i>p&#772;</i>(<i>N</i>)]<sup><i>N</i></sup> &ge; 1 &minus; <i>N</i> <i>p&#772;</i>(<i>N</i>) &ge; 1 &minus; 0.0456 = 0.9544 &gt; 0.10 &ge; &epsilon;
    <span class="eq-num">(17)</span>
  </div>
  strictly ensuring <i>F</i><sub>PB</sub>(<i>N</i> &minus; 1) &le; 0.0456 &ll; 1 &minus; &epsilon; and <i>N</i><sub>crit</sub> &equiv; <i>N</i> for all <i>N</i> &ge; 5.</li>
</ul>

<p>Because each calculated lower bound on &prod;<sub><i>i</i>=1</sub><sup><i>N</i></sup> <i>q<sub>i</sub></i> (0.6382, 0.6736, 0.7992, 0.89996, and &ge; 0.9544) strictly exceeds 0.10, it strictly exceeds every permissible risk tolerance across the entire system design interval &epsilon; &in; [0.01, 0.10]. Consequently, <i>F</i><sub>PB</sub>(<i>N</i> &minus; 1) &lt; 1 &minus; &epsilon; holds uniformly, guaranteeing that <i>N</i><sub>crit</sub> &equiv; <i>N</i><sub>init</sub> holds across all queue sizes.</p>

<p>Furthermore, because the roadside traffic controller locks phase transitions upon trigger evaluation &tau;*, subsequent acoustic siren perception occurring when the EV arrives within 180&nbsp;m cannot retroactively shorten the locked signal schedule. We emphasize that Proposition 1 constitutes a model-based fallback-equivalence result within the formulated kinematic and behavioral framework: it proves that the chance-constrained optimization algorithm structurally and intrinsically recovers the conservative passive queue-discharge baseline schedule under zero connectivity without requiring manual intervention, threshold heuristics, or separate supervisory logic. &#9632;</p>

<h2>VI. Experimental Benchmark Methodology</h2>

<p class="no-indent">To provide an open-source, fully reproducible scientific benchmark without proprietary simulator dependencies, we implemented an object-oriented Microscopic Discrete-Event Kinematic Simulation (MDE-KS) in Python (complete simulation codebase, configuration scripts, random seeds 1001–1050, and per-seed raw output logs available at <a href="https://github.com/himanshu-1629/green-corridor">https://github.com/himanshu-1629/green-corridor</a>, Git commit <code>e3a77c5</code>). The reproducible artifacts comprise the benchmark execution engine (<code>scratch/run_four_controller_ablation.py</code>), per-seed logging output (<code>scratch/per_seed_benchmark_results.csv</code>), parameter calibration scripts (<code>scratch/test_physics_calibration.py</code>), and sensitivity suite (<code>scratch/run_penetration_sweep.py</code>), executable under standard scientific Python environments (<code>numpy &gt;= 1.24</code>, <code>pandas &gt;= 2.0</code>, <code>scipy &gt;= 1.10</code>):</p>

<ul>
  <li><b>Arterial Corridor Geometry:</b> 5 consecutive signalized intersections along a 3.2&nbsp;km arterial corridor. The emergency vehicle begins at dispatch origin <i>x</i> = 0 with an initial 640&nbsp;m approach to the first intersection at <i>x</i> = 640&nbsp;m, followed by 4 inter-intersection links of 640&nbsp;m each (intersections located at <i>x</i> = 640&nbsp;m, 1280&nbsp;m, 1920&nbsp;m, 2560&nbsp;m, and 3200&nbsp;m). The inter-intersection span between the first and fifth signal is 4 &times; 640&nbsp;m = 2.56&nbsp;km, yielding a total corridor transit run of 3200&nbsp;m = 3.2&nbsp;km.</li>
  <li><b>Continuous Kinematic Integration:</b> Longitudinal EV trajectory integrated at &Delta;<i>t</i> = 0.1&nbsp;s time steps: <i>a</i>(<i>t</i>) = [<i>v</i>(<i>t</i>) &minus; <i>v</i>(<i>t</i> &minus; &Delta;<i>t</i>)] / &Delta;<i>t</i>.</li>
  <li><b>Kinematic Limits:</b> <i>v</i><sub>desired</sub> &sim; Normal(20.0, 0.85<sup>2</sup>)&nbsp;m/s (bounded in [17.5, 22.2]&nbsp;m/s / 80&nbsp;km/h), <i>a</i><sub>max</sub> = 2.2&nbsp;m/s<sup>2</sup>, <i>b</i><sub>service</sub> = 2.5&nbsp;m/s<sup>2</sup>, <i>b</i><sub>emergency</sub> = 4.5&nbsp;m/s<sup>2</sup>.</li>
  <li><b>Signal Parameters:</b> Cycle length <i>C</i> = 90&nbsp;s, nominal cross green <i>g<sub>c</sub></i> = 35&nbsp;s, saturation flow <i>s</i> = 0.50&nbsp;veh/s, cross-street demand &lambda;<sub>cross</sub> = 0.16&nbsp;veh/s (576&nbsp;veh/h) (IRC:SP:41).</li>
  <li><b>Transient Cycle-by-Cycle Webster Delay:</b> Cross-street delay is evaluated across the preemption cycle and subsequent recovery cycles using queue area integration &int; <i>Q</i>(<i>t</i>)&thinsp;<i>dt</i>.</li>
  <li><b>Common Random Numbers (CRN):</b> Across each seed, identical initial queues (<i>N</i> &sim; Poisson(&lambda;=8.0)), phase offsets (<i>g</i><sub>elapsed</sub> &sim; Uniform(0, 20&nbsp;s)), EV cruising speeds, and individual driver behavioral attributes are sampled once. All four controllers are evaluated on the exact same physical traffic stream.</li>
</ul>

<h3>A. Four Benchmark Controllers Evaluated</h3>
<ol>
  <li><b>Baseline 1 (Fixed-Distance EVP):</b> Preemption triggers strictly when <i>d</i><sub>EV</sub> &le; 300&nbsp;m.</li>
  <li><b>Baseline 2 (Obrusn&iacute;k-Inspired Queue-Discharge Baseline):</b> Assumes passive traffic (<i>P</i><sub>yield</sub> = 0), calculating lead time to clear all <i>N</i><sub>init</sub> vehicles through green.</li>
  <li><b>Baseline 3 (Strictly Causal Sensor-Driven Reactive Observer):</b> Polls approach queue at discrete intervals (&Delta;<i>t</i><sub>sensor</sub> = 2.0&nbsp;s) with zero future knowledge. At each tick <i>t</i><sub>poll</sub>, counts only vehicles that have <i>already vacated</i> (<i>t</i><sub>poll</sub> &ge; <i>t</i><sub>vacate</sub>). Triggers at the first tick where remaining ETA &le; <i>T</i><sub>clear</sub>(<i>N</i><sub>detected</sub>) + <i>T</i><sub>transition</sub>.</li>
  <li><b>Proposed CC-HLP:</b> Evaluates <i>p<sub>i</sub></i> dynamically and enforces the exact discrete Poisson-Binomial quantile over residual blockers.</li>
</ol>

<div class="tbl-caption">TABLE II: Comprehensive Performance Comparison Across 50 Paired Monte Carlo Simulation Runs (Mean &plusmn; Std. Dev.)</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th>Fixed-Dist.</th>
      <th>Obrusn&iacute;k Baseline</th>
      <th>Reactive Observer</th>
      <th>CC-HLP (Ours)</th>
      <th>Diff vs. Obrusn&iacute;k (&Delta;)</th>
      <th>Diff vs. Observer (&Delta;)</th>
      <th>Paired <i>t</i>-stat (<i>p</i>-val)</th>
      <th>Wilcoxon <i>p</i>-val</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>EV Transit Time (s)</td>
      <td>220.2 &plusmn; 17.4</td>
      <td>172.1 &plusmn; 9.0</td>
      <td>165.1 &plusmn; 8.4</td>
      <td><b>161.4 &plusmn; 7.5</b></td>
      <td><b>&minus;10.70 &plusmn; 2.57</b></td>
      <td>&minus;3.64 &plusmn; 2.58</td>
      <td><i>t</i> = &minus;29.39 (<i>p</i> &lt; 10<sup>&minus;30</sup>)</td>
      <td><i>p</i> = 7.52 &times; 10<sup>&minus;10</sup></td>
    </tr>
    <tr>
      <td>EV Decel. Episodes (<i>a</i> &le; &minus;2.0)</td>
      <td>4.98 &plusmn; 0.14</td>
      <td>5.00 &plusmn; 0.00</td>
      <td>3.52 &plusmn; 1.11</td>
      <td><b>1.62 &plusmn; 1.24</b></td>
      <td><b>&minus;3.38 &plusmn; 1.24</b></td>
      <td><b>&minus;1.90 &plusmn; 1.39</b></td>
      <td><i>t</i> = &minus;19.22 (<i>p</i> &lt; 10<sup>&minus;20</sup>)</td>
      <td><i>p</i> = 1.16 &times; 10<sup>&minus;9</sup></td>
    </tr>
    <tr>
      <td>EV Complete Stops (<i>v</i> = 0)</td>
      <td>4.40 &plusmn; 0.83</td>
      <td>0.12 &plusmn; 0.39</td>
      <td>0.00 &plusmn; 0.00</td>
      <td><b>0.00 &plusmn; 0.00</b></td>
      <td>&minus;0.12 &plusmn; 0.39</td>
      <td>0.00 &plusmn; 0.00</td>
      <td><i>t</i> = &minus;2.20 (<i>p</i> = 0.032)</td>
      <td><i>p</i> = 0.034</td>
    </tr>
    <tr>
      <td>Aggregate Green Duration (s)</td>
      <td>145.0 &plusmn; 15.6</td>
      <td>144.9 &plusmn; 14.3</td>
      <td>111.1 &plusmn; 17.1</td>
      <td><b>122.1 &plusmn; 10.4</b></td>
      <td><b>&minus;22.88 &plusmn; 4.60</b></td>
      <td>+10.94 &plusmn; 9.92</td>
      <td><i>t</i> = &minus;35.13 (<i>p</i> &lt; 10<sup>&minus;30</sup>)</td>
      <td><i>p</i> = 7.56 &times; 10<sup>&minus;10</sup></td>
    </tr>
    <tr>
      <td>Green Savings per Junction (s)</td>
      <td>Baseline</td>
      <td>Baseline</td>
      <td>+6.76 s</td>
      <td><b>+4.58 &plusmn; 0.92 s</b></td>
      <td>+4.58 s saved</td>
      <td>&minus;2.19 s</td>
      <td><i>t</i> = +35.13 (<i>p</i> &lt; 10<sup>&minus;30</sup>)</td>
      <td><i>p</i> = 7.56 &times; 10<sup>&minus;10</sup></td>
    </tr>
    <tr>
      <td>Cross-Street Delay (s/veh)</td>
      <td>56.8 &plusmn; 6.1</td>
      <td>56.9 &plusmn; 5.5</td>
      <td>43.3 &plusmn; 7.0</td>
      <td><b>47.4 &plusmn; 4.2</b></td>
      <td><b>&minus;9.50 &plusmn; 1.92</b></td>
      <td>+4.17 &plusmn; 4.05</td>
      <td><i>t</i> = &minus;34.98 (<i>p</i> &lt; 10<sup>&minus;30</sup>)</td>
      <td><i>p</i> = 1.78 &times; 10<sup>&minus;15</sup></td>
    </tr>
    <tr class="highlight">
      <td>Civilian Delay Reduction (%)</td>
      <td>Baseline</td>
      <td>Baseline</td>
      <td>+24.0%</td>
      <td><b>+16.7%</b></td>
      <td>+16.7%</td>
      <td>&minus;7.3%</td>
      <td>N/A</td>
      <td><i>p</i> = 1.78 &times; 10<sup>&minus;15</sup></td>
    </tr>
  </tbody>
</table>

<h2>VII. Experimental Results & Discussion</h2>

<p class="no-indent">The empirical benchmark results presented in Table II establish the core performance trade-offs:</p>

<h3>A. Resolution of the Observer vs. Predictor Dilemma</h3>
<p>The reactive observer (Baseline 3) attempts to capture the same human-yielding benefits as CC-HLP, but relies on causal sensor polling. As demonstrated in Table II:</p>
<ol>
  <li>The reactive observer reduces cross-street delay (43.3&nbsp;s/veh) by aggressively shortening preemption green (111.1&nbsp;s).</li>
  <li>However, because it incurs the sensor polling and maneuver lag (&Delta;<i>t</i><sub>decision</sub> &in; [11.0, 23.3]&nbsp;s), by the time it confirms vehicles have vacated, the EV is already inside the stop-distance horizon.</li>
  <li>Consequently, the EV experiences an unacceptable <b>3.52 severe braking episodes per run</b>.</li>
  <li><b>CC-HLP slashes braking episodes by 54.0%</b> (1.62 vs. 3.52 episodes, <i>t</i> = &minus;9.67, <i>p</i> &lt; 10<sup>&minus;12</sup>, Wilcoxon <i>p</i> = 1.34 &times; 10<sup>&minus;8</sup>) and achieves fastest progression (161.4&nbsp;s) with zero complete stops, while preserving 16.7% civilian delay reduction (47.4 vs. 56.9&nbsp;s/veh) and saving 22.88&nbsp;s (15.8%) of preemption green over passive queue discharge (<i>t</i> = &minus;35.13, <i>p</i> &lt; 10<sup>&minus;30</sup>, Wilcoxon <i>p</i> = 7.56 &times; 10<sup>&minus;10</sup>).</li>
</ol>

<div class="fig-box">
  <img src="data:image/png;base64,__IMG_B64__" alt="Comprehensive Four Controller Benchmark Results">
  <div class="fig-caption">Figure 1: Comprehensive benchmark results across 50 paired Monte Carlo seeds (seeds 1001--1050): (a) Emergency vehicle transit time distributions showing fastest corridor progression under CC-HLP (161.4 s); (b) EV deceleration episode counts demonstrating a 54.0% reduction under CC-HLP (1.62 episodes) relative to the reactive observer (3.52 episodes); (c) Preemption green duration showing 22.88 s (15.8%) green savings over Obrusn&iacute;k; (d) Webster cycle-by-cycle cross-street civilian delay showing a 16.7% reduction in civilian delay (47.4 vs. 56.9 s/veh, p = 1.78 &times; 10<sup>&minus;15</sup>).</div>
</div>

<h3>B. Sensitivity to Risk Tolerance (&epsilon; &in; [0.01, 0.10])</h3>
<p class="no-indent">Table III demonstrates the tunability of CC-HLP along an explicit operational frontier. At &epsilon; = 0.01 (ultra-conservative), the controller prioritizes EV ride comfort (1.14 braking episodes), while at &epsilon; = 0.10 (high throughput), green savings reach 26.5&nbsp;s and delay drops to 45.9&nbsp;s/veh. The nominal calibration &epsilon; = 0.05 represents a balanced design choice.</p>

<div class="tbl-caption">TABLE III: CC-HLP Sensitivity to Risk Tolerance (&epsilon;)</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>Risk (&epsilon;)</th>
      <th>Delay (s/veh)</th>
      <th>Green (s)</th>
      <th>Decel. Ep.</th>
      <th>Stops</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>&epsilon; = 0.01</td>
      <td>51.0 &plusmn; 4.7</td>
      <td>129.9 &plusmn; 11.5</td>
      <td>1.14 &plusmn; 0.99</td>
      <td>0.00</td>
    </tr>
    <tr>
      <td>&epsilon; = 0.03</td>
      <td>48.5 &plusmn; 4.3</td>
      <td>124.5 &plusmn; 10.4</td>
      <td>1.44 &plusmn; 1.20</td>
      <td>0.00</td>
    </tr>
    <tr class="highlight">
      <td><b>&epsilon; = 0.05 (Nominal)</b></td>
      <td><b>47.4 &plusmn; 4.2</b></td>
      <td><b>122.0 &plusmn; 10.4</b></td>
      <td><b>1.62 &plusmn; 1.24</b></td>
      <td><b>0.00</b></td>
    </tr>
    <tr>
      <td>&epsilon; = 0.08</td>
      <td>45.8 &plusmn; 4.1</td>
      <td>118.4 &plusmn; 10.0</td>
      <td>2.04 &plusmn; 1.31</td>
      <td>0.00</td>
    </tr>
    <tr>
      <td>&epsilon; = 0.10</td>
      <td>45.8 &plusmn; 4.1</td>
      <td>118.4 &plusmn; 10.0</td>
      <td>2.04 &plusmn; 1.31</td>
      <td>0.00</td>
    </tr>
  </tbody>
</table>

<h3>C. Sensitivity to Mobile App Penetration (&rho;<sub>app</sub>)</h3>
<p class="no-indent">Table IV validates controller response across adoption rates. Crucially, at &rho; = 0.00, the system operates in acoustic siren fallback mode (135.1&nbsp;s green, 53.3&nbsp;s/veh delay, zero stops), confirming Proposition 1.</p>

<div class="tbl-caption">TABLE IV: CC-HLP Sensitivity to Mobile App Penetration (&rho;<sub>app</sub>)</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>Penetration (&rho;<sub>app</sub>)</th>
      <th>Delay (s/veh)</th>
      <th>Green (s)</th>
      <th>Decel. Ep.</th>
    </tr>
  </thead>
  <tbody>
    <tr class="highlight">
      <td><b>&rho; = 0.00 (Siren Fallback)</b></td>
      <td><b>53.3 &plusmn; 5.5</b></td>
      <td><b>135.1 &plusmn; 13.4</b></td>
      <td><b>3.50 &plusmn; 1.11</b></td>
    </tr>
    <tr>
      <td>&rho; = 0.20 (Early Adoption)</td>
      <td>52.9 &plusmn; 5.5</td>
      <td>134.3 &plusmn; 13.3</td>
      <td>2.30 &plusmn; 1.04</td>
    </tr>
    <tr>
      <td>&rho; = 0.40 (Moderate Adoption)</td>
      <td>51.2 &plusmn; 4.8</td>
      <td>130.5 &plusmn; 11.7</td>
      <td>1.70 &plusmn; 0.97</td>
    </tr>
    <tr class="highlight">
      <td><b>&rho; = 0.60 (Nominal Target)</b></td>
      <td><b>47.4 &plusmn; 4.2</b></td>
      <td><b>122.0 &plusmn; 10.4</b></td>
      <td><b>1.62 &plusmn; 1.24</b></td>
    </tr>
    <tr>
      <td>&rho; = 0.80 (High Connectivity)</td>
      <td>42.7 &plusmn; 3.1</td>
      <td>111.4 &plusmn; 8.0</td>
      <td>1.74 &plusmn; 1.19</td>
    </tr>
    <tr>
      <td>&rho; = 1.00 (Full Saturation)</td>
      <td>37.4 &plusmn; 2.3</td>
      <td>99.0 &plusmn; 7.0</td>
      <td>2.50 &plusmn; 1.15</td>
    </tr>
  </tbody>
</table>

<h2>VIII. System Safety Architecture & Fail-Safe Operation</h2>

<p class="no-indent">To ensure robust cyber-physical deployment, the CC-HLP control architecture explicitly separates predictive advisory operation from degraded fail-safe modes and physical hardware interlocks:</p>

<ol>
  <li><b>Connected Predictive Advisory Mode (&rho;<sub>app</sub> &gt; 0):</b> In normal connected operation, CC-HLP operates as a predictive chance-constrained controller using cellular/V2X advisory push messaging. Individual yielding probabilities <i>p<sub>i</sub></i> = <i>P</i>(alert<sub><i>i</i></sub>) &middot; <i>c</i><sub>base</sub> &middot; <i>P</i>(gap) &middot; <i>P</i>(feasible<sub><i>i</i></sub>) are estimated a-priori from the behavioral yielding model. We explicitly distinguish this predictive probability estimation from physical observation: <i>p<sub>i</sub></i> represents the expected likelihood of voluntary yielding, allowing the roadside controller to calculate the exact Poisson-Binomial quantile <i>N</i><sub>crit</sub> under risk tolerance &epsilon;. Preemption lead time is shortened safely based on this stochastic quantile, capturing the documented 22.88&nbsp;s (15.8%) aggregate green savings (4.58&nbsp;s per junction) and 16.7% civilian delay reduction.</li>
  <li><b>Opportunistic Maneuver Telemetry Verification (Stage 2):</b> If client devices transmit verified lateral maneuver telemetry (e.g., C-ITS Cooperative Awareness Messages confirming lateral position shift &Delta;<i>y</i> &ge; 2.5&nbsp;m into an adjacent lane or shoulder), the edge controller updates that specific vehicle's state to <i>p<sub>i</sub></i> &leftarrow; 1.0. This collapses remaining residual variance in real time without introducing signal flutter.</li>
  <li><b>Operational Latency Watchdog Monitor:</b> The roadside edge controller executes a real-time watchdog thread at 100&nbsp;ms cycles. Every incoming telematics packet carries a 64-bit UTC timestamp <i>t</i><sub>msg</sub> synchronized via Network Time Protocol (NTP) or cellular base-station clocks. The controller evaluates instantaneous latency &tau;<sub>latency</sub> = <i>t</i><sub>edge</sub> &minus; <i>t</i><sub>msg</sub>. If &tau;<sub>latency</sub> &gt; 800&nbsp;ms, or if no telematics heartbeat is received for &tau;<sub>timeout</sub> &gt; 800&nbsp;ms, the watchdog trips, forcing <i>P</i><sub>mobile</sub> &equiv; 0 in the mathematical model.</li>
  <li><b>Advisory Failure and Zero-Adoption Fallback Mode (&rho;<sub>app</sub> = 0 or Latency Watchdog Trip):</b> When <i>P</i><sub>mobile</sub> = 0, warning delivery relies exclusively on acoustic sirens. Under this degraded condition, Proposition 1 guarantees that the chance constraint mathematically collapses to <i>N</i><sub>crit</sub> &equiv; <i>N</i><sub>init</sub> across all <i>N</i> &ge; 0. The controller automatically reverts to the conservative passive queue-discharge schedule <i>T</i><sub>clear</sub>(<i>N</i><sub>init</sub>) = <i>t<sub>L</sub></i> + <i>N</i><sub>init</sub> <i>h<sub>s</sub></i>, ensuring complete stopline queue clearance without relying on unconfirmed voluntary driver yielding.</li>
  <li><b>Hardware-Level Conflict Interlock (MMU/CMU):</b> All physical signal actuations remain strictly subordinate to the roadside controller cabinet (NEMA TS2 / IRC:SP:41 standard), where an independent hardware Malfunction Management Unit (MMU-16LE / CMU) physically monitors the field load switch voltages. If software attempts an invalid or conflicting phase transition, or violates minimum clearance intervals (<i>t</i><sub>yellow</sub> &ge; 3.5&nbsp;s, <i>t</i><sub>all-red</sub> &ge; 2.0&nbsp;s), the MMU physically forces the intersection into flash within 450&nbsp;ms independently of the edge processor. Emergency vehicle acoustic sirens (120&nbsp;dB) and optical strobe emitters operate continuously as the primary physical fail-safe warning system.</li>
</ol>

<h2>IX. Detailed Technical Description of Preferred Embodiments</h2>

<h3>A. Embodiment 1: Cloud-Edge Distributed Architecture with C-V2X Telematics</h3>
<p class="no-indent">In a primary preferred embodiment, the cyber-physical preemption system comprises a distributed cloud orchestrator and a network of roadside edge controllers operating over 3GPP Release 16/17 Cellular-V2X (C-V2X) architecture:</p>

<ul>
  <li><b>Dynamic Geofence Polygon Synthesis:</b> The cloud orchestrator calculates a dynamic spatial polygon upstream of each intersection along the emergency vehicle dispatch route. The lookahead distance is calculated as <i>d</i><sub>geofence</sub> = <i>v</i><sub>EV</sub> &middot; (<i>T</i><sub>transition</sub> + <i>t</i><sub>maneuver</sub> + <i>t</i><sub>buffer</sub>), where <i>t</i><sub>buffer</sub> = 2.0&nbsp;s. For <i>v</i><sub>EV</sub> = 20&nbsp;m/s, <i>d</i><sub>geofence</sub> &in; [260, 506]&nbsp;meters.</li>
  <li><b>5G Network Slicing & Quality of Service (QoS):</b> Vehicle kinematic state vectors <b>x</b><sub>EV</sub>(<i>t</i>) are transmitted over an Ultra-Reliable Low-Latency Communication (URLLC) slice (5QI = 82/83) with guaranteed packet latency &lt;20&nbsp;ms. Civilian advisory push messages are broadcast via enhanced Mobile Broadband (eMBB) cell broadcast channels to prevent cellular network congestion.</li>
  <li><b>Standard Message Protocol Formatting:</b> Emergency alerts are mapped to SAE J2735 Emergency Vehicle Alert (EVA) and Basic Safety Message (BSM) formats in North America, and ETSI EN 302 637-2 Cooperative Awareness Messages (CAM) and Decentralized Environmental Notification Messages (DENM) in Europe.</li>
</ul>

<h3>B. Embodiment 2: Algorithmic Implementation of Recursive Discrete Convolution</h3>
<p class="no-indent">The edge controller processor executes Algorithm 1 at each 100&nbsp;ms control cycle. To eliminate floating-point underflow when multiplying large sequences of blocker probabilities <i>q<sub>i</sub></i>, the recursion maintains dynamic normalization.</p>

<pre class="code-box">
ALGORITHM 1: CC-HLP Quantile Evaluation & Preemption Actuation
Input: N_init (queue count), x_amb, v_amb, x_stop, epsilon, T_transition
Output: Actuation Decision (BOOLEAN)

1:  d_EV = x_stop - x_amb
2:  IF d_EV &lt;= 0 THEN RETURN FALSE   // EV has crossed stopline
3:  ETA = d_EV / max(v_amb, 0.1)
4:  
5:  // Step 1: Compute Individual Yielding Probabilities p_i
6:  FOR i = 1 TO N_init DO
7:      x_i = x_stop - i * l_veh
8:      delta_x_i = x_i - x_amb
9:      delta_t_deadline = (delta_x_i - d_safe) / max(v_amb, 0.1)
10:     IF delta_t_deadline &lt;= 0 THEN
11:         P_feasible[i] = 0.0
12:     ELSE
13:         P_feasible[i] = Phi((ln(delta_t_deadline) - mu_m) / sigma_m)
14:     END IF
15:     P_acoustic = 1.0 / (1.0 + exp((delta_x_i - d_mid) / sigma_audio))
16:     P_alert = 1.0 - (1.0 - P_mobile) * (1.0 - P_acoustic)
17:     p[i] = P_alert * c_base * P_gap * P_feasible[i]
18:     q[i] = 1.0 - p[i]
19: END FOR
20: 
21: // Step 2: Recursive Poisson-Binomial Convolution (O(N^2))
22: P_curr = ARRAY OF SIZE (N_init + 1) INITIALIZED TO 0.0
23: P_curr[0] = 1.0
24: FOR k = 1 TO N_init DO
25:     P_next = ARRAY OF SIZE (N_init + 1) INITIALIZED TO 0.0
26:     P_next[0] = P_curr[0] * p[k]
27:     FOR n = 1 TO k DO
28:         P_next[n] = P_curr[n] * p[k] + P_curr[n-1] * q[k]
29:     END FOR
30:     P_curr = P_next
31: END FOR
32: 
33: // Step 3: Quantile Inversion for N_crit
34: cum_prob = 0.0
35: N_crit = N_init
36: FOR n = 0 TO N_init DO
37:     cum_prob = cum_prob + P_curr[n]
38:     IF cum_prob &gt;= 1.0 - epsilon THEN
39:         N_crit = n
40:         BREAK
41:     END IF
42: END FOR
43: 
44: // Step 4: Clearance Duration and Preemption Trigger Evaluation
45: IF N_crit == 0 THEN T_clear = 0.0 ELSE T_clear = t_L + N_crit * h_s
46: T_lead = T_clear + T_transition
47: IF ETA &lt;= T_lead THEN
48:     EXECUTE_CABINET_PREEMPTION_COMMAND()
49:     LOCK_PHASE_TRANSITION()
50:     RETURN TRUE
51: END IF
52: RETURN FALSE
</pre>

<h3>C. Embodiment 3: NEMA TS2 Cabinet SDLC Bus & Malfunction Management Unit</h3>
<p class="no-indent">The physical interface between the edge computing unit and the roadside signal controller cabinet is engineered to ensure seamless drop-in deployment without replacing municipal signal hardware:</p>

<ul>
  <li><b>EIA-485 Differential SDLC Link:</b> The edge processor communicates over an asynchronous, high-speed Synchronous Data Link Control (SDLC) Port 1 bus operating at 153.6&nbsp;kbps. The processor transmits structured Command Frame 0x2A containing the preemption call bit, designated phase call vector, and priority clearance interval.</li>
  <li><b>Opto-Isolated Contact Closures:</b> For legacy NEMA TS1, 170, or 2070 cabinets lacking an active SDLC bus, the edge controller drives solid-state optical relays providing 2500&nbsp;V RMS galvanic isolation to energize cabinet detector rack input channels directly.</li>
  <li><b>Independent Hardware MMU-16LE / CMU Conflict Interlock:</b> All software commands remain subordinate to the cabinet Malfunction Management Unit (MMU-16LE). The MMU independently monitors field terminal voltages. If software attempts to grant conflicting greens or violates minimum clearance times (<i>t</i><sub>yellow</sub> &ge; 3.5&nbsp;s, <i>t</i><sub>all-red</sub> &ge; 2.0&nbsp;s), the MMU physically energizes a mechanical transfer relay within 450&nbsp;ms, dropping the signal assembly into fail-safe flashing mode.</li>
</ul>

<h3>D. Embodiment 4: Real-Time Latency Watchdog Hardware Circuit & FSM</h3>
<p class="no-indent">The safety architecture executes an asynchronous hardware-backed finite state machine (FSM) comprising four distinct operational states:</p>

<ul>
  <li><b>State 1: NORMAL_PREDICTIVE (Active Mobile Mode):</b> Mobile telematics latency &tau;<sub>latency</sub> &le; 800&nbsp;ms. <i>P</i><sub>mobile</sub> = &rho;<sub>app</sub> &middot; (1 &minus; <i>P</i><sub>loss</sub>). The controller computes <i>N</i><sub>crit</sub> via Poisson-Binomial quantile inversion, saving preemption green.</li>
  <li><b>State 2: TELEMETRY_CONFIRMED (Opportunistic Maneuver Mode):</b> Specific client devices transmit verified lateral lane clearance telemetry. Individual probabilities collapse to <i>p<sub>i</sub></i> = 1.0, collapsing remaining variance in real time without signal flutter.</li>
  <li><b>State 3: WATCHDOG_TIMEOUT_FALLBACK (Degraded Passive Mode):</b> Upon detecting &tau;<sub>latency</sub> &gt; 800&nbsp;ms or missing heartbeat for &gt;800&nbsp;ms, the watchdog forces <i>P</i><sub>mobile</sub> &equiv; 0. By Proposition 1, <i>N</i><sub>crit</sub> &equiv; <i>N</i><sub>init</sub> and preemption timing collapses identically into the conservative passive queue baseline.</li>
  <li><b>State 4: HARDWARE_FAILSAFE_FLASH (Cabinet Interlock Mode):</b> If electrical power fails or an invalid phase conflict is sensed, the hardware MMU crowbar drops the signal assembly into emergency flash within 450&nbsp;ms.</li>
</ul>

<h3>E. Embodiment 5: Empirical Sensitivity Analysis & Calibration Robustness</h3>
<p class="no-indent">To ensure robust real-world transferability across diverse geographic and climatic environments, we conducted comprehensive sensitivity analyses across key behavioral and communications parameters:</p>

<ul>
  <li><b>Driver Willingness (<i>c</i><sub>base</sub> &in; [0.70, 0.99]):</b> Under conservative driver compliance (<i>c</i><sub>base</sub> = 0.70), preemption green savings remain positive at +1.62&nbsp;s per intersection, while deceleration episodes remain bounded at 0.84 &plusmn; 0.89.</li>
  <li><b>Critical Gap Acceptance (<i>t<sub>c</sub></i> &in; [2.5, 5.0]&nbsp;s):</b> Under high adjacent lane demand (<i>t<sub>c</sub></i> = 5.0&nbsp;s, <i>P</i>(gap) = 0.65), the chance constraint automatically adjusts <i>N</i><sub>crit</sub> upward, preventing under-clearance and preserving zero complete stops.</li>
  <li><b>Cellular Packet Loss (<i>P</i><sub>loss</sub> &in; [0.01, 0.15]):</b> Even under severe urban multipath fading (<i>P</i><sub>loss</sub> = 0.15), CC-HLP maintains a 6.8% delay reduction and zero complete stops.</li>
</ul>

<h2>X. Statutory Patentability & Inventive Step Legal Memorandum</h2>

<div class="callout legal">
  <div class="callout-title">Legal Memorandum: Patentability under 35 U.S.C. &sect;&sect; 101, 102, 103 & Indian Patents Act &sect; 3(k)</div>
  <b>A. Subject-Matter Eligibility (35 U.S.C. &sect; 101 & Alice/Mayo Framework):</b><br>
  Under Step 1 of the <i>Alice/Mayo</i> framework, Claims 1–6 define a physical cyber-physical machine/apparatus; Claims 7–11 define an industrial process; Claim 15 defines an article of manufacture. Under Step 2A (Prong 2) and Step 2B, the claims integrate the mathematical quantile model into a specific physical cyber-physical application: controlling physical traffic signal phase transitions at a roadside cabinet, managing electrical contact closures, interfacing with an independent hardware MMU, and preventing physical vehicle decelerations on arterial roadways. Under USPTO 2019 Revised Guidance, the claims improve the technical functioning of traffic control systems and are patent-eligible.<br><br>
  <b>B. Indian Patents Act Section 3(k) & CRI Guidelines (2025 / April 29, 2026):</b><br>
  Under Section 3(k) of the Indian Patents Act, 1970, patentability is assessed based on whether the claimed invention exhibits a tangible technical contribution or produces a technical effect beyond a mere computer program or algorithm per se. In the CC-HLP architecture, the claimed system does not claim an abstract quantile in isolation, but physically couples real-time telemetry transceivers, fail-safe latency watchdogs, and roadside traffic signal controllers to actuate physical signal phase transitions and alter vehicular dynamics across an arterial corridor. While statutory patent eligibility ultimately depends on claim construction and examination under applicable national patent laws, CC-HLP is structured around specific cyber-physical apparatus elements and hardware interlocks rather than abstract software.<br><br>
  <b>C. Novelty under 35 U.S.C. &sect; 102:</b><br>
  No single prior art reference discloses all claim limitations:
  <ul>
    <li><i>Bachelder (US 7,868,783 B2)</i> lacks an individualized queue-yielding model, lacks a maneuver deadline feasibility expiration rule, lacks an exact Poisson-Binomial discrete quantile, and lacks an acoustic zero-adoption fallback equivalence proof.</li>
    <li><i>Sony (US 2026/0188114 A1)</i> discloses route notifications and infrastructure messaging for cooperative maneuvers; however, it lacks deadline-conditioned individual human yielding dynamics and does not formulate a chance-constrained residual queue quantile for signal phase scheduling.</li>
    <li><i>Ding et al. (IEEE T-ITS 2024)</i> is restricted to 100% automated CAV fleets; it lacks human driver perception-reaction models and stochastic mixed-traffic queue quantiles.</li>
    <li><i>Obrusn&iacute;k et al. (IFAC 2020)</i> treats all civilian vehicles as passive obstacles (<i>P</i><sub>yield</sub> = 0).</li>
  </ul>
  <b>D. Non-Obviousness under 35 U.S.C. &sect; 103:</b><br>
  A person having ordinary skill in the art (PHOSITA) would not find it obvious to combine mobile navigation alerts with queue-discharge preemption because prior art teaches that controllers should wait for reactive sensor confirmation. Following that teaching (Baseline 3) leads to severe failure (3.52 braking episodes). CC-HLP teaches away from reactive sensing, achieves unexpected superior technical results (54.0% braking reduction relative to reactive observers, 22.88 s aggregate green saved over passive baselines, zero complete stops), and satisfies a long-felt unsolved need.
</div>

<h2>XI. Formal Patent Claims Specification</h2>

<h4>CLAIM GROUP A: CYBER-PHYSICAL SYSTEM (APPARATUS CLAIMS)</h4>

<div class="claim-block">
<span class="claim-id">1.</span> <b>A cyber-physical system for closed-loop emergency vehicle preemption at a signalized intersection, comprising:</b>
<ul>
  <li>a vehicle telemetry interface configured to receive real-time kinematic coordinates comprising a position and speed of an approaching emergency vehicle;</li>
  <li>at least one queue sensor configured to detect an initial stationary queue count <i>N</i> occupying an approach lane of the intersection;</li>
  <li>an advisory-message interface communicatively coupled to a cloud network to broadcast opportunistic advisory notifications to mobile client devices located within a dynamic lookahead geofence upstream of the intersection;</li>
  <li>a traffic-signal controller interface operatively coupled to a roadside traffic signal cabinet;</li>
  <li>an edge controller processor coupled to the telemetry interface, the queue sensor, the advisory-message interface, and the traffic-signal controller interface, the processor configured to:
    <ul>
      <li>determine an individualized yielding probability <i>p<sub>i</sub></i> for each vehicle <i>i</i> &in; {1, &hellip;, <i>N</i>} conditioned on maneuver deadline feasibility and advisory notification delivery;</li>
      <li>compute a discrete probability distribution of a residual blocking queue <i>N</i><sub>rem</sub> based on blocker probabilities <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i>;</li>
      <li>determine an exact discrete risk-constrained quantile <i>N</i><sub>crit</sub> of the residual blocking queue satisfying <i>P</i>(<i>N</i><sub>rem</sub> &le; <i>N</i><sub>crit</sub>) &ge; 1 &minus; &epsilon;, wherein &epsilon; &in; [0.01, 0.10] is a predetermined risk tolerance;</li>
      <li>schedule a preemption initiation instant based on a clearance duration <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) and a mandatory signal transition duration <i>T</i><sub>transition</sub>; and</li>
      <li>transmit an actionable preemption command via the traffic-signal controller interface to actuate a green signal phase; and</li>
    </ul>
  </li>
  <li>a hardware Malfunction Management Unit (MMU) coupled to the traffic signal cabinet to physically enforce conflicting clearance intervals independently of software commands.</li>
</ul>
</div>

<div class="claim-block">
<span class="claim-id">2.</span> <b>The system of claim 1,</b> wherein the roadside edge controller processor evaluates an operating trade-off between cross-street civilian delay and emergency vehicle progression braking by tuning the risk tolerance parameter &epsilon; &in; [0.01, 0.10].
</div>

<div class="claim-block">
<span class="claim-id">3.</span> <b>The system of claim 1,</b> wherein scheduling the preemption initiation instant comprises evaluating the clearance duration <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) = <i>t<sub>L</sub></i> + <i>N</i><sub>crit</sub> &middot; <i>h<sub>s</sub></i> with an explicit zero boundary condition <i>T</i><sub>clear</sub>(0) = 0, wherein <i>N</i><sub>crit</sub> &lt; <i>N</i> when at least one queued vehicle satisfies the maneuver deadline feasibility condition &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &gt; 0.
</div>

<div class="claim-block">
<span class="claim-id">4.</span> <b>The system of claim 1,</b> wherein the dynamic lookahead geofence has an upstream distance <i>d</i><sub>decision</sub> = <i>v</i><sub>EV</sub> &middot; (<i>T</i><sub>transition</sub> + <i>t</i><sub>maneuver</sub>), spanning 220 to 466 meters.
</div>

<div class="claim-block">
<span class="claim-id">5.</span> <b>The system of claim 1,</b> further comprising a hardware watchdog timer monitoring latency of the advisory-message interface, configured to transition the processor to a conservative fallback mode when latency exceeds 800 milliseconds.
</div>

<div class="claim-block">
<span class="claim-id">6.</span> <b>The system of claim 5,</b> wherein the conservative fallback mode sets <i>P</i><sub>mobile</sub> = 0, causing the critical clearance queue to resolve to <i>N</i><sub>crit</sub> &equiv; <i>N</i> and allocating full passive queue clearance time <i>T</i><sub>clear</sub>(<i>N</i>) = <i>t<sub>L</sub></i> + <i>N</i> &middot; <i>h<sub>s</sub></i>.
</div>

<h4>CLAIM GROUP B: RESIDUAL-QUEUE PREEMPTION METHOD</h4>

<div class="claim-block">
<span class="claim-id">7.</span> <b>A method for dynamic emergency vehicle preemption at a signalized intersection, comprising:</b>
<ul>
  <li>receiving real-time telemetry comprising a position and speed of an approaching emergency vehicle;</li>
  <li>detecting, via at least one roadside sensor, an initial stationary queue count <i>N</i> in an approach lane of the intersection;</li>
  <li>obtaining, for each vehicle <i>i</i> &in; {1, &hellip;, <i>N</i>}, an individualized yielding probability <i>p<sub>i</sub></i> conditioned on alert perception, lateral gap availability, and a vehicle-specific maneuver deadline &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) = (&Delta;<i>x<sub>i</sub></i> &minus; <i>d</i><sub>safe</sub>) / <i>v</i><sub>EV</sub>;</li>
  <li>computing a discrete Poisson-Binomial distribution of a residual blocking queue <i>N</i><sub>rem</sub> based on blocker probabilities <i>q<sub>i</sub></i> = 1 &minus; <i>p<sub>i</sub></i>;</li>
  <li>calculating, using a predetermined risk tolerance parameter &epsilon;, an exact discrete quantile <i>N</i><sub>crit</sub> satisfying <i>P</i>(<i>N</i><sub>rem</sub> &le; <i>N</i><sub>crit</sub>) &ge; 1 &minus; &epsilon; via recursive discrete convolution;</li>
  <li>calculating a dynamic preemption lead time <i>T</i><sub>lead</sub> = <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) + <i>T</i><sub>transition</sub>, wherein <i>T</i><sub>clear</sub>(<i>N</i><sub>crit</sub>) enforces an explicit zero boundary condition <i>T</i><sub>clear</sub>(0) = 0; and</li>
  <li>actuating a preemption phase transition at the intersection when an estimated time of arrival (ETA) satisfies ETA &le; <i>T</i><sub>lead</sub>.</li>
</ul>
</div>

<div class="claim-block">
<span class="claim-id">8.</span> <b>The method of claim 7,</b> wherein obtaining the individualized yielding probability <i>p<sub>i</sub></i> comprises setting deadline completion feasibility <i>P</i>(feasible<sub><i>i</i></sub>) = 0.0 if &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &le; 0, and evaluating <i>P</i>(feasible<sub><i>i</i></sub>) via a lognormal cumulative distribution function if &Delta;<i>t</i><sub>deadline</sub>(<i>i</i>) &gt; 0.
</div>

<div class="claim-block">
<span class="claim-id">9.</span> <b>The method of claim 7,</b> wherein alert perception combines a digital mobile push notification channel and an acoustic siren channel: <i>P</i>(alert<sub><i>i</i></sub>) = 1 &minus; (1 &minus; <i>P</i><sub>mobile</sub>) &middot; (1 &minus; <i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>)).
</div>

<div class="claim-block">
<span class="claim-id">10.</span> <b>The method of claim 7,</b> wherein the recursive discrete convolution executes in <i>O</i>(<i>N</i><sup>2</sup>) time via recurrence <i>P<sub>k</sub></i>(<i>n</i>) = <i>P</i><sub><i>k</i>&minus;1</sub>(<i>n</i>) &middot; <i>p<sub>k</sub></i> + <i>P</i><sub><i>k</i>&minus;1</sub>(<i>n</i> &minus; 1) &middot; (1 &minus; <i>p<sub>k</sub></i>).
</div>

<div class="claim-block">
<span class="claim-id">11.</span> <b>The method of claim 7,</b> further comprising receiving maneuver confirmation telemetry from a subset of vehicles and updating corresponding probabilities <i>p<sub>i</sub></i> &leftarrow; 1.0 in real time.
</div>

<h4>CLAIM GROUP C: FAIL-SAFE WATCHDOG AND FALLBACK CONTROLLER</h4>

<div class="claim-block">
<span class="claim-id">12.</span> <b>An apparatus for fail-safe traffic signal preemption control under communication uncertainty, comprising a processor and a memory storing instructions that cause the processor to:</b>
<ul>
  <li>monitor an operational status and network latency of an advisory-message interface;</li>
  <li>operate in a predictive preemption mode when the advisory-message interface is operational, calculating preemption timing based on a risk-bounded quantile <i>N</i><sub>crit</sub> &lt; <i>N</i> derived from alert-induced yielding probabilities;</li>
  <li>transition to a conservative fallback mode upon detecting that advisory communications have become stale, delayed beyond an 800-millisecond threshold, or unavailable; and</li>
  <li>schedule preemption green initiation using the full conservative queue clearance time <i>T</i><sub>clear</sub>(<i>N</i>) = <i>t<sub>L</sub></i> + <i>N</i> &middot; <i>h<sub>s</sub></i>, thereby ensuring complete queue dissipation without relying on unconfirmed voluntary driver yielding.</li>
</ul>
</div>

<div class="claim-block">
<span class="claim-id">13.</span> <b>The apparatus of claim 12,</b> wherein the fallback mode sets <i>P</i>(alert<sub><i>i</i></sub>) = <i>P</i><sub>acoustic</sub>(&Delta;<i>x<sub>i</sub></i>) and evaluates acoustic attenuation at &Delta;<i>x<sub>i</sub></i> &ge; 150.0 + 32.5 <i>N</i>&nbsp;m.
</div>

<div class="claim-block">
<span class="claim-id">14.</span> <b>The apparatus of claim 13,</b> wherein the processor establishes <i>N</i><sub>crit</sub> &equiv; <i>N</i> by evaluating &prod;<sub><i>i</i>=1</sub><sup><i>N</i></sup> <i>q<sub>i</sub></i> &ge; [1 &minus; <i>p&#772;</i>(<i>N</i>)]<sup><i>N</i></sup> &gt; &epsilon; across all <i>N</i> &ge; 1.
</div>

<h4>CLAIM GROUP D: COMPUTER-READABLE MEDIUM</h4>

<div class="claim-block">
<span class="claim-id">15.</span> <b>A non-transitory computer-readable medium</b> storing instructions that, when executed by a processor of an edge traffic controller, cause the processor to perform the method of claim 7.
</div>

<h2>XII. Mathematical Notation, Variable Taxonomy, and Physical Dimensions</h2>

<p class="no-indent">Table V provides a formal, comprehensive taxonomy of all mathematical variables, parameters, physical dimensions, and calibrated nominal values employed in the CC-HLP framework.</p>

<div class="tbl-caption">TABLE V: Comprehensive Mathematical Notation, Definitions, Physical Units, and Nominal Calibrations</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>Symbol</th>
      <th>Definition & Semantics</th>
      <th>SI Unit</th>
      <th>Calibrated Nominal Value</th>
      <th>Governing Reference</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>&Delta;<i>t</i><sub>decision</sub></td>
      <td>Preemption Decision Horizon (<i>T</i><sub>transition</sub> + <i>t</i><sub>maneuver</sub>)</td>
      <td>Seconds (s)</td>
      <td>[11.0, 23.3] s (Nominal &approx; 13.0 s)</td>
      <td>Kinematic Horizon Derivation</td>
    </tr>
    <tr>
      <td><i>d</i><sub>decision</sub></td>
      <td>Spatial Lookahead Distance (<i>v</i><sub>EV</sub> &middot; &Delta;<i>t</i><sub>decision</sub>)</td>
      <td>Meters (m)</td>
      <td>220 to 466 m (Nominal &approx; 260 m)</td>
      <td>Kinematic Horizon Derivation</td>
    </tr>
    <tr>
      <td><i>T</i><sub>transition</sub></td>
      <td>Signal Phase Transition Latency</td>
      <td>Seconds (s)</td>
      <td>[5.5, 13.5] s (Nominal &approx; 7.5–8.0 s)</td>
      <td>NEMA TS2 Standard</td>
    </tr>
    <tr>
      <td><i>t<sub>L</sub></i></td>
      <td>Intersection Startup Lost Time</td>
      <td>Seconds (s)</td>
      <td>2.0 s</td>
      <td>Webster (1958)</td>
    </tr>
    <tr>
      <td><i>h<sub>s</sub></i></td>
      <td>Saturation Departure Headway</td>
      <td>s/veh</td>
      <td>2.0 s/veh (1800 veh/h/lane)</td>
      <td>Highway Capacity Manual</td>
    </tr>
    <tr>
      <td><i>l</i><sub>veh</sub></td>
      <td>Queue Vehicle Slot Length</td>
      <td>Meters (m)</td>
      <td>7.5 m</td>
      <td>IRC:SP:41 Standard</td>
    </tr>
    <tr>
      <td><i>v</i><sub>EV</sub></td>
      <td>Emergency Vehicle Cruising Speed</td>
      <td>m/s</td>
      <td>20.0 m/s (72.0 km/h)</td>
      <td>Arterial Transit Model</td>
    </tr>
    <tr>
      <td>&mu;<sub><i>m</i></sub>, &sigma;<sub><i>m</i></sub></td>
      <td>Lognormal Human Maneuver Parameters</td>
      <td>Log-seconds</td>
      <td>&mu;<sub><i>m</i></sub> = 1.705, &sigma;<sub><i>m</i></sub> = 0.35 (Median 5.5 s)</td>
      <td>NHTSA DOT HS 811 144</td>
    </tr>
    <tr>
      <td><i>d</i><sub>safe</sub></td>
      <td>EV Longitudinal Safety Perimeter</td>
      <td>Meters (m)</td>
      <td>15.0 m</td>
      <td>Safety Kinematics</td>
    </tr>
    <tr>
      <td>&Delta;<i>t</i><sub>deadline</sub>(<i>i</i>)</td>
      <td>Maneuver Deadline for Vehicle <i>i</i></td>
      <td>Seconds (s)</td>
      <td>(&Delta;<i>x<sub>i</sub></i> &minus; <i>d</i><sub>safe</sub>) / <i>v</i><sub>EV</sub></td>
      <td>Kinematic Derivation</td>
    </tr>
    <tr>
      <td><i>d</i><sub>mid</sub>, &sigma;<sub>audio</sub></td>
      <td>Acoustic Siren Attenuation Parameters</td>
      <td>Meters (m)</td>
      <td><i>d</i><sub>mid</sub> = 180.0 m, &sigma;<sub>audio</sub> = 30.0 m</td>
      <td>ISO 7731 Cabin Sound Decay</td>
    </tr>
    <tr>
      <td><i>P</i><sub>loss</sub></td>
      <td>Cellular-V2X Radio Packet Loss</td>
      <td>Dimensionless</td>
      <td>0.04 (4.0%)</td>
      <td>3GPP Rel-16 Urban C-V2X</td>
    </tr>
    <tr>
      <td><i>c</i><sub>base</sub></td>
      <td>Baseline Driver Willingness</td>
      <td>Dimensionless</td>
      <td>0.92 (92.0%)</td>
      <td>Lidestam et al. (2020)</td>
    </tr>
    <tr>
      <td><i>P</i>(gap)</td>
      <td>Adjacent Lane Gap Availability</td>
      <td>Dimensionless</td>
      <td>0.82 (82.0%)</td>
      <td>Critical Gap Theory (<i>t<sub>c</sub></i> = 3.5 s)</td>
    </tr>
    <tr>
      <td><i>N</i><sub>init</sub></td>
      <td>Initial Queue Count at Stopline</td>
      <td>Vehicles</td>
      <td><i>N</i> &sim; Poisson(&lambda;=8.0)</td>
      <td>Stopline Detector Rack</td>
    </tr>
    <tr>
      <td><i>N</i><sub>crit</sub></td>
      <td>Critical Clearance Quantile</td>
      <td>Vehicles</td>
      <td>Discrete integer <i>n</i> &le; <i>N</i><sub>init</sub></td>
      <td>Poisson-Binomial Quantile</td>
    </tr>
    <tr>
      <td>&epsilon;</td>
      <td>System Risk Tolerance Parameter</td>
      <td>Dimensionless</td>
      <td>&epsilon; &in; [0.01, 0.10] (Nominal &epsilon; = 0.05)</td>
      <td>Chance-Constrained Target</td>
    </tr>
    <tr>
      <td>&rho;<sub>app</sub></td>
      <td>Mobile App Penetration Rate</td>
      <td>Dimensionless</td>
      <td>&rho; &in; [0.0, 1.0] (Nominal &rho; = 0.60)</td>
      <td>Market Penetration Sweep</td>
    </tr>
    <tr>
      <td>&tau;<sub>latency</sub></td>
      <td>End-to-End Communications Latency</td>
      <td>Milliseconds (ms)</td>
      <td>Hard Threshold: 800 ms</td>
      <td>Watchdog Specification</td>
    </tr>
    <tr>
      <td>&tau;*</td>
      <td>Preemption Actuation Instant</td>
      <td>Timestamp (s)</td>
      <td>inf { <i>t</i> | ETA(<i>t</i>) &le; <i>T</i><sub>lead</sub> }</td>
      <td>Boundary Operator</td>
    </tr>
  </tbody>
</table>

<h2>XIII. Roadside Cabinet Hardware Interface & SDLC Protocol Specification</h2>

<p class="no-indent">To ensure reproducible industrial deployment across municipal infrastructure, Table VI details the physical electrical wiring and SDLC Port 1 frame format interfacing the CC-HLP edge processor with a standard NEMA TS2 Type 1 / ATC 5301 traffic signal controller cabinet.</p>

<div class="tbl-caption">TABLE VI: NEMA TS2 SDLC Port 1 Physical Interface & Electrical Pinout Specification</div>
<table class="styled-table">
  <thead>
    <tr>
      <th>Signal Line</th>
      <th>DB-25 Pin</th>
      <th>Electrical Level</th>
      <th>Data Rate & Direction</th>
      <th>Functional Role</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>TX Data (+)</td>
      <td>Pin 2</td>
      <td>EIA-485 Differential (+)</td>
      <td>153.6 kbps (Output)</td>
      <td>Preemption Command Frame 0x2A</td>
    </tr>
    <tr>
      <td>TX Data (-)</td>
      <td>Pin 14</td>
      <td>EIA-485 Differential (-)</td>
      <td>153.6 kbps (Output)</td>
      <td>Inverted Transmit Channel</td>
    </tr>
    <tr>
      <td>RX Data (+)</td>
      <td>Pin 3</td>
      <td>EIA-485 Differential (+)</td>
      <td>153.6 kbps (Input)</td>
      <td>Phase Status Telemetry (BIU)</td>
    </tr>
    <tr>
      <td>RX Data (-)</td>
      <td>Pin 16</td>
      <td>EIA-485 Differential (-)</td>
      <td>153.6 kbps (Input)</td>
      <td>Inverted Receive Channel</td>
    </tr>
    <tr>
      <td>Signal Ground</td>
      <td>Pin 7</td>
      <td>0.0 V Reference</td>
      <td>Common Ground</td>
      <td>Isolated Logic Ground</td>
    </tr>
    <tr>
      <td>Preempt Call 1</td>
      <td>Detector Rack C1</td>
      <td>24 V DC Optical Relay</td>
      <td>Dry Contact Closure</td>
      <td>Hardware Preemption Override</td>
    </tr>
    <tr>
      <td>MMU Sense Lead</td>
      <td>MMU-16LE Aux</td>
      <td>120 V AC Field Voltage</td>
      <td>Continuous Monitor</td>
      <td>Hardware Conflict Interlock</td>
    </tr>
  </tbody>
</table>

<p>The SDLC command frame operates with a fixed 16-byte structure: <code>[0xFF, 0xFF, ADDR=0x01, CMD=0x2A, PREEMPT_TYPE=0x01, TARGET_PHASE=0x02, CLEAR_TIME_HI, CLEAR_TIME_LO, LATENCY_MS, WATCHDOG_CTR, CRC16_HI, CRC16_LO]</code>. If the cabinet Bus Interface Unit (BIU) detects an invalid CRC or missing frame for &gt;800&nbsp;ms, it initiates local timer fallback.</p>

<h2>XIV. Indian Patent Office (IPO) Complete Specification & Filing Checklist</h2>

<p class="no-indent">In strict accordance with Section 10 and Rule 13 of the Indian Patents Act, 1970, this disclosure is structured to serve as an official Form 2 Complete Specification. Indian resident inventors must comply with Section 39 before foreign filing:</p>

<ol>
  <li><b>Form 1 (Application for Grant of Patent):</b> To be filed electronically via the IPO portal naming Himanshu Singh as Sole Inventor and Applicant.</li>
  <li><b>Form 2 (Complete Specification):</b> Contains:
    <ul>
      <li><i>Title:</i> Chance-Constrained Human-in-the-Loop Emergency Vehicle Preemption System and Method.</li>
      <li><i>Field of Invention:</i> Intelligent Transportation Systems, Cyber-Physical Traffic Signal Control, and Connected Vehicle Telematics.</li>
      <li><i>Background & Prior Art Deficiencies:</i> Full analysis of fixed-distance triggers, passive queue preemption (Obrusn&iacute;k et al.), and cellular preemption (Bachelder US 7,868,783 B2).</li>
      <li><i>Summary of Invention:</i> Complete disclosure of deadline-conditioned yielding probabilities, Poisson-Binomial quantile inversion, and zero-adoption fallback equivalence.</li>
      <li><i>Brief Description of Drawings:</i> Description of Fig. 1 (System Architecture), Fig. 2 (Timing Horizon), and Fig. 3 (Simulation Results).</li>
      <li><i>Detailed Description:</i> Comprehensive technical embodiments 1–5, Algorithm 1, and mathematical proofs.</li>
      <li><i>Statement of Claims:</i> Claims 1 through 15 (Group A: Apparatus Claims 1–6; Group B: Method Claims 7–11; Group C: Fail-Safe Controller Claims 12–14; Group D: Storage Medium Claim 15).</li>
      <li><i>Abstract:</i> Concise summary (&lt;150 words) outlining technical contribution.</li>
    </ul>
  </li>
  <li><b>Form 3 (Statement & Undertaking under Section 8):</b> Undertaking to keep the Controller informed of foreign patent filings (USPTO, PCT).</li>
  <li><b>Form 5 (Declaration as to Inventorship):</b> Formal declaration confirming inventorship.</li>
  <li><b>Form 25 (Foreign Filing License):</b> If filing directly in the USPTO or WIPO/PCT prior to IPO submission, file Form 25 with the Controller General to obtain statutory clearance within 21 days under Section 39.</li>
</ol>

<h2>XV. Conclusion and Implementation Roadmap</h2>

<p class="no-indent">This paper and patent disclosure formulated, analyzed, and benchmarked <b>Chance-Constrained Human-in-the-Loop Preemption (CC-HLP)</b>, an integrated cyber-physical preemption framework bridging in-cabin mobile participatory alerts with roadside traffic signal controllers. By modeling individual driver maneuver deadline feasibility and evaluating an exact Poisson-Binomial quantile over residual blockers, CC-HLP bridges the physical sequential decision horizon spanning &Delta;<i>t</i><sub>decision</sub> &in; [11.0, 23.3]&nbsp;s (nominal &approx; 13.0&nbsp;s).</p>

<p>Across 50 audited paired Monte Carlo simulation runs on a 3.2&nbsp;km arterial corridor:</p>
<ol>
  <li>A reactive sensor observer suffers from 3.52 &plusmn; 1.11 severe EV braking episodes per run due to sensor polling and maneuver completion latency.</li>
  <li>CC-HLP slashes EV braking by <b>54.0%</b> (1.62 &plusmn; 1.24 episodes, <i>p</i> &lt; 10<sup>&minus;12</sup>) and matches free-flow transit (161.4 &plusmn; 7.5&nbsp;s) with zero complete stops.</li>
  <li>CC-HLP saves <b>22.88 seconds (15.8%) of aggregate preemption green</b> (4.58&nbsp;s per junction, <i>p</i> &lt; 10<sup>&minus;30</sup>), reducing cross-street delay by <b>16.7%</b> (47.4 &plusmn; 4.2&nbsp;s vs. 56.9 &plusmn; 5.5&nbsp;s/veh, <i>p</i> = 1.78 &times; 10<sup>&minus;15</sup>).</li>
  <li>We prove mathematically that CC-HLP inherently recovers the conservative passive queue-discharge schedule when app adoption is zero (&rho;<sub>app</sub> = 0.0).</li>
</ol>

<h2>XVI. Verified Academic & Patent References</h2>

<ol class="ref-list">
  <li>V. Obrusn&iacute;k, I. Herman, and Z. Hur&aacute;k, &ldquo;Queue discharge-based emergency vehicle traffic signal preemption,&rdquo; <i>IFAC-PapersOnLine</i>, vol. 53, no. 2, pp. 14997&ndash;15002, 2020. doi: 10.1016/j.ifacol.2020.12.1998.</li>
  <li>B. Lidestam, B. Thorslund, H. Selander, D. N&auml;sman, and J. Dahlman, &ldquo;In-car warnings of emergency vehicles approaching: Effects on car drivers&rsquo; propensity to give way,&rdquo; <i>Frontiers in Sustainable Cities</i>, vol. 2, art. 19, 2020. doi: 10.3389/frsc.2020.00019.</li>
  <li>National Highway Traffic Safety Administration (NHTSA), &ldquo;Analysis of light vehicle lane change crashes and potential active safety system approaches,&rdquo; U.S. Dept. of Transportation, Tech. Rep. DOT HS 811 144, 2009.</li>
  <li>Federal Highway Administration (FHWA), <i>Highway Capacity Manual (HCM)</i>, 6th ed. Washington, DC: Transportation Research Board, 2016.</li>
  <li>National Electrical Manufacturers Association, <i>Traffic Controller Assemblies with NEMA TS 2 Requirements</i>, NEMA Standard TS 2-2016, Rosslyn, VA, 2016.</li>
  <li>International Organization for Standardization, <i>Ergonomics &mdash; Danger signals for public and work areas &mdash; Auditory danger signals</i>, ISO Standard 7731:2003, Geneva, Switzerland, 2003.</li>
  <li>F. V. Webster, &ldquo;Traffic signal settings,&rdquo; <i>Road Research Technical Paper No. 39</i>, Her Majesty's Stationery Office, London, UK, 1958.</li>
  <li>Y. Hong, &ldquo;On computing the distribution function for the Poisson binomial distribution,&rdquo; <i>Computational Statistics & Data Analysis</i>, vol. 59, pp. 41&ndash;51, 2013.</li>
  <li>Indian Roads Congress, <i>Guidelines on Design for Signalized Intersections</i>, IRC:SP:41-1994, New Delhi, India, 1994.</li>
  <li>D. Krajzewicz, J. Erdmann, M. Behrisch, and L. Bieker, &ldquo;Recent development and applications of SUMO - Simulation of Urban MObility,&rdquo; <i>Int. Journal On Advances in Systems and Measurements</i>, vol. 5, no. 3&4, pp. 128&ndash;138, 2012.</li>
  <li>C. Ding, I. W.-H. Ho, E. Chung, and T. Fan, &ldquo;V2X and deep reinforcement learning-aided mobility-aware lane changing for emergency vehicle preemption in connected autonomous transport systems,&rdquo; <i>IEEE Transactions on Intelligent Transportation Systems</i>, vol. 25, no. 7, pp. 7281&ndash;7293, 2024. doi: 10.1109/TITS.2024.3350334.</li>
  <li>Sony Group Corporation, &ldquo;Multi-user navigation system and information processing method,&rdquo; U.S. Patent Application 2026/0188114 A1, published July 2, 2026.</li>
  <li>D. Roja Ramani, T. S. Usha Rani, S. Soja Rani, C. B. Chempavathy, G. Vijayasekaran, and S. V. Bhaskar, &ldquo;Emergency vehicle intelligent detection and signal preemption framework using Monte Carlo simulation,&rdquo; in <i>Proc. 9th Int. Conf. Trends Electron. Informatics (ICOEI)</i>, 2026, pp. 449&ndash;454. doi: 10.1109/ICOEI68323.2026.11541639.</li>
  <li>M. Lamrabet, M. Alami Chentoufi, and R. Ellaia, &ldquo;Emergency-aware adaptive traffic signal control using YOLO-based light-bar detection and SUMO system-level validation,&rdquo; <i>IEEE Access</i>, vol. 14, pp. 104922&ndash;104933, July 2026. doi: 10.1109/ACCESS.2026.3710015.</li>
  <li>N. Heusser, C. Temme, and L.-C. Fuerstenberg, &ldquo;System and method for enhanced routing for traffic signal preemption and priority,&rdquo; U.S. Patent Application 2026/0266618 A1, assigned to Neutron Edge, Inc., published Sept. 10, 2026.</li>
  <li>A. D. Bachelder, &ldquo;Cellular-based preemption system,&rdquo; U.S. Patent 7,868,783 B2, issued Jan. 11, 2011.</li>
  <li>H. Liu, J. Wu, L. Zhao, and M. Wang, &ldquo;A collaborative control framework: Achieving emergency vehicle priority while minimizing negative impact on ordinary vehicles at signalized intersection,&rdquo; <i>Journal of Advanced Transportation</i>, vol. 2024, art. 6689123, 2024. doi: 10.1155/2024/6689123.</li>
  <li>Z. Chen, Y. Zhang, X. Sun, and H. Zhou, &ldquo;A coordinated optimization strategy integrating dynamic emergency lane management and signal pre-emption in complex traffic systems,&rdquo; <i>Transportmetrica A: Transport Science</i>, published online Apr. 19, 2026. doi: 10.1080/23249935.2026.2341902.</li>
</ol>

</div>

</body>
</html>
"""

# Replace image placeholder
clean_html = raw_html.replace("__IMG_B64__", img_b64)

html_path = "/Users/himanshusingh/project/green_corridor/scratch/cchlp_perfect_manuscript.html"
pdf_path = "/Users/himanshusingh/project/green_corridor/Green_Corridor_Patent_Specification_v12.pdf"

with open(html_path, "w", encoding="utf-8") as f:
    f.write(clean_html)

print(f"Wrote clean HTML to {html_path}")

cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",
    "--disable-gpu",
    "--run-all-compositor-stages-before-draw",
    f"--print-to-pdf={pdf_path}",
    html_path
]

print("Compiling perfect PDF with Google Chrome headless...")
subprocess.run(cmd, check=True)

# Verify page count and character count per page
url = NSURL.fileURLWithPath_(pdf_path)
doc = Quartz.PDFDocument.alloc().initWithURL_(url)
page_count = doc.pageCount() if doc else 0

blank_pages = []
for i in range(page_count):
    page = doc.pageAtIndex_(i)
    txt = page.string()
    if not txt or len(txt.strip()) == 0:
        blank_pages.append(i + 1)
    else:
        sample = txt[:50].replace('\n', ' ').strip()
        print(f"Page {i+1}: {len(txt)} chars | '{sample}...'")

print(f"SUCCESS: Generated PDF '{pdf_path}' with {page_count} pages! Blank pages: {blank_pages}")
