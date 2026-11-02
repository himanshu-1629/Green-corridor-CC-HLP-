#!/usr/bin/env python3
"""
STEP 5: Neural Weight Exporter
Exports PyTorch weights and scaler parameters to a unified JSON format
for real-time client-side matrix multiplication in the 3D Digital Twin.
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

def export_model_json():
    dir_path = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(dir_path, "driver_yielding_model.pth")
    scaler_path = os.path.join(dir_path, "scaler_params.json")
    out_json = os.path.join(dir_path, "model_weights.json")

    # 1. Load Scaler
    with open(scaler_path, 'r') as f:
        scaler = json.load(f)

    # 2. Load Model
    model = DriverYieldingMLP(input_dim=8)
    model.load_state_dict(torch.load(model_path, weights_only=True))
    model.eval()

    state = model.state_dict()

    # 3. Extract Folded Weights & Biases (Linear + BatchNorm folded for ultra-fast inference)
    # Layer 1: Linear net.0 (8 -> 64), BatchNorm net.1
    w1 = state['net.0.weight'].cpu().numpy()  # (64, 8)
    b1 = state['net.0.bias'].cpu().numpy()    # (64,)
    bn1_w = state['net.1.weight'].cpu().numpy()
    bn1_b = state['net.1.bias'].cpu().numpy()
    bn1_m = state['net.1.running_mean'].cpu().numpy()
    bn1_v = state['net.1.running_var'].cpu().numpy()
    scale1 = bn1_w / np.sqrt(bn1_v + 1e-5)
    w1_folded = (w1.T * scale1).T
    b1_folded = (b1 - bn1_m) * scale1 + bn1_b

    # Layer 2: Linear net.4 (64 -> 32), BatchNorm net.5
    w2 = state['net.4.weight'].cpu().numpy()  # (32, 64)
    b2 = state['net.4.bias'].cpu().numpy()
    bn2_w = state['net.5.weight'].cpu().numpy()
    bn2_b = state['net.5.bias'].cpu().numpy()
    bn2_m = state['net.5.running_mean'].cpu().numpy()
    bn2_v = state['net.5.running_var'].cpu().numpy()
    scale2 = bn2_w / np.sqrt(bn2_v + 1e-5)
    w2_folded = (w2.T * scale2).T
    b2_folded = (b2 - bn2_m) * scale2 + bn2_b

    # Layer 3: Linear net.7 (32 -> 16)
    w3 = state['net.7.weight'].cpu().numpy()  # (16, 32)
    b3 = state['net.7.bias'].cpu().numpy()

    # Layer 4: Linear net.9 (16 -> 1)
    w4 = state['net.9.weight'].cpu().numpy()  # (1, 16)
    b4 = state['net.9.bias'].cpu().numpy()

    export_payload = {
        "architecture": "MLP_8_64_32_16_1",
        "feature_cols": scaler['feature_cols'],
        "scaler_means": scaler['means'],
        "scaler_stds": scaler['stds'],
        "weights": {
            "w1": np.round(w1_folded, 6).tolist(),
            "b1": np.round(b1_folded, 6).tolist(),
            "w2": np.round(w2_folded, 6).tolist(),
            "b2": np.round(b2_folded, 6).tolist(),
            "w3": np.round(w3, 6).tolist(),
            "b3": np.round(b3, 6).tolist(),
            "w4": np.round(w4, 6).tolist(),
            "b4": np.round(b4, 6).tolist(),
        }
    }

    with open(out_json, 'w') as f:
        json.dump(export_payload, f, indent=2)

    print(f"✓ Model weights successfully exported to: {out_json}")
    print(f"  • W1 dimensions: {w1_folded.shape}")
    print(f"  • W2 dimensions: {w2_folded.shape}")
    print(f"  • W3 dimensions: {w3.shape}")
    print(f"  • W4 dimensions: {w4.shape}")
    print("Ready for live client-side neural execution!")

if __name__ == '__main__':
    export_model_json()
