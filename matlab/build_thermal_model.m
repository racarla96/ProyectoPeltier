function build_thermal_model()
% build_thermal_model  Crea el modelo Simulink de la Fase 1:
%   Referencia -> PID -> ThermalPlantInterface (RP2040) -> Scopes + logging
%
% Requiere que ThermalPlantInterface.m este en el path de MATLAB.

modelName = "peltier_fase1_control";
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

Ts = 0.01; % 100 Hz, igual que la planta

set_param(modelName, 'Solver', 'FixedStepDiscrete', 'FixedStep', num2str(Ts));

% --- Referencia de temperatura ---
add_block('simulink/Sources/Constant', modelName + "/T_ref", ...
    'Value', '15', 'Position', [30 100 80 130]);

% --- Suma (error) ---
add_block('simulink/Math Operations/Sum', modelName + "/Error", ...
    'Inputs', '+-', 'Position', [140 90 165 140]);

% --- Controlador PID ---
add_block('simulink/Continuous/PID Controller', modelName + "/PID", ...
    'P', '0.3', 'I', '0.05', 'D', '0', ...
    'Position', [220 90 320 140]);

% --- Saturacion de u en [-1, 1] ---
add_block('simulink/Discontinuities/Saturation', modelName + "/Sat_u", ...
    'UpperLimit', '1', 'LowerLimit', '-1', ...
    'Position', [360 90 410 140]);

% --- Bloque MATLAB System: interfaz con la RP2040 ---
add_block('simulink/User-Defined Functions/MATLAB System', ...
    modelName + "/RP2040_Plant", ...
    'Position', [460 60 620 200]);
set_param(modelName + "/RP2040_Plant", 'System', 'ThermalPlantInterface');

% --- Realimentacion: T_c es la variable controlada ---
add_line(modelName, 'T_ref/1', 'Error/1');
add_line(modelName, 'RP2040_Plant/2', 'Error/2'); % salida 2 = T_c
add_line(modelName, 'Error/1', 'PID/1');
add_line(modelName, 'PID/1', 'Sat_u/1');
add_line(modelName, 'Sat_u/1', 'RP2040_Plant/1');

% --- Scopes ---
add_block('simulink/Sinks/Scope', modelName + "/Scope_Temperaturas", ...
    'Position', [700 40 750 120], 'NumInputPorts', '3');
add_line(modelName, 'RP2040_Plant/1', 'Scope_Temperaturas/1');
add_line(modelName, 'RP2040_Plant/2', 'Scope_Temperaturas/2');
add_line(modelName, 'RP2040_Plant/3', 'Scope_Temperaturas/3');

add_block('simulink/Sinks/Scope', modelName + "/Scope_u", ...
    'Position', [460 240 510 280]);
add_line(modelName, 'Sat_u/1', 'Scope_u/1');

% --- Logging a workspace (mux + To Workspace) ---
add_block('simulink/Signal Routing/Mux', modelName + "/Mux_log", ...
    'Inputs', '4', 'Position', [700 160 720 220]);
add_line(modelName, 'RP2040_Plant/1', 'Mux_log/1');
add_line(modelName, 'RP2040_Plant/2', 'Mux_log/2');
add_line(modelName, 'RP2040_Plant/3', 'Mux_log/3');
add_line(modelName, 'Sat_u/1', 'Mux_log/4');

add_block('simulink/Sinks/To Workspace', modelName + "/Log_signals", ...
    'VariableName', 'peltier_log', 'SaveFormat', 'Structure With Time', ...
    'Position', [760 165 830 195]);
add_line(modelName, 'Mux_log/1', 'Log_signals/1');

save_system(modelName);
fprintf('Modelo "%s.slx" creado. Configura Port en ThermalPlantInterface antes de simular.\n', modelName);

end
