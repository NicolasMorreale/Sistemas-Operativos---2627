#!/bin/bash

# SSOO
# Nicolas Morreale Toledo

# Variables.

opcion_u=0
opcion_m=0
opcion_r=0

LISTA_USUARIOS=$USER
MIN=-1

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

lsof_instalado() {
    which lsof >/dev/null 2>/dev/null
}

help() {
    echo "Uso: $0 [-h | --help] [-m | --min minimo] [-u | --user usuario/s] [-r]"
}

get_datos_columnas() {
    LISTA_USUARIOS_COMAS=$(echo "$LISTA_USUARIOS" | tr ' ' ',')

    lsof -u "$LISTA_USUARIOS_COMAS" 2>/dev/null | awk 'NR > 1 {print $5}' | sort | uniq -c | while read -r contador type; do
        if [[ $contador -gt $MIN ]]; then
            echo "$type" "$contador"
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
            -u | --user)
                opcion_u=1
                shift
                LISTA_USUARIOS=""
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el/los argumento/s de la opcion -u | --user."
                fi

                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -m | --min)
                opcion_m=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -m | --min."
                fi
                MIN=$1
                shift
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

if ! lsof_instalado; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

if [[ $opcion_m -eq 1 ]]; then
    if ! [[ $MIN =~ ^[0-9]+$ ]] || [[ $MIN -lt 0 ]]; then
        error_exit "ERROR. El argumento de la opcion -m | --min no es un entero valido mayor que cero."
    fi
elif [[ "$MIN_OPEN_FILES" != "" ]]; then
    if ! [[ $MIN_OPEN_FILES =~ ^[0-9]+$ ]] || [[ $MIN_OPEN_FILES -lt 0 ]]; then
        error_exit "ERROR. La variable de entorno 'MIN_OPEN_FILES' no es un entero valido mayor que cero."
    fi
    MIN=$MIN_OPEN_FILES
fi

# Logica del programa principal.

main() {
    SORT_CMD="sort -k2,2nr"
    if [[ $opcion_r -eq 1 ]]; then
        SORT_CMD="sort -k2,2n"
    fi

    printf "%s %s\n" "TYPE" "COUNT"
    get_datos_columnas | $SORT_CMD | while read -r type count; do
        printf "%s %s\n" "$type" "$count"
    done
}

main