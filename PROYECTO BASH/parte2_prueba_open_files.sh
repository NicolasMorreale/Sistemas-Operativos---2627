#!/bin/bash

# Variables

OPCION_R=0
OPCION_U=0
OPCION_F=0
OPCION_E=0

LISTA_USUARIOS=$(cut -d: -f1 /etc/passwd)
EXPRESION_REGULAR=""
FILTRO=""

# Funciones

error_exit() {
    echo "$1" >&2
    exit 1
}

lsof_en_path() {
    which lsof > /dev/null 2> /dev/null
}

get_num_archivos_abiertos() {
    # Si nos dan la expresion regular para el filtro, la usamos.
    if [[ "$FILTRO" != "" ]]; then
        lsof -u "$1" 2> /dev/null | awk 'NR > 1' | grep -E "${FILTRO}\$" | wc -l
    else
        lsof -u "$1" 2> /dev/null | awk 'NR > 1' | wc -l
    fi
}

procesar_argumentos() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -f | --file)
                OPCION_F=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -f."
                fi
                FILTRO=$1
                shift
                ;;
            -e)
                # Si se activa, usamos la expresion regular la cadena almacenada en la variable de entorno OPEN_FILES_REG
                OPCION_E=1
                shift
                ;;
            -u | --user)
                shift
                OPCION_U=1
                LISTA_USUARIOS=""
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta la lista de usuarios en la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -r)
                OPCION_R=1
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
# Comprobacion de ejecucion

if ! lsof_en_path; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el path."
fi

if [[ ]]

# Programa principal