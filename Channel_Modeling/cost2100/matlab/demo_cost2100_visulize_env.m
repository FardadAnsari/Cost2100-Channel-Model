% Add the COST2100 MATLAB folder to the path
addpath('path_to_cost2100/matlab');

% Define input parameters
network = 'SemiUrban_300MHz'; % Scenario
scenario = 'LOS'; % LOS or NLOS
freq = [300e6, 300e6]; % Frequency band (300 MHz)
snapRate = 100; % Snapshots per second
snapNum = 1000; % Total snapshots
BSPosCenter = [0, 0, 10]; % BS position [x, y, z] in meters
BSPosSpacing = 0.5; % BS array spacing (m)
BSPosNum = 2; % Number of BS positions
MSPos = [100, 100, 1.5]; % MS initial position [x, y, z] in meters
MSVelo = [1, 0, 0]; % MS velocity [x, y, z] in m/s

% Run the COST2100 model
[paraEx, paraSt, link, env] = cost2100(network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);

disp(link)



% Visualize results (example)
visual_channel(paraEx, paraSt, link, env); % Plot channel environment

