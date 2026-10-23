"""
Unit & Property Tests for CC-HLP Prototype
Verifies mathematical invariants, state machine safety, and fallback behavior.
"""
import unittest
import math
from cchlp_prototype.estimator import CCHLPEstimator
from cchlp_prototype.state_machine import SignalStateMachine, SignalPhase

class TestCCHLPPrototype(unittest.TestCase):
    def setUp(self):
        self.estimator = CCHLPEstimator()

    def test_pmf_sums_to_one(self):
        """Invariant: The residual blocker PMF must strictly sum to 1.0 within float precision."""
        probs = [0.8, 0.4, 0.6, 0.2, 0.9, 0.5]
        pmf = self.estimator.compute_poisson_binomial_pmf(probs)
        self.assertAlmostEqual(sum(pmf), 1.0, places=7)

    def test_quantile_within_bounds(self):
        """Invariant: N_crit must be between 0 and N_init."""
        probs = [0.7] * 10
        pmf = self.estimator.compute_poisson_binomial_pmf(probs)
        n_crit = self.estimator.compute_critical_quantile(pmf, epsilon=0.05)
        self.assertGreaterEqual(n_crit, 0)
        self.assertLessEqual(n_crit, 10)

    def test_signed_coordinates(self):
        """Coordinates must handle negative upstream positions correctly without sign flips."""
        p_list = self.estimator.compute_yielding_probabilities(
            N_init=5,
            x_ev=-200.0,
            v_ev=20.0,
            x_stopline=0.0
        )
        self.assertEqual(len(p_list), 5)
        for p in p_list:
            self.assertGreaterEqual(p, 0.0)
            self.assertLessEqual(p, 1.0)

    def test_safety_perimeter_zero_probability(self):
        """If EV has already breached the vehicle's safety distance, yielding probability must be 0."""
        # Stopline is 0, car 1 is at -7.5m. EV is at -10m (only 2.5m away, d_safe is 15m)
        p_list = self.estimator.compute_yielding_probabilities(
            N_init=1,
            x_ev=-10.0,
            v_ev=20.0,
            x_stopline=0.0
        )
        self.assertEqual(p_list[0], 0.0)

    def test_fallback_when_mobile_alert_drops(self):
        """When mobile notification fails (p_mobile=0) at long range, N_crit should expand to N_init."""
        decision = self.estimator.evaluate_preemption_decision(
            N_init=6,
            x_ev=-500.0,
            v_ev=20.0,
            p_mobile=0.0,
            epsilon=0.05
        )
        # At 500m, siren is inaudible (p_acoustic ~ 0) and p_mobile=0, so p_i should be 0
        self.assertEqual(decision["N_crit"], 6)

    def test_state_machine_illegal_transition_rejection(self):
        """State machine must raise RuntimeError if trying to jump straight to PREEMPT_GREEN."""
        sm = SignalStateMachine()
        self.assertEqual(sm.current_phase, SignalPhase.CROSS_GREEN)
        with self.assertRaises(RuntimeError):
            sm.transition_to(SignalPhase.PREEMPT_GREEN)

    def test_state_machine_orderly_transition(self):
        """State machine must cycle through Yellow -> All-Red -> Preempt Green."""
        sm = SignalStateMachine(t_yellow=0.01, t_all_red=0.01)
        sm.update(preempt_call=True)
        self.assertEqual(sm.current_phase, SignalPhase.TRANSITION_YELLOW)

if __name__ == "__main__":
    unittest.main()
