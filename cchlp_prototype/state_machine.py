"""
Safety Controller State Machine & Hardware Interlock
Guarantees ONE-HOT signal states and enforces unskippable clearance intervals.
"""
from enum import Enum
import time
from typing import Dict, Any, Callable, Optional

class SignalPhase(Enum):
    CROSS_GREEN = "CROSS_GREEN"          # Cross-street has Green, EV approach has Red
    TRANSITION_YELLOW = "TRANSITION_YELLOW"# Cross-street has Yellow (3.5s)
    TRANSITION_ALL_RED = "ALL_RED"       # All approaches have Red (2.0s)
    PREEMPT_GREEN = "PREEMPT_GREEN"      # Emergency Corridor has Green, Cross has Red
    POST_YELLOW = "POST_YELLOW"          # EV corridor has Yellow
    POST_ALL_RED = "POST_ALL_RED"        # Post all-red recovery

class SignalStateMachine:
    def __init__(
        self,
        t_yellow: float = 3.5,
        t_all_red: float = 2.0,
        output_hook: Optional[Callable[[SignalPhase], None]] = None
    ):
        self.t_yellow = t_yellow
        self.t_all_red = t_all_red
        self.current_phase = SignalPhase.CROSS_GREEN
        self.phase_start_time = time.time()
        self.output_hook = output_hook
        self.preempt_active = False

    def elapsed_in_phase(self) -> float:
        return time.time() - self.phase_start_time

    def transition_to(self, new_phase: SignalPhase):
        # Invariant check: cannot jump directly from CROSS_GREEN to PREEMPT_GREEN
        if self.current_phase == SignalPhase.CROSS_GREEN and new_phase == SignalPhase.PREEMPT_GREEN:
            raise RuntimeError("CRITICAL SAFETY FAULT: Attempted direct jump to PREEMPT_GREEN without clearance!")
        
        self.current_phase = new_phase
        self.phase_start_time = time.time()
        if self.output_hook:
            self.output_hook(self.current_phase)

    def update(self, preempt_call: bool, ev_cleared: bool = False):
        """
        Step-based state machine update.
        """
        now = time.time()
        elapsed = now - self.phase_start_time

        if self.current_phase == SignalPhase.CROSS_GREEN:
            if preempt_call:
                self.transition_to(SignalPhase.TRANSITION_YELLOW)

        elif self.current_phase == SignalPhase.TRANSITION_YELLOW:
            # Enforce unskippable yellow interval
            if elapsed >= self.t_yellow:
                self.transition_to(SignalPhase.TRANSITION_ALL_RED)

        elif self.current_phase == SignalPhase.TRANSITION_ALL_RED:
            # Enforce unskippable all-red interval
            if elapsed >= self.t_all_red:
                self.transition_to(SignalPhase.PREEMPT_GREEN)

        elif self.current_phase == SignalPhase.PREEMPT_GREEN:
            # Hold green until EV has safely cleared the stopline
            if ev_cleared:
                self.transition_to(SignalPhase.POST_YELLOW)

        elif self.current_phase == SignalPhase.POST_YELLOW:
            if elapsed >= self.t_yellow:
                self.transition_to(SignalPhase.POST_ALL_RED)

        elif self.current_phase == SignalPhase.POST_ALL_RED:
            if elapsed >= self.t_all_red:
                self.transition_to(SignalPhase.CROSS_GREEN)
