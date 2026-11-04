#!/bin/bash

# SSOO.
# Nicolas Morreale Toledo.

# Variables.

OPCION_D=0
OPCION_U=0
OPCION_W=0

DIR=""
USUARIO=""
RUTA_PATH=$(echo $PATH | tr ':' ' ')

# Funciones.

error_exit() {
    echo "$1" >&2 
    exit 1
}

help() {
    echo "Uso: $0 [-h] [[-d dir] [-u usuario] | [-w]]"
}

lsof_esta_instalado() {
    which lsof >/dev/null 2>/dev/null
}

existe_usuario() {
    id "$1" >/dev/null 2>/dev/null
}

existe_dir() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

salida_estandar() {
    ARGUMENTOS_LSOF=""
    for directorios in $HOME $RUTA_PATH; do
        if existe_dir "$directorios"; then
            ARGUMENTOS_LSOF="$ARGUMENTOS_LSOF +D $directorios"
        fi
    done

    lsof $ARGUMENTOS_LSOF 2>/dev/null | awk 'NR > 1'
}

procesar_op() {
    
    while [[ "$1" != "" ]]; do
        case "$1" in 
            -h)
                help
                exit 0
                ;;
            -d)
                OPCION_D=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -d."
                fi

                DIR="$1"
                shift
                ;;
            -u)
                OPCION_U=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -u."
                fi

                USUARIO="$1"
                shift
                ;;
            -w)
                OPCION_W=1
                shift
                ;;
            -*)
                error_exit "ERROR. Opcion desconocida."
                ;;
            *)  
                error_exit "ERROR. Argumento no valido."
                ;;
        esac
    done
}

procesar_op "$@"

# Comprobaciones de ejecucion.

if ! lsof_esta_instalado; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

if ! existe_usuario "$USUARIO"; then
    error_exit "El usuario '$USUARIO' no existe en el sistema."
fi

if [[ "$OPEN_FILES_FOLDER" != "" ]]; then
    if ! existe_dir "$OPEN_FILES_FOLDER"; then
        error_exit "ERROR. No existe la ruta especificada en la variable de entorno 'OPEN_FILES_FOLDER'."
    fi
fi

if [[ $OPCION_W -eq 1 ]]; then
    if [[ $OPCION_D -eq 1 && $OPCION_U -eq 1 ]]; then
        error_exit "ERROR. Las opciones -w y (-d,-u) son incompatibles, si usa -w no podra usar las otras dos, y viceversa."
    fi
fi

# Logica del programa principal.

main() {

    # Ejecutar modo -w.
    if [[ $OPCION_W -eq 1 ]]; then
        pids=$(ps -u $USER 2>/dev/null | awk 'NR > 1 {print $1}')
        for pid in $pids; do
            dir_actual=$(pwdx "$pid" 2>/dev/null | awk '{print $2}')
            if [[ "$dir_actual" != "" && existe_dir "$dir_actual" ]]; then
                lsof +D "$dir_actual" 2>/dev/null | awk 'NR > 1'
            else
                echo "El PID $pid no devuelve una ruta existente."
            fi
        done
    fi

    PARAMETROS_LSOF=""
    if [[ $OPCION_U -eq 1 ]]; then
        PARAMETROS_LSOF="-u $USUARIO"
    fi

    DIRECTORIOS_A_BUSCAR=""
    if [[ $OPCION_D -eq 1 || "$OPEN_FILES_FOLDER" != "" ]]; then
        if [[ $OPCION_D -eq 1 ]]; then
            DIRECTORIOS_A_BUSCAR="$DIR"
        fi

        if [[ "$OPEN_FILES_FOLDER" != "" ]]; then
            DIRECTORIOS_A_BUSCAR="$DIRECTORIOS_A_BUSCAR $OPEN_FILES_FOLDER"
        fi
    else
        DIRECTORIOS_A_BUSCAR="$HOME $RUTA_PATH"
    fi

    if [[ $OPCION_U -eq 1 && "$DIRECTORIOS_A_BUSCAR" != "" ]]; then
        PARAMETROS_LSOF="$PARAMETROS_LSOF -a"
    fi

    for dir in $DIRECTORIOS_A_BUSCAR; do
        if existe_dir "$dir"; then
            PARAMETROS_LSOF="$PARAMETROS_LSOF +D $dir"
        fi
    done

    lsof "$PARAMETROS_LSOF" 2>/dev/null | awk 'NR > 1'
}

main

