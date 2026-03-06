# %% [markdown]
# # Reviewer #1 Comment #5: Time-series comparison (Baseline RBC vs MPC PH=20)
# This script:
# 1) Loads Baseline RBC (Dymola .mat) + MPC PH=20 (CSV)
# 2) Plots trajectories: input mode, TES SOC, zone temperatures (5 zones + average)
# 3) Computes metrics: energy (kWh), TOU cost ($), peak power (kW), unmet degree-hours (°C·h)
#
# Assumptions from manuscript:
# - Occupied indicator: occSch.occupied (0/1)
# - Comfort setpoint: conAHU.TZonCooSet (K)
# - Upper comfort bound during occupied: Tset + 1°C (i.e., +1 K)
# - Zone temps (K): conVAVCor.TZon, conVAVSou.TZon, conVAVEas.TZon, conVAVNor.TZon, conVAVWes.TZon
# - Operation mode: uModActual.y  (if missing in baseline mat, derived)
# - Plant power components (W): chi.P, priPum.P, secPum.P, fanSup.P
#
# TOU (from paper):
# - high: 13:00–18:59  @ 0.3548 $/kWh
# - mid : 09:00–12:59 and 19:00–22:59 @ 0.1391 $/kWh
# - low : 00:00–08:59 and 23:00–23:59 @ 0.0640 $/kWh

# %%
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple
import scipy.io

# %% [markdown]
# ## 0) File paths (EDIT if needed)

# %%
BASELINE_MAT = r"Baseline_RBC_Day243_244.mat"         # or full path
MPC_CSV      = r"results_measurements_PH20.csv"       # or full path

assert os.path.exists(BASELINE_MAT), f"Missing baseline mat: {BASELINE_MAT}"
assert os.path.exists(MPC_CSV),      f"Missing MPC csv: {MPC_CSV}"

OUT_DIR = "reviewer1_timeseries_outputs"
os.makedirs(OUT_DIR, exist_ok=True)

# %% [markdown]
# ## 1) Dymola .mat reader (no BuildingsPy required)

# %%
class DymolaMatReader:
    def __init__(self, mat_path: str):
        self.mat_path = mat_path
        self.mat = scipy.io.loadmat(mat_path, squeeze_me=True, struct_as_record=False)
        self._names = None
        self._name_to_idx = None

    @property
    def names(self) -> List[str]:
        if self._names is None:
            rows = self.mat["name"]
            n = len(rows[0])
            self._names = ["".join(r[i] for r in rows).strip() for i in range(n)]
        return self._names

    @property
    def name_to_idx(self) -> Dict[str, int]:
        if self._name_to_idx is None:
            self._name_to_idx = {n: i for i, n in enumerate(self.names)}
        return self._name_to_idx

    def resolve(self, var: str) -> str:
        if var in self.name_to_idx:
            return var
        lv = var.lower()

        for n in self.names:
            if n.lower() == lv:
                return n

        suffix = [n for n in self.names if n.endswith(var)]
        if len(suffix) == 1:
            return suffix[0]
        if len(suffix) > 1:
            return sorted(suffix, key=len)[0]

        contains = [n for n in self.names if lv in n.lower()]
        if contains:
            return sorted(contains, key=len)[0]

        raise KeyError(f"Variable '{var}' not found in {self.mat_path}")

    def get(self, var: str) -> np.ndarray:
        v = self.resolve(var)
        idx = self.name_to_idx[v]

        di = self.mat["dataInfo"][:, idx]  # 4 x nVar
        dataset = int(di[0])               # 1 -> data_1, 2 -> data_2
        row = int(di[1])                   # 1-based row index; negative means sign flip
        sign = 1
        if row < 0:
            sign = -1
            row = -row

        data = self.mat["data_1"] if dataset == 1 else self.mat["data_2"]
        return sign * data[row - 1, :]

    def time(self) -> np.ndarray:
        return self.mat["data_2"][0, :]

    def to_dataframe(self, vars_needed: List[str]) -> Tuple[pd.DataFrame, List[str]]:
        t = self.time()
        out = {"time": t}
        missing = []
        for v in vars_needed:
            try:
                out[v] = self.get(v)
            except KeyError:
                missing.append(v)
        return pd.DataFrame(out), missing

