"""
CC-HLP Demonstrator Runner
Connects trajectory simulation, CC-HLP Estimator, Safety State Machine, and Display.
"""
import time
import csv
import os
from .estimator import CCHLPEstimator
from .state_machine import SignalStateMachine, SignalPhase
from .hal_display import SignalDisplayHAL

def run_demonstration(
    x_start: float = -350.0,
    v_ev: float = 20.0,
    N_init: int = 8,
    p_mobile: float = 0.85,
    epsilon: float = 0.05,
    dt: float = 0.5,
    log_file: str = "cchlp_hil_demonstration_log.csv"
):
    print("=" * 80)
    print("🚀 CC-HLP HARDWARE-IN-THE-LOOP (HIL) BENCHTOP DEMONSTRATOR")
    print(f"Parameters: Start={x_start}m, Speed={v_ev} m/s ({v_ev*3.6:.0f} km/h), N_init={N_init}, Epsilon={epsilon}")
    print("=" * 80)

    estimator = CCHLPEstimator()
    hal = SignalDisplayHAL(mode="AUTO")
    state_machine = SignalStateMachine(
        t_yellow=3.5,
        t_all_red=2.0,
        output_hook=hal.render_phase
    )

    x_ev = x_start
    preempt_called = False
    records = []

    # Initial display
    hal.render_phase(state_machine.current_phase)
    print("\nStarting simulated vehicle approach...")

    try:
        while x_ev <= 40.0:
            step_start = time.time()
            ev_cleared = (x_ev >= 10.0)

            # 1. CC-HLP Estimator Decision
            decision = estimator.evaluate_preemption_decision(
                N_init=N_init,
                x_ev=x_ev,
                v_ev=v_ev,
                x_stopline=0.0,
                p_mobile=p_mobile,
                epsilon=epsilon
            )

            if decision["should_preempt"] and not preempt_called:
                preempt_called = True
                print(f"\n\n🚨 [BOUNDARY CROSSING TRIGGER] ETA: {decision['eta']:.1f}s <= T_lead: {decision['T_lead']:.1f}s!")
                print(f"   Standing Queue: {N_init} cars ──> Critical Residual Blockers N_crit: {decision['N_crit']}")
                print(f"   Yielding Probabilities p_i: {[round(p, 2) for p in decision['yielding_probs']]}\n")

            # 2. Update Safety State Machine
            state_machine.update(preempt_call=preempt_called, ev_cleared=ev_cleared)

            # 3. Log Record
            records.append({
                "time_sim": round(-x_start / v_ev + (x_ev - x_start) / v_ev, 2),
                "x_ev": round(x_ev, 2),
                "v_ev": v_ev,
                "eta": round(decision["eta"], 2),
                "N_init": N_init,
                "N_crit": decision["N_crit"],
                "T_lead": round(decision["T_lead"], 2),
                "phase": state_machine.current_phase.value,
                "preempt_called": preempt_called
            })

            # Advance vehicle kinematics
            x_ev += v_ev * dt

            # Sleep to match real wall-clock time for bench demonstration
            elapsed = time.time() - step_start
            sleep_time = max(0.0, dt - elapsed)
            time.sleep(sleep_time)

        # Ensure return to normal
        time.sleep(2.0)
        state_machine.update(preempt_call=False, ev_cleared=True)
        print("\n\n✅ Emergency vehicle has cleared the intersection. Corridor successfully concluded.")

    finally:
        hal.cleanup()

        # Save CSV Log
        if records:
            keys = records[0].keys()
            with open(log_file, "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=keys)
                writer.writeheader()
                writer.writerows(records)
            print(f"📄 Saved full telemetry and decision log to: {log_file}")

if __name__ == "__main__":
    run_demonstration()
