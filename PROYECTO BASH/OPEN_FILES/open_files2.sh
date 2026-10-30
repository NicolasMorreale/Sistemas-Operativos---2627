#!/bin/bash

# Variables.

OFFLINE=0
SORT=1
REGEX=""
ACTIVO_U=0
LISTA_USUARIOS=$(who | cut -d' ' -f1 | sort | uniq | tr '\n' ' ') # Mostrar por defecto si no se introduce nada.

# Funciones.

error_exit1() {
    echo $1
    exit 1
}

usage1() {
    cat << _EOF_ 
    open_files [-h | --help] [-f | --file regexp] [-o] [--offline] [-u usuario …] [-s | --sort]

    Opciones:
     -h | --help        Muestra mensaje de ayuda y finaliza la ejecucion con estado 0.
     -f regexp          Filtra los archivos segun su nombre si coincide con la exp regular.
     -o | --offline     Muestra unicamente los usuarios no conectados al sistema.
     -u usuario ...     Elegir los usuarios especificos sobre los que procesar el script.
     -s | --sort        Mostrar la tabla orden por el numero de archivos abiertos (mayor a menor)
_EOF_
}

procesar_argumentos1() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help)
                usage1
                exit 0
                ;;
            -o | --offline)
                OFFLINE=1
                shift
                ;;
            -s | --sort)
                SORT=1
                shift
                ;;
            -f | --file)
                shift 
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit1 "ERROR. Falta la expresion regular de la opcion -f."
                fi
                REGEX=$1
                shift
                ;;
            -u)
                shift
                ACTIVO_U=1
                LISTA_USUARIOS="" # Vaciamos para no usar la opcion por defecto.
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit1 "ERROR. Falta el argumento de la opcion -u."
                fi
                while [[ "$1" != "" &&  "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -*)
                error_exit1 "ERROR. Opcion no conocida."
                ;;
            *)
                error_exit1 "ERROR. Argumento invalido."
                ;;
        esac
    done
}

