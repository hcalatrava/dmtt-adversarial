# Label Hijacking in Track Consensus-Based Distributed Multi-Target Tracking

Code for the paper:

> H. Calatrava, S. Tang, P. Closas, "Label Hijacking in Track Consensus-Based Distributed Multi-Target Tracking," Under Review.

[[arXiv]](https://arxiv.org/abs/2603.05023) [[Code]](https://github.com/hcalatrava/dmtt-adversarial)

---

## Important: Relationship to Van Nguyen et al.

This repository builds directly on the TC-DMTT framework of:

> H. Van Nguyen, H. Rezatofighi, B.-N. Vo, D. C. Ranasinghe, "Distributed Multi-Object Tracking under Limited Field of View Sensors," IEEE Transactions on Signal Processing, 2021. [[Paper]](https://doi.org/10.1109/TSP.2021.3108811) [[Code]](https://github.com/AdelaideAuto-IDLab/Distributed-limitedFoV-MOT)

The core tracking and fusion code (`filters_joint/`, `data_fusion/`, `track_matching/`, `misc/`) is taken directly from their implementation. Our contributions are the attack injection block in `run_fused_filter.m`, the spoofed trajectory generation in `gen_truth_attack_scenario.m`, the MPC solver in `mpc/solve_MPC.m`, and the modified scenario settings in `gen_settings.m`.

---

## Requirements

- MATLAB (tested on R2023b)
- [CasADi](https://web.casadi.org/get/) — required for the stealthy attack only. Download the MATLAB version and place it in `mpc/casadi_files/`.

---

## Usage

Open `main.m`, select the attack type and number of trials at the top of the file, and run. 

