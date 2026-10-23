"""
CC-HLP Estimator Wrapper
Delegates directly to cchlp_reference.py ensuring single source of truth.
"""
from typing import List, Dict, Any
from .cchlp_reference import (
    ModelParameters,
    yielding_probability,
    blocker_pmf,
    critical_queue,
    queue_vehicle_positions,
    evaluate_approach
)

class CCHLPEstimator:
    def __init__(
        self,
        vehicle_length: float = 7.5,
        d_safe: float = 15.0,
        mu_m: float = 1.705,
        sigma_m: float = 0.35,
        c_base: float = 0.92,
        p_gap: float = 0.82,
        t_yellow: float = 3.5,
        t_all_red: float = 2.0,
        t_lost: float = 2.0,
        headway_s: float = 2.0,
        g_min: float = 6.0
    ):
        self.params = ModelParameters(
            vehicle_slot_m=vehicle_length,
            safe_buffer_m=d_safe,
            maneuver_mu=mu_m,
            maneuver_sigma=sigma_m,
            willingness=c_base,
            gap_probability=p_gap,
            startup_lost_s=t_lost,
            saturation_headway_s=headway_s
        )
        self.t_yellow = t_yellow
        self.t_all_red = t_all_red
        self.g_min = g_min

    def compute_yielding_probabilities(
        self,
        N_init: int,
        x_ev: float,
        v_ev: float,
        x_stopline: float = 0.0,
        p_mobile: float = 0.85
    ) -> List[float]:
        if N_init <= 0 or v_ev <= 0.1 or x_ev >= x_stopline:
            return [0.0] * max(0, N_init)
        
        positions = queue_vehicle_positions(N_init, self.params.vehicle_slot_m)
        probs = []
        for x_i in positions:
            # Map stopline relative coordinates
            p = yielding_probability(
                ev_x_m=x_ev,
                vehicle_x_m=x_i,
                ev_speed_mps=v_ev,
                params=self.params,
                mobile_channel_available=(p_mobile > 0.0)
            )
            probs.append(p)
        return probs

    def compute_poisson_binomial_pmf(self, probs: List[float]) -> List[float]:
        return blocker_pmf(probs)

    def compute_critical_quantile(self, pmf: List[float], epsilon: float = 0.05) -> int:
        # Reconstruct pseudo yield probabilities from PMF or compute directly
        cdf = 0.0
        for n, mass in enumerate(pmf):
            cdf += mass
            if cdf + 1e-15 >= 1.0 - epsilon:
                return n
        return len(pmf) - 1

    def evaluate_preemption_decision(
        self,
        N_init: int,
        x_ev: float,
        v_ev: float,
        x_stopline: float = 0.0,
        p_mobile: float = 0.85,
        epsilon: float = 0.05,
        g_elapsed: float = 0.0
    ) -> Dict[str, Any]:
        d_stop = x_stopline - x_ev
        if d_stop <= 0 or v_ev <= 0.1:
            return {
                "x_ev": x_ev,
                "v_ev": v_ev,
                "eta": 0.0,
                "N_init": N_init,
                "N_crit": N_init,
                "T_clear": 0.0,
                "T_transition": 0.0,
                "T_lead": 0.0,
                "should_preempt": False,
                "yielding_probs": [0.0] * N_init,
                "pmf": [1.0]
            }

        t_min_green_remaining = max(0.0, self.g_min - g_elapsed)
        t_trans = t_min_green_remaining + self.t_yellow + self.t_all_red

        result = evaluate_approach(
            ev_distance_to_stopline_m=d_stop,
            ev_speed_mps=v_ev,
            queue_count=N_init,
            transition_s=t_trans,
            params=self.params,
            mobile_channel_available=(p_mobile > 0.0)
        )

        pmf = blocker_pmf(result["yield_probabilities"])

        return {
            "x_ev": x_ev,
            "v_ev": v_ev,
            "eta": result["eta_s"],
            "N_init": N_init,
            "N_crit": result["n_crit"],
            "T_clear": result["t_clear_s"],
            "T_transition": result["transition_s"],
            "T_lead": result["t_lead_s"],
            "should_preempt": result["preemption_due_in_model"],
            "yielding_probs": result["yield_probabilities"],
            "pmf": pmf
        }