# %% [markdown]
# ## 2) Load datasets + preprocessing

# %%
ZONE_COLS = [
    "conVAVCor.TZon",
    "conVAVSou.TZon",
    "conVAVEas.TZon",
    "conVAVNor.TZon",
    "conVAVWes.TZon",
]
SETPOINT_COL = "conAHU.TZonCooSet"
OCC_COL = "occSch.occupied"
SOC_COL = "iceTan.SOC"
MODE_COL = "uModActual.y"

POWER_COLS = ["chi.P", "priPum.P", "secPum.P", "fanSup.P"]  # W

CHARGE_ACTIVE_COL = "iceTan.stoCon.charge.active"
DISCHARGE_ACTIVE_COL = "iceTan.stoCon.discharge.active"

baseline_reader = DymolaMatReader(BASELINE_MAT)
baseline_vars = [OCC_COL, SOC_COL, SETPOINT_COL, MODE_COL] + ZONE_COLS + POWER_COLS + [CHARGE_ACTIVE_COL, DISCHARGE_ACTIVE_COL]
baseline_df, baseline_missing = baseline_reader.to_dataframe(baseline_vars)

mpc_df = pd.read_csv(MPC_CSV)

print("Baseline missing variables:", baseline_missing)

# %%
def add_time_columns(df: pd.DataFrame, t0: float) -> pd.DataFrame:
    df = df.copy()
    df["t_rel_s"] = df["time"] - t0
    df["t_rel_hr"] = df["t_rel_s"] / 3600.0
    df["tod_hr"] = (df["time"] / 3600.0) % 24.0
    df["day_of_year"] = np.floor(df["time"] / 86400.0).astype(int)
    return df

t0 = min(baseline_df["time"].min(), mpc_df["time"].min())
baseline_df = add_time_columns(baseline_df, t0)
mpc_df = add_time_columns(mpc_df, t0)

# %%
def ensure_mode_column(df: pd.DataFrame, label: str) -> pd.DataFrame:
    df = df.copy()

    if MODE_COL in df.columns and df[MODE_COL].notna().any():
        df["u_mode_plot"] = np.round(df[MODE_COL].astype(float)).astype(int)
        return df

    if CHARGE_ACTIVE_COL in df.columns and DISCHARGE_ACTIVE_COL in df.columns:
        ch = df[CHARGE_ACTIVE_COL].fillna(0).values
        dis = df[DISCHARGE_ACTIVE_COL].fillna(0).values
        u = np.zeros(len(df), dtype=int)
        u[ch > 0.5] = -1
        u[dis > 0.5] = 1
        df["u_mode_plot"] = u
        return df

    if SOC_COL in df.columns:
        soc = df[SOC_COL].values
        ds = np.gradient(soc, df["t_rel_hr"].values)
        u = np.zeros(len(df), dtype=int)
        u[ds > 1e-4] = -1
        u[ds < -1e-4] = 1
        df["u_mode_plot"] = u
        return df

    raise ValueError(f"[{label}] Cannot determine operation mode (no {MODE_COL}, no active flags, no SOC).")

baseline_df = ensure_mode_column(baseline_df, "Baseline")
mpc_df = ensure_mode_column(mpc_df, "MPC")

