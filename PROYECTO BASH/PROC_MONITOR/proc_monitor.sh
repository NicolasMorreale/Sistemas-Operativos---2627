#!/bin/bash

# SSOO
# Nicolas Morreale Toledo

# Variables.

opcion_r=0
opcion_u=0
opcion_c=0

LISTA_USUARIOS=$USER
UMBRAL=-1

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

help() {
    echo "Uso: $0 [-h | --help] [-u | --user usuario] [-c | --cpu umbral] [-r]"
}

ps_instalado() {
    which ps >/dev/null 2>/dev/null
}

get_pid_cpu() {
    ps -u "$LISTA_USUARIOS" -o pid,%cpu 2>/dev/null | awk -v umbral="$UMBRAL" 'NR > 1 && $2 > umbral {print $1, $2}'
}

procesar_opciones() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help)
                help
                exit 0
                ;;
            -c | --cpu)
                shift 
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento para la opcion -c."
                fi
                UMBRAL=$1
                opcion_c=1
                shift
                ;;
            -u | --user)
                shift
                opcion_u=1
                LISTA_USUARIOS=""
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el/los argumento/s para la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -r)
                opcion_r=1
                shift
                ;;
            -*)
                error_exit "ERROR. Opcion desconocida."
                ;;
            *)
                error_exit "ERROR. Argumento invalido."
                ;;
        esac
    done
}

procesar_opciones "$@"

# Comprobaciones de ejecucion.

if ! ps_instalado; then
    error_exit "ERROR. El comando 'ps' no esta instalado en el sistema."
fi

if [[ $opcion_c -eq 1 ]]; then
    if ! [[ $UMBRAL =~ ^[0-9]+$ ]] || [[ $UMBRAL -gt 100 || $UMBRAL -lt 0 ]]; then
        error_exit "ERROR. El valor introducido como umbral es no-numerico o esta fuera del rango (0-100)."
    fi
elif [[ "$MIN_CPU_PCT" != "" ]]; then
    if ! [[ $MIN_CPU_PCT =~ ^[0-9]+$ ]] || [[ $MIN_CPU_PCT -gt 100 || $MIN_CPU_PCT -lt 0 ]]; then
        error_exit "ERROR. La variable de entorno 'MIN_USE_CPU' contiene un valor no-numerico o fuera del rango (0-100)."
    fi
    UMBRAL=$MIN_CPU_PCT
fi

# Logica del programa principal.

main() {

    SORT_CMD="sort -k2,2nr"
    if [[ $opcion_r -eq 1 ]]; then
        SORT_CMD="sort -k2,2n"
    fi

    printf "%s %s\n" "PID" "%CPU"
    get_pid_cpu | $SORT_CMD | while read -r pid cpu; do
        printf "%s %s\n" "$pid" "$cpu"
    done
}

main