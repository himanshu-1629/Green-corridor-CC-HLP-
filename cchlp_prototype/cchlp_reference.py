"""
CC-HLP Reference Specification & Verification Model
Implements the exact algorithmic core and invariant self-tests from the Working Guide.
"""
from dataclasses import dataclass, field
import math
from typing import Sequence, List, Dict, Any, Union

@dataclass(frozen=True)
class ModelParameters:
    vehicle_slot_m: float = 7.5
    safe_buffer_m: float = 15.0
    maneuver_mu: float = 1.705
    maneuver_sigma: float = 0.35
    acoustic_midpoint_m: float = 180.0
    acoustic_scale_m: float = 30.0
    willingness: float = 0.92
    gap_probability: float = 0.82
    app_penetration: float = 0.60
    packet_loss: float = 0.05
    startup_lost_s: float = 2.0
    saturation_headway_s: float = 2.0
    epsilon: float = 0.05

    def validate(self) -> None:
        """Validates physical and probability bounds."""
        if self.vehicle_slot_m <= 0:
            raise ValueError("vehicle_slot_m must be strictly positive.")
        if self.safe_buffer_m < 0:
            raise ValueError("safe_buffer_m cannot be negative.")
        if self.maneuver_sigma <= 0:
            raise ValueError("maneuver_sigma must be positive.")
        if not 0.0 <= self.willingness <= 1.0:
            raise ValueError("willingness must be in [0, 1].")
        if not 0.0 <= self.gap_probability <= 1.0:
            raise ValueError("gap_probability must be in [0, 1].")
        if not 0.0 <= self.app_penetration <= 1.0:
            raise ValueError("app_penetration must be in [0, 1].")
        if not 0.0 <= self.packet_loss <= 1.0:
            raise ValueError("packet_loss must be in [0, 1].")
        if self.startup_lost_s < 0 or self.saturation_headway_s <= 0:
            raise ValueError("Clearance headways must be non-negative.")
        if not 0.0 < self.epsilon < 1.0:
            raise ValueError("epsilon must be strictly between 0 and 1.")

def yielding_probability(
    *,
    ev_x_m: float,
    vehicle_x_m: float,
    ev_speed_mps: float,
    params: ModelParameters,
    mobile_channel_available: bool = True,
) -> float:
    """
    Evaluates individual driver voluntary yielding probability p_i.
    Strict geometry fail-closed: vehicle_x_m must be strictly downstream of ev_x_m.
    """
    params.validate()
    if ev_speed_mps <= 0:
        raise ValueError("ev_speed_mps must be strictly positive.")
    
    # Invariant: EV must be upstream of vehicle. Never use abs(delta_x).
    if vehicle_x_m <= ev_x_m:
        raise ValueError(f"Invalid geometry: vehicle_x_m ({vehicle_x_m}) must be downstream of ev_x_m ({ev_x_m}).")

    delta_x = vehicle_x_m - ev_x_m

    # If inside safe perimeter, deadline feasibility is zero
    if delta_x <= params.safe_buffer_m:
        return 0.0

    delta_t_deadline = (delta_x - params.safe_buffer_m) / ev_speed_mps
    if delta_t_deadline <= 0:
        p_feasible = 0.0
    else:
        # Lognormal cumulative distribution function
        z = (math.log(delta_t_deadline) - params.maneuver_mu) / (params.maneuver_sigma * math.sqrt(2.0))
        p_feasible = 0.5 * (1.0 + math.erf(z))

    # Acoustic siren perception
    p_acoustic = 1.0 / (1.0 + math.exp((delta_x - params.acoustic_midpoint_m) / params.acoustic_scale_m))

    # In-cabin digital alert perception
    if mobile_channel_available:
        p_mobile = params.app_penetration * (1.0 - params.packet_loss)
    else:
        p_mobile = 0.0

    # Dual-channel alert perception
    p_alert = 1.0 - (1.0 - p_mobile) * (1.0 - p_acoustic)

    # Net voluntary yielding probability
    p_yield = p_alert * params.willingness * params.gap_probability * p_feasible
    return max(0.0, min(1.0, p_yield))

def blocker_pmf(yield_probabilities: Sequence[float]) -> List[float]:
    """
    Computes exact discrete PMF of residual blockers using recursive convolution.
    Index n represents exactly n remaining blocking vehicles.
    """
    pmf = [1.0]
    for p_yield in yield_probabilities:
        p_block = 1.0 - p_yield
        next_pmf = [0.0] * (len(pmf) + 1)
        for blockers, mass in enumerate(pmf):
            next_pmf[blockers] += mass * p_yield
            next_pmf[blockers + 1] += mass * p_block
        pmf = next_pmf
    return pmf