# %%
def compute_total_power(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    missing = [c for c in POWER_COLS if c not in df.columns]
    if missing:
        raise KeyError(f"Missing power columns: {missing}")
    df["P_total_W"] = df[POWER_COLS].sum(axis=1)
    df["P_total_kW"] = df["P_total_W"] / 1000.0
    return df

baseline_df = compute_total_power(baseline_df)
mpc_df = compute_total_power(mpc_df)

# %%
def to_celsius(K: pd.Series) -> pd.Series:
    return K - 273.15

for z in ZONE_COLS:
    baseline_df[z + "_C"] = to_celsius(baseline_df[z])
    mpc_df[z + "_C"] = to_celsius(mpc_df[z])

baseline_df["Tset_C"] = to_celsius(baseline_df[SETPOINT_COL])
mpc_df["Tset_C"] = to_celsius(mpc_df[SETPOINT_COL])

baseline_df["Tavg_C"] = baseline_df[[z + "_C" for z in ZONE_COLS]].mean(axis=1)
mpc_df["Tavg_C"] = mpc_df[[z + "_C" for z in ZONE_COLS]].mean(axis=1)

baseline_df["Tmax_C"] = baseline_df[[z + "_C" for z in ZONE_COLS]].max(axis=1)
mpc_df["Tmax_C"] = mpc_df[[z + "_C" for z in ZONE_COLS]].max(axis=1)

baseline_df["occ"] = (baseline_df[OCC_COL] > 0.5).astype(int)
mpc_df["occ"] = (mpc_df[OCC_COL] > 0.5).astype(int)

# %% [markdown]
# ## 3) TOU pricing + metrics

# %%
TOU_HIGH = 0.3548
TOU_MID  = 0.1391
TOU_LOW  = 0.0640

def tou_rate(tod_hr: np.ndarray) -> np.ndarray:
    r = np.full_like(tod_hr, TOU_LOW, dtype=float)
    r[(tod_hr >= 13) & (tod_hr < 19)] = TOU_HIGH
    r[((tod_hr >= 9) & (tod_hr < 13)) | ((tod_hr >= 19) & (tod_hr < 23))] = TOU_MID
    return r

baseline_df["price"] = tou_rate(baseline_df["tod_hr"].values)
mpc_df["price"] = tou_rate(mpc_df["tod_hr"].values)

def integrate_trapz(y: np.ndarray, x: np.ndarray) -> float:
    return float(np.trapz(y, x))

def compute_metrics(df: pd.DataFrame, label: str) -> Dict[str, float]:
    t_hr = df["t_rel_hr"].values
    P_kW = df["P_total_kW"].values
    price = df["price"].values

    E_kWh = integrate_trapz(P_kW, t_hr)
    # NOTE: "$" is not allowed in Python identifiers; keep the "$" only in labels.
    cost_dollar = integrate_trapz(P_kW * price, t_hr)
    peak_kW = float(np.max(P_kW))

    upper_C = df["Tset_C"].values + 1.0
    occ = df["occ"].values.astype(bool)

    udh_per_zone = {}
    frac_violate_per_zone = {}
    max_violation_C = 0.0

    for z in ZONE_COLS:
        T = df[z + "_C"].values
        viol = np.maximum(T - upper_C, 0.0)
        viol_occ = np.where(occ, viol, 0.0)
        udh = integrate_trapz(viol_occ, t_hr)
        udh_per_zone[z] = udh

        occ_count = np.sum(occ)
        frac = float(np.sum((viol > 0) & occ) / occ_count) if occ_count > 0 else 0.0
        frac_violate_per_zone[z] = frac

        max_violation_C = max(max_violation_C, float(np.max(viol_occ)))

    udh_avg = float(np.mean(list(udh_per_zone.values())))
    udh_sum = float(np.sum(list(udh_per_zone.values())))
    frac_violate_avg = float(np.mean(list(frac_violate_per_zone.values())))

    return {
        "case": label,
        "Energy_kWh": E_kWh,
        "Cost_$": cost_dollar,
        "PeakPower_kW": peak_kW,
        "UDH_avg_C_h": udh_avg,
        "UDH_sum_C_h": udh_sum,
        "OccFracViolation_avg": frac_violate_avg,
        "MaxOccViolation_C": max_violation_C,
    }

metrics_baseline = compute_metrics(baseline_df, "Baseline_RBC")
metrics_mpc      = compute_metrics(mpc_df, "MPC_PH20")

summary = pd.DataFrame([metrics_baseline, metrics_mpc])
summary["CostSaving_%"] = 100 * (summary.loc[0, "Cost_$"] - summary["Cost_$"]) / summary.loc[0, "Cost_$"]
summary["EnergySaving_%"] = 100 * (summary.loc[0, "Energy_kWh"] - summary["Energy_kWh"]) / summary.loc[0, "Energy_kWh"]

summary.to_csv(os.path.join(OUT_DIR, "summary_metrics_baseline_vs_mpc.csv"), index=False)
print("Saved metrics CSV:", os.path.join(OUT_DIR, "summary_metrics_baseline_vs_mpc.csv"))
print(summary)

# %% [markdown]
# ## 4) Plots (mode, SOC, temperatures, total power)

# %%
# def shade_occupied(ax, t_hr, occ, label=None):
#     occ = occ.astype(int)
#     in_occ = False
#     start = None
#     for i in range(len(t_hr)):
#         if occ[i] == 1 and not in_occ:
#             in_occ = True
#             start = t_hr[i]
#         if in_occ and (occ[i] == 0 or i == len(t_hr)-1):
#             end = t_hr[i] if occ[i] == 0 else t_hr[i]
#             ax.axvspan(start, end, alpha=0.15)
#             in_occ = False
            
def shade_occupied(ax, t_hr, occ, label=None):
    occ = occ.astype(int)
    in_occ = False
    start = None
    label_added = False  # To ensure the label is added only once
    for i in range(len(t_hr)):
        if occ[i] == 1 and not in_occ:
            in_occ = True
            start = t_hr[i]
        if in_occ and (occ[i] == 0 or i == len(t_hr)-1):
            end = t_hr[i] if occ[i] == 0 else t_hr[i]
            ax.axvspan(start, end, alpha=0.15, label=label if not label_added else None)
            label_added = True
            in_occ = False

def downsample_for_plot(df, step_seconds=300):
    """Downsample to a regular grid for plotting.

    Uses mean+interpolation for continuous signals and nearest for discrete signals.
    Handles duplicate timestamps (common in some simulation/CSV exports).
    """
    df = df.copy()
    td = pd.to_timedelta(df["t_rel_s"], unit="s")
    df = df.set_index(td).sort_index()

    # Pandas' resample(...).nearest() requires a *unique* index.
    if not df.index.is_unique:
        discrete_cols = [c for c in ["u_mode_plot", "occ"] if c in df.columns]
        cont_cols = [c for c in df.columns if c not in discrete_cols]
        df_cont = df[cont_cols].groupby(level=0).mean() if cont_cols else pd.DataFrame(index=df.index.unique())
        df_disc = df[discrete_cols].groupby(level=0).last() if discrete_cols else None
        df = df_cont.join(df_disc, how="left") if df_disc is not None else df_cont
        df = df.sort_index()

    rule = f"{step_seconds}S"
    discrete_cols = [c for c in ["u_mode_plot", "occ"] if c in df.columns]
    cont_cols = [c for c in df.columns if c not in discrete_cols]

    # Continuous signals
    if cont_cols:
        df_reg = df[cont_cols].resample(rule).mean().interpolate()
    else:
        df_reg = pd.DataFrame(index=pd.timedelta_range(start=df.index.min(), end=df.index.max(), freq=rule))

    # Discrete signals
    for c in discrete_cols:
        df_reg[c] = df[c].resample(rule).nearest().astype(int)

    df_reg["t_rel_s"] = df_reg.index.total_seconds()
    df_reg["t_rel_hr"] = df_reg["t_rel_s"] / 3600.0
    return df_reg.reset_index(drop=True)

baseline_p = downsample_for_plot(baseline_df, step_seconds=300)
mpc_p      = downsample_for_plot(mpc_df, step_seconds=300)

# Figure A: operation mode
fig, ax = plt.subplots(figsize=(10, 3))
ax.step(baseline_p["t_rel_hr"], baseline_p["u_mode_plot"], where="post", label="Baseline (RBC)")
ax.step(mpc_p["t_rel_hr"], mpc_p["u_mode_plot"], where="post", label="MPC (PH=20)")
shade_occupied(ax, baseline_p["t_rel_hr"].values, baseline_p["occ"].values, label="Occupied") 
ax.set_ylim(-1.1,2.1) # I also need to set y unit intervals to make the step plot look right (mode is discrete)
ax.set_yticks([-1, 0, 1, 2])
ax.set_xlabel("Time (hours from start)")
ax.set_ylabel("Operation mode")
ax.set_title("Operation mode = -1 (Charge TES); 0 (Off); 1 (Discharge TES only); 2 (Operate chiller only)")
ax.legend(loc="upper left")
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "FigA_mode_baseline_vs_mpc.png"), dpi=300)

