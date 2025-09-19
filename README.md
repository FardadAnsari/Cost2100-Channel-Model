# Cost2100-Channel-Model
This repo provides MATLAB implementations of the COST2100 channel model for realistic MIMO simulations. It generates channel state information (CSI) in domains such as spatial–delay and angular–delay, supports dataset creation for deep learning, and includes demo scripts for visualization and analysis in wireless communication research.


# COST2100 Channel Model – CSI Generation

This repository demonstrates how to generate **Channel State Information (CSI)** from the **COST2100 geometry-based stochastic channel model** using MATLAB.

## 📌 Process Overview
1. **Set up scenario parameters**  
   - Frequency range (e.g., 2.57–2.62 GHz)  
   - Antenna array geometry (32-element BS)  
   - MS position and velocity  
   - LOS / NLOS scenario  

2. **Run COST2100**  
   ```matlab
   [paraEx, paraSt, link, env] = cost2100(...);


3. **Generate impulse response (IR)**

```ir_vla = create_IR_omni_MIMO_VLA(link_use, freq, delta_f, 'Wideband');

