#!/bin/bash

# SSOO
# Nicolas Morreale Toledo

# Variables.

OPCION_R=0
OPCION_U=0
OPCION_S=0
OPCION_O=0

REGEX=""
USUARIOS=""
DIR=""

# Funciones.

error_exit() {
    echo "$1" >&2
    exit 1
}

lsof_installed() {
    which lsof >/dev/null 2>/dev/null
}

ps_installed() {
    which ps >/dev/null 2>/dev/null
}

du_installed() {
    which du >/dev/null 2>/dev/null
}

help() {
    echo "Uso: $0 [-h | --help] [-r regex] [-s] [-u usuarios ...] [-o]"
}

dir_existe() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

usuario_existe() {
    id "$1" >/dev/null 2>/dev/null
}

usuario_esta_conectado() {
    who | awk '{print $1}' | grep "^$1$" >/dev/null 2>/dev/null
}

get_numero_procesos() {
    if [[ "$REGEX" != "" ]]; then
        ps -u "$1" 2>/dev/null | awk -v regex="$REGEX" 'NR > 1 && $NF ~ regex' | wc -l
    else
        ps -u "$1" 2>/dev/null | awk 'NR > 1' | wc -l
    fi
}

get_open_reg_files() {
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


get_mem_kb() {
    if [[ "$REGEX" != "" ]]; then
        ps -u "$1" -o rss= -o command= 2>/dev/null | awk -v regex="$REGEX" '$2 ~ regex {sum+=$1} END {print sum+0}'
    else    
        ps -u "$1" -o rss= -o command= 2>/dev/null | awk '{sum+=$1} END {print sum+0}'
    fi
}

get_disk_kb() {
    if [[ "$DIR" != "" ]]; then
       disk_kb=$(du -sk "$DIR" 2>/dev/null | awk '{print $1}')
    else
        disk_kb=$(du -sk 2>/dev/null | awk '{print $1}')
    fi

    if [[ "$disk_kb" != "" ]]; then
        echo "$disk_kb"
    else
        echo 0
    fi
    
}

procesar_opciones() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help)
                help
                exit 0
                ;;
            -r)
                OPCION_R=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el argumento de la opcion -r."
                fi
                REGEX="$1"
                shift
                ;;
            -u)
                OPCION_U=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "ERROR. Falta el/los argumento/s de la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    USUARIOS="$USUARIOS $1"
                    shift
                done
                ;;
            -s)
                OPCION_S=1
                shift
                ;;
            -o) 
                OPCION_O=1
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

if ! lsof_installed; then
    error_exit "ERROR. El comando 'lsof' no esta instalado en el sistema."
fi

if ! ps_installed; then
    error_exit "ERROR. El comando 'ps' no esta instalado en el sistema."
fi

if ! du_installed; then
    error_exit "ERROR. El comando 'du' no esta instalado en el sistema."
fi

if [[ "$MONITOR_TARGET_DIR" != "" ]]; then
    if ! dir_existe "$MONITOR_TARGET_DIR"; then
        error_exit "ERROR. No existe el directorio especificado en la variable de entorno 'MONITOR_TARGET_DIR'."
    fi
    DIR="$MONITOR_TARGET_DIR"
fi

for usuario in $USUARIOS; do
    if ! usuario_existe "$usuario"; then
        error_exit "ERROR. El usuario '$usuario' no existe en el sistema."
    fi
done

# Logica del programa principal.

main() {

    # Eleccion del conjunto de usuarios a analizar.
    USUARIOS_FINAL=""
    if [[ $OPCION_U-eq 1 ]]; then
        USUARIOS_FINAL="$USUARIOS"
    elif [[ $OPCION_O -eq -1 && $OPCION_U -eq 0 ]]; then
        USUARIOS_FINAL=$(cut -d: -f1 /etc/passwd)
    else
        USUARIOS_FINAL=$(who | awk '{print $1}' | sort -u)
    fi

    # Filtrar dicho conjunto seleccionado.
    USUARIOS_FILTRADOS=""
    for usuario_final in $USUARIOS_FINAL; do
        if usuario_esta_conectado "$usuario_final"; then
            CONECTADO=1
        else
            CONECTADO=0
        fi

        if [[ $OPCION_O -eq 1 && $CONECTADO -eq 0 ]]; then
            USUARIOS_FILTRADOS="$USUARIOS_FILTRADOS $usuario_final"
        elif [[ $OPCION_O -eq 0 && $CONECTADO -eq 1 ]]; then
            USUARIOS_FILTRADOS="$USUARIOS_FILTRADOS $usuario_final"
        fi
    done

    # Elegir por que columna ordenar la tabla.
    SORT_cmd="sort -k3,3n"
    if [[ $OPCION_S -eq 1 ]]; then
        SORT_cmd="sort -k4,4nr"
    fi

    # Opcion por defecto -> MEM_KB.
    if [[ "$MONITOR_TARGET_DIR" == "" ]]; then

        printf "%-15s %-10s %-10s %s\n" "USER" "N_PROC" "MEM_KB" "OPEN_FILES"
        for usuario in $USUARIOS_FILTRADOS; do
            N_PROC=$(get_numero_procesos "$usuario")
            MEM_KB=$(get_mem_kb "$usuario")
            OPEN_FILES=$(get_open_reg_files "$usuario")
            printf "%-15s %-10s %-10s %s\n" "$usuario" "$N_PROC" "$MEM_KB" "$OPEN_FILES"
        done | $SORT_cmd
        
    # Opcion si asignas valor a la variable de entorno -> DISK_KB.
    else
        printf "%-15s %-10s %-10s %s\n" "USER" "N_PROC" "DISK_KB" "OPEN_FILES"
        for usuario in $USUARIOS_FILTRADOS; do
            N_PROC=$(get_numero_procesos "$usuario")
            DISK_KB=$(get_disk_kb "$usuario")
            OPEN_FILES=$(get_open_reg_files "$usuario")
            printf "%-15s %-10s %-10s %s\n" "$usuario" "$N_PROC" "$DISK_KB" "$OPEN_FILES"
        done | $SORT_cmd
    fi
}

main