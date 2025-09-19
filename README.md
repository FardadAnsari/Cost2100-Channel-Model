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
    ```matlab 
   ir_vla = create_IR_omni_MIMO_VLA(link_use, freq, delta_f, 'Wideband');

4. **Transform into Angular–Delay domain**
 ```matlab
   H_ang_delay = fftshift(fft(h_da, [], 2), 2);



### Real Part of CSI
![Real Part](https://raw.githubusercontent.com/FardadAnsari/Cost2100-Channel-Model/main/images/csireal.png)

### Imaginary Part of CSI
![Imaginary Part](https://raw.githubusercontent.com/FardadAnsari/Cost2100-Channel-Model/main/images/csiimag.png)

## 🔎 Applications
- MIMO channel modeling & analysis  
- CSI feedback & compression (CsiNet, CLNet, CLLWCsiNet, etc.)  
- Beamforming, precoding, and massive MIMO research  
- Dataset creation for deep learning in wireless communications
MIMO channel modeling & analysis

CSI feedback & compression (CsiNet, CLNet, CLLWCsiNet)

Precoding, beamforming, and massive MIMO experiments

⚡ This repo helps generate and analyze realistic CSI data from COST2100, supporting wireless communication research and machine learning applications.
