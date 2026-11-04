#!/bin/bash

# SSOO.
# Nicolas Morreale Toledo.

# Variables.

OPCION_U=0
OPCION_S=0
OPCION_R=0

DIR=""
REGEX=""
LISTA_USUARIOS=""

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

lsof_instalado() {
    which lsof >/dev/null 2>/dev/null
}

ps_instalado() {
    which ps >/dev/null 2>/dev/null
}

du_instalado() {
    which du >/dev/null 2>/dev/null
}

existe_directorio() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

existe_usuario() {
    who | awk '{print $1}' | grep "^$1$" >/dev/null 2>/dev/null
}

num_procesos() {
    if [[ "$REGEX" != "" ]]; then
        ps -u "$1" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $NF ~ regex' | wc -l
    else
        ps -u "$1" 2>/dev/null | awk 'NR > 1' | wc -l
    fi
}

open_files() {
    if [[ "$REGEX" != "" && "$DIR" != "" ]]; then
        lsof -u "$1" -a +D "$DIR" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    elif [[ "$REGEX" != "" && "$DIR" == "" ]]; then
        lsof -u "$1" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    elif [[ "$REGEX" == "" && "$DIR" != "" ]]; then
        lsof -u "$1" -a +D "$DIR" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    else 
        lsof -u "$1" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    fi
}

home_kb() {
    if ! existe_directorio "/home/usuario"; then
        echo 0
    else
        du -sk "/home/usuario" | awk '{print $1}'
    fi
}



procesar_opciones() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -r)
                OPCION_R=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Faltan los argumentos de la opcion -r."
                fi
                REGEX="$1"
                shift
                ;;
            -s)
                OPCION_S=1
                shift
                ;;
            -u)
                OPCION_U=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta/n el/los argumento/s de la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
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

if ! ps_instalado; then
    error_exit "ERROR. El comando 'ps' no esta instalado en el sistema."
fi

if ! du_instalado; then
    error_exit "ERROR. El comando 'du' no esta instalado en el sistema."
fi

if [[ "$AUDIT_CHECK_DIR" != "" ]]; then
    if ! existe_directorio "$AUDIT_CHECK_DIR"; then
        error_exit "ERROR. El directorio indicado dentro de la variable de entorno 'AUDIT_CHECK_DIR' no existe en el sistema."
    fi
    DIR="$AUDIT_CHECK_DIR"
fi

for usuarios in $LISTA_USUARIOS; do
    if ! existe_usuario $usuarios; then
        error_exit "ERROR. El usuario '$usuarios' no existe en el sistema."
    fi
done

# Logica del programa principal.

main() {

}

main