# Figure B: SOC
fig, ax = plt.subplots(figsize=(10, 3))
ax.plot(baseline_p["t_rel_hr"], baseline_p[SOC_COL], label="Baseline (RBC)")
ax.plot(mpc_p["t_rel_hr"], mpc_p[SOC_COL], label="MPC (PH=20)")
shade_occupied(ax, baseline_p["t_rel_hr"].values, baseline_p["occ"].values)
ax.axhline(0.20, linestyle="--")
ax.axhline(0.99, linestyle="--")
ax.set_xlabel("Time (hours from start)")
ax.set_ylabel("TES SOC")
ax.set_title("TES state-of-charge trajectory")
ax.legend(loc="upper left")
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "FigB_SOC_baseline_vs_mpc.png"), dpi=300)

# Figure C: avg and max temps
fig, axs = plt.subplots(2, 1, figsize=(10, 6), sharex=True)

axs[0].plot(baseline_p["t_rel_hr"], baseline_p["Tavg_C"], label="Baseline avg")
axs[0].plot(mpc_p["t_rel_hr"], mpc_p["Tavg_C"], label="MPC avg")
axs[0].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"], linestyle="--", label="Setpoint")
axs[0].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"] + 1.0, linestyle="--", label="Upper bound (Tset+1°C)")
shade_occupied(axs[0], baseline_p["t_rel_hr"].values, baseline_p["occ"].values)
axs[0].set_ylabel("Temperature (°C)")
axs[0].set_title("Indoor temperature (average across 5 zones)")
axs[0].legend()

