#ifndef THERMAL_MODEL_H
#define THERMAL_MODEL_H

// Estados de la planta térmica virtual (Fase 1)
typedef struct {
    double T_amb;   // Temperatura ambiente (nodo lento, no afectado por Peltier)
    double T_c;     // Temperatura cara fría
    double T_h;     // Temperatura cara caliente
} ThermalState;

// Parametros del modelo (analogia RC, ver Machines 2021)
typedef struct {
    double T_room;  // Temperatura de referencia del entorno [C]
    double R_c;     // Resistencia termica cara fria -> ambiente [K/W]
    double R_h;     // Resistencia termica cara caliente -> ambiente [K/W]
    double R_amb;   // Resistencia termica nodo ambiente -> T_room [K/W]
    double C_c;     // Capacidad termica cara fria [J/K]
    double C_h;     // Capacidad termica cara caliente [J/K]
    double C_amb;   // Capacidad termica nodo ambiente [J/K]
    double K_p;      // Coeficiente termico efectivo Peltier [W] (Q = K_p * u)
    double dt;       // Paso de integracion [s]
} ThermalParams;

// Parametros nominales de partida (referencia bibliografica indicada por el usuario)
static inline ThermalParams thermal_params_default(void) {
    ThermalParams p;
    p.T_room = 21.0;
    p.R_c    = 0.40;
    p.R_h    = 0.15;
    p.R_amb  = 2.0;
    p.C_c    = 100.0;
    p.C_h    = 70.0;
    p.C_amb  = 15.98;
    p.K_p    = 5.0;      // W, valor de partida ajustable
    p.dt     = 0.010;    // 10 ms -> 100 Hz
    return p;
}

static inline void thermal_model_init(ThermalState *s, const ThermalParams *p) {
    s->T_amb = p->T_room;
    s->T_c   = p->T_room;
    s->T_h   = p->T_room;
}

// u en [-1, 1] ya saturado por el llamador. u>0 => refrigeracion (Q sale de T_c hacia T_h)
static inline void thermal_model_step(ThermalState *s, const ThermalParams *p, double u) {
    double Q = p->K_p * u;

    double dTc = ((p->T_room - s->T_c) / p->R_c - Q) / p->C_c;
    double dTh = ((p->T_room - s->T_h) / p->R_h + Q) / p->C_h;
    double dTamb = (p->T_room - s->T_amb) / p->R_amb / p->C_amb;

    // Euler explicito
    s->T_c   += p->dt * dTc;
    s->T_h   += p->dt * dTh;
    s->T_amb += p->dt * dTamb;
}

#endif // THERMAL_MODEL_H
