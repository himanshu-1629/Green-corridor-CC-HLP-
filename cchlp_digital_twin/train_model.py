#!/usr/bin/env python3
"""
STEP 2: PyTorch Model Definition and Training Pipeline
Trains a Deep Multi-Layer Perceptron (MLP) to predict individual driver
yielding probabilities (p_i) for the CC-HLP chance-constrained engine.
"""

import os
import json
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import TensorDataset, DataLoader

# Set reproducibility seeds
torch.manual_seed(42)
np.random.seed(42)

# =========================================================================
# 1. NEURAL NETWORK ARCHITECTURE
# =========================================================================
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

# =========================================================================
# 2. EVALUATION METRICS
# =========================================================================
def calculate_metrics(y_true, y_prob, threshold=0.5):
    y_pred = (y_prob >= threshold).astype(int)
    
    tp = np.sum((y_pred == 1) & (y_true == 1))
    fp = np.sum((y_pred == 1) & (y_true == 0))
    tn = np.sum((y_pred == 0) & (y_true == 0))
    fn = np.sum((y_pred == 0) & (y_true == 1))
    
    acc = (tp + tn) / max(1, len(y_true))
    prec = tp / max(1, (tp + fp))
    rec = tp / max(1, (tp + fn))
    f1 = 2 * (prec * rec) / max(1e-6, (prec + rec))
    
    # Fast Trapezoidal AUC calculation
    desc_idx = np.argsort(-y_prob)
    y_sorted = y_true[desc_idx]
    n_pos = np.sum(y_sorted == 1)
    n_neg = len(y_sorted) - n_pos
    if n_pos == 0 or n_neg == 0:
        auc = 0.5
    else:
        rank = np.where(y_sorted == 1)[0]
        auc = (np.sum(rank) - n_pos * (n_pos - 1) / 2) / (n_pos * n_neg)
        auc = 1.0 - auc  # Align with true-positive order
        
    return acc, prec, rec, f1, auc

# =========================================================================
# 3. DATA PREPARATION & TRAINING LOOP
# =========================================================================
def train():
    dir_path = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(dir_path, "driver_yielding_dataset.csv")

    if not os.path.exists(csv_path):
        raise FileNotFoundError("Missing dataset! Run generate_dataset.py first.")

    print(f"Loading dataset from: {csv_path}")
    df = pd.read_csv(csv_path)

    feature_cols = [
        'dist_to_ev_m', 'ev_speed_ms', 'time_deadline_s', 'queue_rank_norm',
        'adjacent_gap_m', 'has_app_alert', 'driver_trait', 'siren_loudness_db'
    ]
    target_col = 'yielded_label'

    X = df[feature_cols].values.astype(np.float32)
    y = df[target_col].values.astype(np.float32).reshape(-1, 1)

    # 80/20 Train/Test Shuffle Split
    n_samples = len(X)
    indices = np.random.permutation(n_samples)
    split_idx = int(n_samples * 0.8)

    train_idx, test_idx = indices[:split_idx], indices[split_idx:]
    X_train, y_train = X[train_idx], y[train_idx]
    X_test, y_test = X[test_idx], y[test_idx]

    # Z-score standardization based strictly on training set statistics
    means = np.mean(X_train, axis=0)
    stds = np.std(X_train, axis=0) + 1e-7

    X_train_norm = (X_train - means) / stds
    X_test_norm = (X_test - means) / stds

    # Save normalization parameters for live inference
    scaler_dict = {
        'feature_cols': feature_cols,
        'means': means.tolist(),
        'stds': stds.tolist()
    }
    with open(os.path.join(dir_path, 'scaler_params.json'), 'w') as f:
        json.dump(scaler_dict, f, indent=2)
    print("Feature normalization parameters saved to scaler_params.json")

    # PyTorch DataLoaders
    train_dataset = TensorDataset(torch.from_numpy(X_train_norm), torch.from_numpy(y_train))
    test_dataset = TensorDataset(torch.from_numpy(X_test_norm), torch.from_numpy(y_test))

    train_loader = DataLoader(train_dataset, batch_size=128, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=512, shuffle=False)

    # Instantiate Model, Loss, Optimizer
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Training on device: {device}")

    model = DriverYieldingMLP(input_dim=8).to(device)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.002, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=8, gamma=0.5)

    epochs = 20
    print(f"\nBeginning training for {epochs} epochs...")
    print("-" * 72)
    print(f"{'Epoch':<8}{'Train Loss':<14}{'Test Loss':<14}{'Test Acc':<12}{'Precision':<12}{'Recall':<10}{'AUC-ROC'}")
    print("-" * 72)

    for epoch in range(1, epochs + 1):
        # Training Phase
        model.train()
        total_train_loss = 0.0
        for batch_x, batch_y in train_loader:
            batch_x, batch_y = batch_x.to(device), batch_y.to(device)
            optimizer.zero_grad()
            preds = model(batch_x)
            loss = criterion(preds, batch_y)
            loss.backward()
            optimizer.step()
            total_train_loss += loss.item() * len(batch_x)

        avg_train_loss = total_train_loss / len(train_dataset)
        scheduler.step()

        # Validation Phase
        model.eval()
        total_test_loss = 0.0
        all_preds = []
        all_targets = []
        with torch.no_grad():
            for batch_x, batch_y in test_loader:
                batch_x, batch_y = batch_x.to(device), batch_y.to(device)
                preds = model(batch_x)
                loss = criterion(preds, batch_y)
                total_test_loss += loss.item() * len(batch_x)
                all_preds.append(preds.cpu().numpy())
                all_targets.append(batch_y.cpu().numpy())

        avg_test_loss = total_test_loss / len(test_dataset)
        y_pred_arr = np.vstack(all_preds).flatten()
        y_true_arr = np.vstack(all_targets).flatten()

        acc, prec, rec, f1, auc = calculate_metrics(y_true_arr, y_pred_arr)

        if epoch % 2 == 0 or epoch == 1 or epoch == epochs:
            print(f"{epoch:<8}{avg_train_loss:<14.4f}{avg_test_loss:<14.4f}{acc*100:<11.2f}%{prec*100:<11.2f}%{rec*100:<9.2f}%{auc:.4f}")

    print("-" * 72)

    # Save Model Weights
    weights_path = os.path.join(dir_path, "driver_yielding_model.pth")
    torch.save(model.state_dict(), weights_path)
    print(f"\nModel training complete! Weights saved to: {weights_path}")
    print(f"Final Test Accuracy : {acc * 100:.2f}%")
    print(f"Final Test AUC-ROC  : {auc:.4f}")
    print(f"Final Test F1-Score : {f1:.4f}")

if __name__ == '__main__':
    train()
