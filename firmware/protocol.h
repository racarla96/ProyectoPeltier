#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// ---- Salida (RP2040 -> Host) ----
// Formato: "T,<t_ms>,<T_amb>,<T_c>,<T_h>\n"
static inline void protocol_send_sample(uint32_t t_ms, double T_amb, double T_c, double T_h) {
    printf("T,%lu,%.4f,%.4f,%.4f\n", (unsigned long)t_ms, T_amb, T_c, T_h);
}

// ---- Entrada (Host -> RP2040) ----
// Formato esperado: "U,<u>\n"
// Devuelve 1 si se parseo correctamente una nueva u, 0 en caso contrario.
static inline int protocol_parse_line(const char *line, double *u_out) {
    if (line[0] != 'U' || line[1] != ',') {
        return 0;
    }
    char *endptr;
    double val = strtod(line + 2, &endptr);
    if (endptr == line + 2) {
        return 0; // no se pudo parsear ningun numero
    }
    *u_out = val;
    return 1;
}

#define PROTOCOL_LINE_BUF_SIZE 64

#endif // PROTOCOL_H
