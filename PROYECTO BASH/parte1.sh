#!/bin/bash

# Variables

opcion_u=0
opcion_d=0

USUARIOS=$USER
DIRECTORIO=""

# Funciones

error_exit_() {
    echo "$1" >&2
    exit 1
}

lsof_instalado() {
    which lsof > /dev/null 2> /dev/null
}

get_pids_users() {
    USUARIOS_COMAS=$(echo "$USUARIOS" | tr -s ' ' | tr ' ' ',')
    if [[ "$USUARIOS_COMAS" == "" ]]; then
        return
    fi
    if [[ "$DIRECTORIO" != "" ]]; then
        lsof -u "$USUARIOS_COMAS" -a +D "$DIRECTORIO" 2> /dev/null | awk 'NR > 1 {print $2}' | sort -u
    else
        lsof -u "$USUARIOS_COMAS" 2> /dev/null | awk 'NR > 1 {print $2}' | sort -u
    fi
}

# Le pasamos como $1 el pid dentro del bucle de la logica principal.
get_n_archivos() {
    lsof -p "$1" 2> /dev/null | awk 'NR > 1 {print $1}' | wc -l
}

existe_directorio() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

procesar_opciones() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -u)
                USUARIOS=""
                shift 
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit_ "ERROR. Falta el argumento de la opcion -u."
                fi
                opcion_u=1
                while [[ "$1" != "" && "$1" != -* ]]; do
                    USUARIOS="$USUARIOS $1"
                    shift
                done
                ;;
            -d)
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit_ "ERROR. Falta el argumento de la opcion -d."
                fi
                DIRECTORIO="$1"
                opcion_d=1
                shift
                ;;
            -*)
                error_exit_ "ERROR. $1 es una opcion desconocida."
                ;;
            *)
                error_exit_ "ERROR. Argumento invalido."
                ;;
        esac
    done
}

procesar_opciones "$@"

# Comprobacion de ejecucion

if ! lsof_instalado; then 
    error_exit_ "ERROR. El comando 'lsof' no esta instalado en el path."
fi

if [[ $opcion_d -eq 1 ]]; then
    if ! existe_directorio "$DIRECTORIO"; then
        error_exit_ "ERROR. El directorio indicado '$DIRECTORIO' es incorrecto o inexistente."
    fi
elif [[ "$OPEN_FILES_FOLDER" != "" ]]; then
    if ! existe_directorio "$OPEN_FILES_FOLDER"; then
        error_exit_ "ERROR. La variable de entorno OPEN_FILES_FOLDER contiene una ruta inexistente."
    fi
    DIRECTORIO="$OPEN_FILES_FOLDER"
fi

# Logica del programa principal

main() {

    sort_cmd="sort -k2,2nr"

    printf "%-12s %s\n" "PIDs" "N_ARCHIVOS" 

    PIDS=$(get_pids_users $USUARIOS)
    if [[ "$PIDS" == "" ]]; then
        return
    fi

    for pid in $PIDS; do
        N_ARCHIVOS=$(get_n_archivos $pid)
        printf "%-12s %s\n" "$pid" "$N_ARCHIVOS"
    done | $sort_cmd
}

main