axs[1].plot(baseline_p["t_rel_hr"], baseline_p["Tmax_C"], label="Baseline max")
axs[1].plot(mpc_p["t_rel_hr"], mpc_p["Tmax_C"], label="MPC max")
axs[1].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"], linestyle="--", label="Setpoint")
axs[1].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"] + 1.0, linestyle="--", label="Upper bound (Tset+1°C)")
shade_occupied(axs[1], baseline_p["t_rel_hr"].values, baseline_p["occ"].values)
axs[1].set_xlabel("Time (hours from start)")
axs[1].set_ylabel("Temperature (°C)")
axs[1].set_title("Indoor temperature (maximum across 5 zones)")
axs[1].legend()

fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "FigC_zoneTemp_avg_max_baseline_vs_mpc.png"), dpi=300)

# Figure D: 5 zone temps
fig, axs = plt.subplots(5, 1, figsize=(10, 10), sharex=True)

for i, z in enumerate(ZONE_COLS):
    zc = z + "_C"
    axs[i].plot(baseline_p["t_rel_hr"], baseline_p[zc], label="Baseline")
    axs[i].plot(mpc_p["t_rel_hr"], mpc_p[zc], label="MPC")
    axs[i].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"], linestyle="--", label="Setpoint" if i == 0 else None)
    axs[i].plot(baseline_p["t_rel_hr"], baseline_p["Tset_C"] + 1.0, linestyle="--", label="Upper bound" if i == 0 else None)
    shade_occupied(axs[i], baseline_p["t_rel_hr"].values, baseline_p["occ"].values)
    axs[i].set_ylabel("°C")
    axs[i].set_title(z.replace(".TZon", ""))

axs[-1].set_xlabel("Time (hours from start)")
axs[0].legend()
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "FigD_zoneTemps_5zones_baseline_vs_mpc.png"), dpi=300)

# Figure E: total power
fig, ax = plt.subplots(figsize=(10, 3))
ax.plot(baseline_p["t_rel_hr"], baseline_p["P_total_kW"], label="Baseline total power")
ax.plot(mpc_p["t_rel_hr"], mpc_p["P_total_kW"], label="MPC total power")
shade_occupied(ax, baseline_p["t_rel_hr"].values, baseline_p["occ"].values)
ax.set_xlabel("Time (hours from start)")
ax.set_ylabel("Total power (kW)")
ax.set_title("Total plant power trajectory")
ax.legend()
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "FigE_totalPower_baseline_vs_mpc.png"), dpi=300)

print("Done. Outputs saved in:", OUT_DIR)
