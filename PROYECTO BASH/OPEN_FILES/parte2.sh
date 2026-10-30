#!/bin/bash

# Variables.
opcion_u=0
opcion_f=0
opcion_e=0
opcion_r=0

USUARIOS=$(cut -d: -f1 /etc/passwd)
FILTRO=""

# Funciones.

error_exit2() {
    echo "$1" >&2
    exit 1
}

lsof_instalado2() {
    which lsof >/dev/null 2>/dev/null
}

# $1 = Usuario actual a analizar
get_num_aperturas() {
    if [[ "$FILTRO" != "" ]]; then
        lsof -u "$1" 2>/dev/null | awk 'NR > 1' | grep -E "${FILTRO}\$" | wc -l
    else
        lsof -u "$1" 2>/dev/null | awk 'NR > 1' | wc -l
    fi
}

procesar_opc() {

    while [[ "$1" != "" ]]; do
        case "$1" in 
            -u)
                shift
                opcion_u=1
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit2 "ERROR. Faltan argumentos para la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    USUARIOS="$USUARIOS $1"
                    shift
                done
                ;;
            -f)
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit2 "ERROR. Faltan argumentos para la opcion -f."
                fi
                FILTRO=$1
                shift
                ;;
            -e)
                shift
                opcion_e=1
                ;;
            -r)
                shift
                opcion_r=1
                ;;
            -*)
                error_exit2 "ERROR. Opcion desconocida ($1)."
                ;;
            *)
                error_exit2 "ERROR. Argumento invalido ($1)."
                ;;
        esac
    done
}

procesar_opc "$@"

# Comprobacion de ejecucion.

if ! lsof_instalado2; then
    error_exit2 "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

if [[ $opcion_e -eq 1 && $opcion_f -eq 1 ]]; then
    error_exit2 "ERROR. Incompatibilidad detectada. No se pueden utilizar la opcion -d y -f simultaneamente."
fi

if [[ $opcion_e -eq 1 ]]; then
    if [[ "$OPEN_FILES_REG" == "" ]]; then
        error_exit2 "ERROR. La variable de entorno OPEN_FILES_REG esta vacia."
    fi
    FILTRO=$OPEN_FILES_REG
fi

# Logica del programa principal.

main2() {

    SORT_CMD="sort -k2,2nr"

    if [[ $opcion_r -eq 1 ]]; then
        SORT_CMD="sort -k2,2n"
    fi
    printf "%s\t%s\n" "USUARIOS" "N_ARCHIVOS"
    for usuario in $USUARIOS; do
        N_ARCHIVOS=$(get_num_aperturas $usuario)
        printf "%s\t%s\n" "$usuario" "$N_ARCHIVOS"
    done | $SORT_CMD
}

main2