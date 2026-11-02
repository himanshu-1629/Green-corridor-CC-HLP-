#!/usr/bin/env python3
"""
STEP 3: Model Inference Verification Test
Loads the trained weights and tests the AI model on 5 distinct real-world
driver scenarios to verify that the neural network 'thinks' realistically.
"""

import os
import json
import torch
import torch.nn as nn
import numpy as np

# Re-declare identical MLP architecture
class DriverYieldingMLP(nn.Module):
    def __init__(self, input_dim=8):
        super(DriverYieldingMLP, self).__init__()
        self.net = nn.Sequential(
            nn.Linear(input_dim, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.15),
            
            nn.Linear(64, 32),
            nn.BatchNorm1d(32),
            nn.ReLU(),
            
            nn.Linear(32, 16),
            nn.ReLU(),
            
            nn.Linear(16, 1),
            nn.Sigmoid()
        )

    def forward(self, x):
        return self.net(x)

def run_test():
    dir_path = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(dir_path, "driver_yielding_model.pth")
    scaler_path = os.path.join(dir_path, "scaler_params.json")

    if not os.path.exists(model_path) or not os.path.exists(scaler_path):
        raise FileNotFoundError("Missing trained model weights or scaler! Run train_model.py first.")

    # 1. Load Scaler
    with open(scaler_path, 'r') as f:
        scaler = json.load(f)
    means = np.array(scaler['means'], dtype=np.float32)
    stds = np.array(scaler['stds'], dtype=np.float32)

    # 2. Load Model Weights
    model = DriverYieldingMLP(input_dim=8)
    model.load_state_dict(torch.load(model_path, weights_only=True))
    model.eval()
    print("✓ Model weights loaded successfully into memory.\n")

    # 3. Five Distinct Real-World Test Drivers
    test_cases = [
        {
            "name": "Driver #1: Connected & Clear Adjacent Lane",
            "desc": "App alert received, 14.5s deadline, large 9.2m lane gap",
            "features": [290.0, 20.0, 14.5, 0.40, 9.2, 1.0, 0.35, 62.0]
        },
        {
            "name": "Driver #2: Connected but Trapped in Heavy Traffic",
            "desc": "App alert received, but adjacent lane jammed (2.1m gap)",
            "features": [240.0, 20.0, 12.0, 0.30, 2.1, 1.0, 0.40, 64.0]
        },
        {
            "name": "Driver #3: Unalerted Driver (Siren Only, Far Away)",
            "desc": "No app alert, distant from siren (280m, only 61 dB)",
            "features": [280.0, 20.0, 14.0, 0.70, 7.5, 0.0, 0.50, 61.0]
        },
        {
            "name": "Driver #4: Front of Queue Panic (Tight Deadline)",
            "desc": "Stopline car #1, EV is close (70m, only 3.5s deadline left)",
            "features": [70.0, 20.0, 3.5, 0.05, 5.0, 1.0, 0.30, 73.0]
        },
        {
            "name": "Driver #5: Fast Cooperative Commuter",
            "desc": "Alert received, agile reaction trait, wide shoulder available (12m)",
            "features": [200.0, 20.0, 10.0, 0.50, 12.0, 1.0, 0.20, 65.0]
        }
    ]

    print("=" * 80)
    print(f"{'DRIVER SCENARIO':<46}{'PREDICTED p_i':<18}{'AI DECISION'}")
    print("=" * 80)

    for tc in test_cases:
        feat_raw = np.array([tc["features"]], dtype=np.float32)
        feat_norm = (feat_raw - means) / stds
        
        with torch.no_grad():
            prob = model(torch.from_numpy(feat_norm)).item()

        pct = prob * 100.0
        if prob >= 0.75:
            decision = f"HIGH YIELD ({pct:.1f}%) -> Lane Cleared"
        elif prob >= 0.45:
            decision = f"MODERATE ({pct:.1f}%) -> Uncertain / Delay"
        else:
            decision = f"BLOCKER ({pct:.1f}%) -> Remains in Lane"

        print(f"{tc['name']:<46}{prob:<18.4f}{decision}")
        print(f"   ↳ {tc['desc']}")
        print("-" * 80)

if __name__ == '__main__':
    run_test()
