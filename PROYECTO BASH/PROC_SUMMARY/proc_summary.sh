#!/bin/bash

# SSOO 
# Nicolas Morreale Toledo

# Variables.

opcion_o=0
opcion_c=0
opcion_u=0
opcion_s=0

LISTA_USUARIOS=""
REGEX=""
DIRECTORIO=""

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

get_n_procesos() {
    ps -u "$1" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $NF ~ regex' | wc -l
}

get_oldest_pid() {

    if [[ $opcion_c -eq 1 && "$REGEX" != "" ]]; then
        pid=$(ps -u "$1" -o pid -o comm --sort=start_time 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $2 ~ regex {print $1; exit}')
    else
        pid=$(ps -u "$1" -o pid= --sort=start_time 2>/dev/null | head -n 1 | xargs)
    fi

    if [[ "$pid" == "" ]]; then
        echo "NA"
    else
        echo "$pid"
    fi
}

get_open_files() {

    if [[ "$DIRECTORIO" != "" && "$REGEX" != "" ]]; then
        lsof -u "$1" -a +D "$DIRECTORIO" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    elif [[ "$DIRECTORIO" != "" && "$REGEX" == "" ]]; then
        lsof -u "$1" -a +D "$DIRECTORIO" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    elif [[ "$DIRECTORIO" == "" && "$REGEX" != "" ]]; then
        lsof -u "$1" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $5 == "REG" && $NF ~ regex' | wc -l
    else
        lsof -u "$1" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    fi
}

usuario_esta_conectado() {
    who | awk '{print $1}' | grep "^$1$" >/dev/null 2>/dev/null
}

procesar_argumentos() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -c)
                opcion_c=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -c."
                fi
                REGEX="$1"
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
                error_exit "ERROR. Argumento invalido."
                ;;
        esac
    done
}

procesar_argumentos "$@"

# Comprobaciones de ejecucion.

if ! lsof_instalado; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

if ! ps_instalado; then
    error_exit "ERROR. El comando 'ps' no esta instalado en el sistema."
fi

if [[ "$PROC_CHECK_DIR" != "" ]]; then
    if ! directorio_existe "$PROC_CHECK_DIR"; then
        error_exit "ERROR. El directorio indicado en la variable de entorno 'PROC_CHECK_DIR' no existe."
    fi
    DIRECTORIO="$PROC_CHECK_DIR"
fi

for usuario in $LISTA_USUARIOS; do
    if ! usuario_existe "$usuario"; then
        error_exit "ERROR. El usuario '$usuario' no existe en el sistema."
    fi
done

# Logica del programa principal.

main() {

    SORT_CMD="sort -k2,2nr"
    if [[ $opcion_s -eq 1 ]]; then
        SORT_CMD="sort -k4,4nr"
    fi

    # Determinamos que lista de usuarios usaremos segun las opciones -u y -o.
    USUARIOS_FINAL=""
    if [[ $opcion_u -eq 1 ]]; then
        USUARIOS_FINAL="$LISTA_USUARIOS"
    elif [[ $opcion_u -eq 0 && $opcion_o -eq 1 ]]; then
        USUARIOS_FINAL=$(cut -d: -f1 /etc/passwd)
    else
        USUARIOS_FINAL=$(who | awk '{print $1}' | sort -u)
    fi

    # Filtraremos estos usuarios.
    USUARIOS_FILTRADOS=""
    for usuario in $USUARIOS_FINAL; do
        if usuario_esta_conectado "$usuario"; then
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

    # Llamamos a las funciones para hacer los calculos e imprimimos las columnas.
    printf "%-15s %-10s %-12s %s\n" "USER" "N_PROC" "OLDEST_PID" "OPEN_FILES"
    for usuario_filtrado in $USUARIOS_FILTRADOS; do
        n_proc=$(get_n_procesos "$usuario_filtrado")
        oldest_pid=$(get_oldest_pid "$usuario_filtrado")
        open_files=$(get_open_files "$usuario_filtrado")
        printf "%-15s %-10s %-12s %s\n" "$usuario_filtrado" "$n_proc" "$oldest_pid" "$open_files"
    done | $SORT_CMD
}

main
