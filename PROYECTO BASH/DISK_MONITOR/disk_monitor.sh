#!/bin/bash

# Variables.

opcion_R=0
opcion_T=0
opcion_P=0

TIPOS_SISTEMAS=""

# Variables de entorno.  MIN_USE_PCT -> Cantidad minima para filtrar el uso al mostrarlo (uso > MIN_USE_PCT)

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

df_installed() {
    which df >/dev/null 2>/dev/null
}

get_mountpoint_usage() {
    df -PT 2>/dev/null | awk 'NR > 1 {print $7, $6, $2}' | tr -d '%' | while read -r mountpoint usage type; do
        if [[ $usage -gt $PORCENTAJE ]]; then
            if [[ "$TIPOS_SISTEMAS" == "" ]] || [[ " $type " =~ " $TIPOS_SISTEMAS " ]]; then
                echo "$mountpoint $usage"
            fi
        fi
    done
}

procesar_opciones() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help)
                help
                exit 0
                ;;
            -t)
                opcion_T=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -t."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    TIPOS_SISTEMAS="$TIPOS_SISTEMAS $1"
                    shift
                done
                ;;
            -p | --percent)
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -p | --percent."
                fi
                PORCENTAJE="$1"
                opcion_P=1
                shift
                ;;
            -r)
                opcion_R=1
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

# Comprobaciones de ejecucion.

if ! df_installed; then
    error_exit "ERROR. El comando df no esta instalado en el sistema."
fi

if [[ $opcion_P -eq 1 ]]; then

    if ! [[ "$PORCENTAJE" =~ "^[0-9]+$" ]] || [[ "$PORCENTAJE" -gt 100 || "$PORCENTAJE" -lt 0 ]]; then
        error_exit "ERROR. El porcentaje introducido en la opcion -p esta fuera del rango valido (0-100)%."
    fi

elif [[ "$MIN_USE_PCT" != "" ]]; then

    if ! [[ "$PORCENTAJE" =~ "^[0-9]+$" ]] || [[ "$MIN_USE_PCT" -gt 100 || "$MIN_USE_PCT" -lt 0 ]]; then
        error_exit "ERROR. El valor de la variable de entorno MIN_USE_PCT esta fuera del rango valido (0-100)."
    fi
    PORCENTAJE="$MIN_USE_PCT"
fi

# Logica del programa principal.

main() {
    SORT_cmd="sort -k2,2nr"
    if [[ $opcion_R -eq 1 ]]; then
        SORT_cmd="sort -k2,2n"
    fi

    printf "%-25s %s\n" "MOUNTPOINT" "USAGE(%)"
    get_mountpoint_usage | $SORT_cmd | while read -r mountpoint usage; do
        printf "%-25s %s\n" "$mountpoint" "$usage"
    done
}

main