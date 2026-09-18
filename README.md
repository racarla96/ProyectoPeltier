# Fase 1 — Planta térmica virtual Peltier en RP2040

## 1. Firmware (RP2040)

Requisitos: `pico-sdk` instalado y variable de entorno `PICO_SDK_PATH` apuntando a él.

```bash
cd firmware
mkdir build && cd build
cmake -DPICO_BOARD=pico ..
make -j4
```

Esto genera `peltier_virtual_plant.uf2`. Copia ese archivo a la RP2040 en modo
BOOTSEL (mantener botón BOOTSEL al conectar el USB, aparece como unidad de
almacenamiento).

Tras el flasheo, la placa expone un puerto serie USB-CDC. Cada 10 ms envía:

```
T,<t_ms>,<T_amb>,<T_c>,<T_h>
```

y acepta líneas:

```
U,<u>      # u en [-1, 1]
```

Si no llega ningún `U,...` en 500 ms (`WATCHDOG_MS` en `main.c`), `u` se
fuerza a 0 automáticamente.

Parámetros del modelo térmico (editables en `thermal_model.h`,
`thermal_params_default()`): `T_room, R_c, R_h, R_amb, C_c, C_h, C_amb, K_p`.
`K_p` es el único parámetro "nuevo" de esta fase — el coeficiente térmico
efectivo que traduce `u` en flujo de calor bombeado de la cara fría a la
caliente.

## 2. MATLAB / Simulink

1. Copia `ThermalPlantInterface.m` a una carpeta de tu path de MATLAB.
2. Identifica el puerto serie asignado a la RP2040 (`Device Manager` en
   Windows, `ls /dev/tty.*` en macOS, `ls /dev/ttyACM*` en Linux) y edita
   la propiedad `Port` por defecto en `ThermalPlantInterface.m`, o cámbiala
   tras insertar el bloque en Simulink (doble clic → parámetros del bloque).
3. Ejecuta en MATLAB:

   ```matlab
   build_thermal_model
   ```

   Esto crea `peltier_fase1_control.slx` con:
   - Referencia de temperatura (constante, editable)
   - Lazo de error + PID
   - Saturación de `u` en [-1, 1]
   - Bloque `MATLAB System` (`ThermalPlantInterface`) como planta HIL real
   - Scopes de temperaturas y de `u`
   - Logging a workspace (`peltier_log`)

4. Abre el modelo, ajusta `Port` en el bloque `RP2040_Plant` y simula.

## 3. Siguiente paso (Fase 2)

Sustituir en el firmware `thermal_model_step()` por lecturas reales de
sensores de temperatura y una salida PWM hacia la etapa de potencia de la
Peltier, manteniendo exactamente el mismo protocolo de 3 temperaturas + 1
acción de control. El lado MATLAB/Simulink no debería necesitar cambios.
