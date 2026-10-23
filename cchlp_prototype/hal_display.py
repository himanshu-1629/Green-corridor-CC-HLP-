"""
Hardware Abstraction Layer (HAL) for Mini Signal Display
Can run on Laptop (Console Mock) or Raspberry Pi (GPIO 3.3V).
"""
import sys
from .state_machine import SignalPhase

class SignalDisplayHAL:
    def __init__(self, mode: str = "AUTO", pin_ev_red=17, pin_ev_yellow=27, pin_ev_green=22, pin_cross_green=23):
        self.mode = mode
        self.pin_ev_red = pin_ev_red
        self.pin_ev_yellow = pin_ev_yellow
        self.pin_ev_green = pin_ev_green
        self.pin_cross_green = pin_cross_green
        self.gpio_available = False

        if mode == "AUTO" or mode == "GPIO":
            try:
                import RPi.GPIO as GPIO
                self.GPIO = GPIO
                self.GPIO.setmode(self.GPIO.BCM)
                self.GPIO.setup([self.pin_ev_red, self.pin_ev_yellow, self.pin_ev_green, self.pin_cross_green], self.GPIO.OUT)
                self.gpio_available = True
                print("[HAL] Initialized Raspberry Pi GPIO hardware mode.")
            except (ImportError, RuntimeError):
                self.gpio_available = False
                print("[HAL] RPi.GPIO not found. Falling back to High-Visibility Terminal MOCK mode.")

    def render_phase(self, phase: SignalPhase):
        """
        Renders the phase to physical LEDs or Console.
        """
        # Determine logical lamp states: (EV_RED, EV_YELLOW, EV_GREEN, CROSS_GREEN, CROSS_RED)
        if phase == SignalPhase.CROSS_GREEN:
            ev_r, ev_y, ev_g = True, False, False
            cr_r, cr_y, cr_g = False, False, True
        elif phase == SignalPhase.TRANSITION_YELLOW:
            ev_r, ev_y, ev_g = True, False, False
            cr_r, cr_y, cr_g = False, True, False
        elif phase == SignalPhase.TRANSITION_ALL_RED:
            ev_r, ev_y, ev_g = True, False, False
            cr_r, cr_y, cr_g = True, False, False
        elif phase == SignalPhase.PREEMPT_GREEN:
            ev_r, ev_y, ev_g = False, False, True
            cr_r, cr_y, cr_g = True, False, False
        elif phase == SignalPhase.POST_YELLOW:
            ev_r, ev_y, ev_g = False, True, False
            cr_r, cr_y, cr_g = True, False, False
        elif phase == SignalPhase.POST_ALL_RED:
            ev_r, ev_y, ev_g = True, False, False
            cr_r, cr_y, cr_g = True, False, False
        else:
            ev_r, ev_y, ev_g = True, False, False
            cr_r, cr_y, cr_g = True, False, False

        # Physical GPIO Actuation (Active LOW on relay boards)
        if self.gpio_available:
            self.GPIO.output(self.pin_ev_red, self.GPIO.LOW if ev_r else self.GPIO.HIGH)
            self.GPIO.output(self.pin_ev_yellow, self.GPIO.LOW if ev_y else self.GPIO.HIGH)
            self.GPIO.output(self.pin_ev_green, self.GPIO.LOW if ev_g else self.GPIO.HIGH)
            self.GPIO.output(self.pin_cross_green, self.GPIO.LOW if cr_g else self.GPIO.HIGH)

        # Terminal Visualization
        ev_str = f"[{'🔴' if ev_r else '⚪'} {'🟡' if ev_y else '⚪'} {'🟢' if ev_g else '⚪'}]"
        cr_str = f"[{'🔴' if cr_r else '⚪'} {'🟡' if cr_y else '⚪'} {'🟢' if cr_g else '⚪'}]"
        
        sys.stdout.write(f"\r🚦 PHASE: {phase.value:<20} | EV Approach: {ev_str} | Cross Street: {cr_str}")
        sys.stdout.flush()

    def cleanup(self):
        if self.gpio_available:
            self.GPIO.cleanup()
        print("\n[HAL] Cleaned up display.")
