#!/bin/bash

# SSOO
# Nicolas Morreale Toledo

# Variables.

opcion_u=0
opcion_f=0
opcion_o=0
opcion_s=0

LISTA_USUARIOS=""
FILTRO=""
DIRECTORIO=""

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

help() {
    echo "Uso: $0 [-h| --help] [-f regex] [-u usuario1 ...] [-o] [-s]"
}

lsof_instalado() {
    which lsof >/dev/null 2>/dev/null
}

usuario_existe() {
    id "$1" >/dev/null 2>/dev/null
}

directorio_existe() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

get_uid() {
    id -u "$1" 2>/dev/null
}

get_oldest_pid() {
    pid=$(ps -u "$1" -o pid= --sort=start_time 2>/dev/null | head -n 1 | xargs)
    if [[ "$pid" == "" ]]; then
        echo "NA"
    else
        echo "$pid"
    fi
}

get_open_files() {
    # Esta la ruta y la expresion regular
    if  [[ "$DIRECTORIO" != "" && "$FILTRO" != "" ]]; then
        lsof -u "$1" -a +D "$DIRECTORIO" 2>/dev/null | awk -v regex="$FILTRO" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    # Esta la ruta pero no la expresion regular
    elif [[ "$DIRECTORIO" != "" && "$FILTRO" == "" ]]; then
        lsof -u "$1" -a +D "$DIRECTORIO" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    # No esta la ruta pero esta la expresion regular
    elif [[ "$DIRECTORIO" == "" && "$FILTRO" != "" ]]; then
        lsof -u "$1" 2>/dev/null | awk -v regex="$FILTRO" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    # No estan ninguna de las dos
    else
        lsof -u "$1" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    fi
}   

usuario_en_sistema() {
    who | awk '{print $1}' | grep "^$1$" >/dev/null 2>/dev/null
}

procesar_argumentos() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help)
                help
                exit 0
                ;;
            -f)
                opcion_f=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -f."
                fi
                FILTRO=$1
                shift
                ;;
            -u)
                opcion_u=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el/los argumento/s de la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -o)
                opcion_o=1
                shift
                ;;
            -s)
                opcion_s=1
                shift
                ;;
            -*)
                error_exit "ERROR. Opcion desconocida."
                ;;
            *)
                error_exit "ERROR. Argumento invalido"
                ;;
        esac
    done
}

procesar_argumentos "$@"

# Comprobaciones de ejecucion.

if ! lsof_instalado; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

for usuario in $LISTA_USUARIOS; do
    if ! usuario_existe $usuario; then
        error_exit "ERROR. El usuario '$usuario' no existe en el sistema."
    fi
done

if [[ "$OPEN_FILES_FOLDER" != "" ]]; then
    if ! directorio_existe "$OPEN_FILES_FOLDER"; then
        error_exit "ERROR. El directorio especificado en la variable de entorno 'OPEN_FILES_FOLDER' no existe."
    fi
    DIRECTORIO="$OPEN_FILES_FOLDER"
fi

# Logica del programa principal.

main() {

    SORT_CMD="sort -k1,1"
    if [[ $opcion_s -eq 1 ]]; then
        SORT_CMD="sort -k4,4nr"
    fi

    # Determinamos la lista de usuarios sobre la que operar.
    USUARIOS_FINAL=""
    if [[ $opcion_u -eq 1 ]]; then
        USUARIOS_FINAL="$LISTA_USUARIOS"
    elif [[ $opcion_o -eq 1 ]]; then
        USUARIOS_FINAL=$(cut -d: -f1 /etc/passwd)
    else 
        USUARIOS_FINAL=$(who | awk '{print $1}' | sort -u)
    fi

    # Filtramos para poder saber cuales estan conectados o no.
    for usuario in $USUARIOS_FINAL; do
        if usuario_en_sistema "$usuario"; then
            conectado=1
        else
            conectado=0
        fi

        if [[ $opcion_o -eq 1 && $conectado -eq 0 ]]; then
            USUARIOS_FILTRADOS="$USUARIOS_FILTRADOS $usuario"
        elif [[ $opcion_o -eq 0 && $conectado -eq 1 ]]; then
            USUARIOS_FILTRADOS="$USUARIOS_FILTRADOS $usuario"
        fi
    done

    printf "%-15s %-8s %-12s %s\n" "USER" "UID" "OLDEST_PID" "N_REG_FILES"

    # Calculamos las columnas usando las funciones y las mostramos.
    for user in $USUARIOS_FILTRADOS; do
        UID=$(get_uid "$user")
        OLDEST_PID=$(get_oldest_pid "$user")
        N_ARCHIVOS=$(get_open_files "$user")

        printf "%-15s %-8s %-12s %s\n" "$user" "$UID" "$OLDEST_PID" "$N_ARCHIVOS"
    done | $SORT_CMD
}

main