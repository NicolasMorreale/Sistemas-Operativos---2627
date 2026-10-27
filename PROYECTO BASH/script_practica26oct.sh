#!/bin/bash

# ls /tmp : Hacer un script que vaya al directorio /tmp , mire los ficheros que hay ahi , busque con lsof que proceoss tiene abierto ese fichero 
# y muestre usando el PID del proceso que tiene abierto, el porcentaje de memoria que esta consumiendo ese proceso (ps)
# si hay un parametro -d, busque en el directorio diferente que te dan por linea comandos, poner -h para el funcionamiento y si el parametro -d se proporciona mal, error+

# Variables.

OPCION_D=0
DIRECTORIO="/tmp"

# Funciones

error_exit() {
    echo "$1" >&2
    exit 1
}

help() {
    cat << _EOF_
    Uso: /.script_practica26oct [-h | --help] [-d directorio]

    El programa es un script que devuelve el porcentaje de memoria consumida por los procesos que tienen abiertos los ficheros de "/tmp" por defecto,
    o el directorio especificado en la opcion -d. 

    -h | --help: Mostrar ayuda sobre el programa
    -d directorio: Opcion que permite indicar un directorio especifico donde buscar
_EOF_
}

lsof_installed() {
    type lsof > /dev/null 2> /dev/null
}

directorio_existe() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

procesando_opciones() {

    while [[ "$1" != "" ]]
    do
        case "$1" in
            -h | --help)
                help
                exit 0
                ;;
            -d)
                OPCION_D=1
                DIRECTORIO=""
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento DIRECTORIO de la opcion -d"
                fi
                DIRECTORIO="$1"
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

procesando_opciones "$@"

if [[ $OPCION_D -eq 1 ]]; then
    if ! directorio_existe "$DIRECTORIO"; then
        error_exit "ERROR. El directorio especificado '$DIRECTORIO' no existe."
    fi
fi

if ! lsof_installed; then
    error_exit "ERROR. El comando lsof no esta instalado en el sistema."
fi


# Logica del programa.

main() {

for fichero in "$DIRECTORIO"/*; do
    if [[ -f "$fichero" ]]; then
        PIDS=$(lsof "$fichero" 2> /dev/null | awk 'NR > 1 {print $2}' | sort -u)
        for pids in $PIDS; do
            MEMORIA=$(ps -p "$pids" -o %mem=)
            echo "Fichero: $fichero | PID: $pids | Memoria: $MEMORIA%"
        done
    fi
done
}

main