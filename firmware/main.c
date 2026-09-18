// Fase 1 - Planta termica virtual (Peltier) sobre RP2040
// Comunicacion: USB CDC (stdio_usb). Periodo de planta: 10 ms (100 Hz).
//
// Protocolo:
//   RP2040 -> Host (cada 10 ms): "T,<t_ms>,<T_amb>,<T_c>,<T_h>\n"
//   Host   -> RP2040:            "U,<u>\n"   (u en [-1,1])
//
// Watchdog de comando: si no se recibe una nueva 'u' en WATCHDOG_MS,
// la accion de control se lleva a 0 automaticamente.

#include <stdio.h>
#include <string.h>
#include "pico/stdlib.h"
#include "pico/time.h"

#include "thermal_model.h"
#include "protocol.h"

#define PLANT_PERIOD_MS   10
#define WATCHDOG_MS       500   // tiempo maximo sin recibir 'u' antes de forzar u=0

static double clampd(double v, double lo, double hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

int main(void) {
    stdio_init_all();

    // Esperar conexion USB CDC (no bloqueante indefinidamente: continua igualmente
    // tras un timeout para no dejar la placa colgada si no hay host).
    absolute_time_t usb_wait_deadline = make_timeout_time_ms(3000);
    while (!stdio_usb_connected() && absolute_time_diff_us(get_absolute_time(), usb_wait_deadline) > 0) {
        sleep_ms(10);
    }

    ThermalParams params = thermal_params_default();
    ThermalState state;
    thermal_model_init(&state, &params);

    double u = 0.0;
    absolute_time_t last_u_time = get_absolute_time();
    absolute_time_t next_tick = get_absolute_time();

    char line_buf[PROTOCOL_LINE_BUF_SIZE];
    int line_len = 0;

    uint32_t t_ms = 0;

    while (true) {
        // --- Lectura no bloqueante de comandos entrantes ---
        int c;
        while ((c = getchar_timeout_us(0)) != PICO_ERROR_TIMEOUT) {
            if (c == '\n' || c == '\r') {
                if (line_len > 0) {
                    line_buf[line_len] = '\0';
                    double new_u;
                    if (protocol_parse_line(line_buf, &new_u)) {
                        u = clampd(new_u, -1.0, 1.0);
                        last_u_time = get_absolute_time();
                    }
                    line_len = 0;
                }
            } else if (line_len < PROTOCOL_LINE_BUF_SIZE - 1) {
                line_buf[line_len++] = (char)c;
            } else {
                // linea demasiado larga: descartar
                line_len = 0;
            }
        }

        // --- Watchdog de comando ---
        if (absolute_time_diff_us(last_u_time, get_absolute_time()) > (int64_t)WATCHDOG_MS * 1000) {
            u = 0.0;
        }

        // --- Tick de planta a periodo fijo (10 ms) ---
        if (absolute_time_diff_us(get_absolute_time(), next_tick) <= 0) {
            thermal_model_step(&state, &params, u);
            t_ms += PLANT_PERIOD_MS;

            protocol_send_sample(t_ms, state.T_amb, state.T_c, state.T_h);

            next_tick = delayed_by_ms(next_tick, PLANT_PERIOD_MS);
        }

        tight_loop_contents();
    }

    return 0;
}