def critical_queue(yield_probabilities: Sequence[float], epsilon: float = 0.05) -> int:
    """Smallest blocker count whose CDF is at least 1-epsilon."""
    if not 0.0 < epsilon < 1.0:
        raise ValueError("epsilon must be strictly between 0 and 1.")
    pmf = blocker_pmf(yield_probabilities)
    cumulative = 0.0
    for n_blockers, mass in enumerate(pmf):
        cumulative += mass
        if cumulative + 1e-15 >= 1.0 - epsilon:
            return n_blockers
    return len(yield_probabilities)  # numerical safety fallback

def queue_vehicle_positions(queue_count: int, slot_m: float = 7.5) -> List[float]:
    """Vehicle reference points nearest-to-farthest, all upstream of x=0."""
    if queue_count < 0:
        raise ValueError("queue_count cannot be negative.")
    if slot_m <= 0:
        raise ValueError("slot_m must be positive.")
    # Treat position as a nominal vehicle reference point at the slot midpoint.
    return [-(idx + 0.5) * slot_m for idx in range(queue_count)]

def evaluate_approach(
    *,
    ev_distance_to_stopline_m: float,
    ev_speed_mps: float,
    queue_count: int,
    transition_s: float,
    params: ModelParameters,
    mobile_channel_available: bool = True,
) -> Dict[str, Union[float, int, bool, List[float]]]:
    """Compute one decision snapshot. It does not operate hardware or actuate lamps."""
    params.validate()
    if ev_distance_to_stopline_m <= 0 or ev_speed_mps <= 0:
        raise ValueError("EV must be upstream of the stopline and moving forward.")
    if queue_count < 0 or transition_s < 0:
        raise ValueError("Queue count and transition time must be non-negative.")
    ev_x = -ev_distance_to_stopline_m
    positions = queue_vehicle_positions(queue_count, params.vehicle_slot_m)
    probabilities = [
        yielding_probability(
            ev_x_m=ev_x,
            vehicle_x_m=x_i,
            ev_speed_mps=ev_speed_mps,
            params=params,
            mobile_channel_available=mobile_channel_available,
        )
        for x_i in positions
    ]
    n_crit = critical_queue(probabilities, params.epsilon)
    t_clear = 0.0 if n_crit == 0 else params.startup_lost_s + n_crit * params.saturation_headway_s
    t_lead = t_clear + transition_s
    eta = ev_distance_to_stopline_m / ev_speed_mps
    return {
        "eta_s": eta,
        "queue_count": queue_count,
        "yield_probabilities": probabilities,
        "n_crit": n_crit,
        "t_clear_s": t_clear,
        "transition_s": transition_s,
        "t_lead_s": t_lead,
        "preemption_due_in_model": eta <= t_lead,
        "mobile_channel_available": mobile_channel_available,
    }

def run_self_tests() -> None:
    """Fast checks for algorithmic invariants; not system-safety certification."""
    assert critical_queue([], 0.05) == 0
    assert critical_queue([0.0, 0.0, 0.0], 0.05) == 3
    assert critical_queue([1.0, 1.0, 1.0], 0.05) == 0
    pmf = blocker_pmf([0.2, 0.5, 0.9])
    assert len(pmf) == 4
    assert abs(sum(pmf) - 1.0) < 1e-12
    assert all(x >= 0.0 for x in pmf)
    
    # Geometry must fail closed; abs(delta_x) must never turn invalid geometry valid.
    try:
        yielding_probability(
            ev_x_m=-10.0, vehicle_x_m=-20.0, ev_speed_mps=20.0,
            params=ModelParameters(),
        )
    except ValueError:
        pass
    else:
        raise AssertionError("Invalid vehicle/EV ordering was not rejected.")
        
    # At zero app penetration, the model still allows non-zero acoustic detection;
    # fallback equivalence is a theorem conditional on its full assumptions, not an
    # automatic implementation guarantee.
    p = yielding_probability(
        ev_x_m=-300.0, vehicle_x_m=-30.0, ev_speed_mps=20.0,
        params=ModelParameters(app_penetration=0.0),
        mobile_channel_available=False,
    )
    assert 0.0 <= p <= 1.0
    print("✅ All CC-HLP algorithmic self-tests passed successfully!")

if __name__ == "__main__":
    run_self_tests()
    example = evaluate_approach(
        ev_distance_to_stopline_m=260.0,
        ev_speed_mps=20.0,
        queue_count=8,
        transition_s=7.5,
        params=ModelParameters(),
        mobile_channel_available=True,
    )
    print("\n--- CC-HLP Reference Decision Snapshot ---")
    print(f"ETA: {example['eta_s']:.2f} s")
    print(f"N_init: {example['queue_count']}")
    print("P(yield):", [round(p, 4) for p in example["yield_probabilities"]])
    print(f"N_crit: {example['n_crit']}")
    print(f"T_clear: {example['t_clear_s']:.2f} s")
    print(f"T_lead: {example['t_lead_s']:.2f} s")
    print(f"Preemption due according to model: {example['preemption_due_in_model']}")
