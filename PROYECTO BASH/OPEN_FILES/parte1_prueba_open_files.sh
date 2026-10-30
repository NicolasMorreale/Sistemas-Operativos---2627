#!/bin/bash

#================================================================
# Variables.
#================================================================

OPCION_D=0
DIR=""
LISTA_USUARIOS=$USER

# ================================================================
# Funciones.
# ================================================================

# a) 1 punto. Implementa una función de bash llamada error_exit que sirva para enviar un mensaje de error a la salida de error
# y terminar el script con estado diferente de 0. Esta función será llamada
# para cualquier terminación en estado de error con un mensaje que describa el motivo del mismo. 

error_exit_() {
    echo "$1" >&2
    exit 1
}

# b) 1 punto. El script empezará comprobando si el programa lsof está en el path (ayuda: comando which).
# En caso de que no lo esté, el script terminará con error (ver 1.a). 
# El script terminará con error también si el usuario introduce una opción no soportada por el comando.  

lsof_en_path_() {
    which lsof > /dev/null 2> /dev/null
}

# 1 punto. Si el script se llama con la opción -d directorio, el directorio utilizado será el
# señalado por la opción -d. También debe comprobarse que el directorio señalado
# existe y salir del script con error si no es así (ver 1.a).

existe_dir_() {
    if [[ -d "$1" ]]; then
        return 0
    else 
        return 1
    fi
}

get_pids_usuarios_() {
    LISTA_COMAS=$(echo "$LISTA_USUARIOS" | tr -s ' ' | tr ' ' ',')
    if [[ "$LISTA_COMAS" == "" ]]; then
        return
    fi

    # Si hay directorio especificado, filtramos por directorio
    if [[ "$DIR" != "" ]]; then
        lsof -u "$LISTA_COMAS" -a +D "$DIR" 2> /dev/null | awk 'NR > 1 {print $2}' | sort -u
    else 
        lsof -u "$LISTA_COMAS" 2> /dev/null | awk 'NR > 1 {print $2}' | sort -u
    fi 
}

get_num_archivos_() {
    PID_ACTUAL="$1"
    # Si hay algun directorio (-d o OPEN_FILES_FOLDER).
    if [[ "$DIR" != "" ]]; then
        lsof -p "$PID_ACTUAL" -a +D "$DIR" 2> /dev/null | awk 'NR > 1' | wc -l
    else 
    # Si no hay directorio.
        lsof -p "$PID_ACTUAL" 2> /dev/null | awk 'NR > 1' | wc -l
    fi
}

procesar_opciones_() {

    while [[ "$1" != "" ]]; do
        case "$1" in
            # -d -> Se usa el directorio que figura como arg de -d.
            -d)
                OPCION_D=1
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit_ "ERROR. Falta el directorio para la opcion -d."
                fi
                DIR="$1"
                shift
                ;;
            -u)
                LISTA_USUARIOS=""
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit_ "ERROR. Falta el/los usuario/s para la opcion -u."
                fi
                while [[ "$1" != "" && "$1" != -* ]]; do
                    LISTA_USUARIOS="$LISTA_USUARIOS $1"
                    shift
                done
                ;;
            -*)
                error_exit_ "ERROR. Opcion no conocida."
                ;;
            *)
                error_exit_ "ERROR. Argumento invalido."
                ;;
        esac
    done
}



# ===================================================================
# Comprobaciones de ejecucion.
# ===================================================================

procesar_opciones_ "$@"

if ! lsof_en_path_; then
    error_exit_ "ERROR. El comando lsof no esta instalado en el path."
fi

# Si es correcto lo que se introdujo por linea de comandos, ignoramos la variable de entorno.
if [[ $OPCION_D -eq 1 ]]; then
    if ! existe_dir_ "$DIR"; then
        error_exit_ "ERROR. El directorio '$DIR' especificado en la opcion -d no existe."
    fi

# Si no se activo la opcion -d, comprobamos si la variable de entorno es no vacia y despues, si es correcta.
elif [[ "$OPEN_FILES_FOLDER" != "" ]]; then
    if ! existe_dir_ "$OPEN_FILES_FOLDER"; then
        error_exit_ "ERROR. La ruta indicada en la variable de entorno OPEN_FILES_FOLDER no existe: $OPEN_FILES_FOLDER."
    fi
    DIR="$OPEN_FILES_FOLDER"
fi

# ====================================================================
# Logica del programa principal.
# ====================================================================

main_() {

    # . Si al ejecutar el script no se especifica ninguna opción, se enviará a la salida estándar una tabla con dos columnas.
    # En la primera columna estarán los PIDs sin repeticiones de los procesos del usuario de bash (variable USER) conaperturas de archivo.
    # En la segunda columna deberás indicar el número de aperturas de archivo de ese proceso. 
    # La tabla estará ordenada por la 2 columna de forma descendente.
    

    # 2 puntos. Si el script se llama con la opción -u seguida de un número indeterminado e nombres de usuario separados por espacio,
    # el script debe modificar el comportamiento descrito en 1.c para que los procesos analizados por lsof tengan 
    # como usuario los de la lista indicada en la opción -u
    
    SORT_CMD="sort -k2,2nr"
    # Calcula los PIDs usando $LISTA_USUARIOS o $USER, dependiendo de si se activase la OPCION_U.
    PIDS=$(get_pids_usuarios_)
    if [[ "$PIDS" == "" ]]; then
        return
    fi
    printf "%-12s %s\n" "PID" "N_ARCHIVOS"
    for pid in $PIDS; do
        NUM_ARCHIVOS=$(get_num_archivos_ "$pid")
        printf "%-12s %s\n" "$pid" "$NUM_ARCHIVOS"
    done | $SORT_CMD
    
}

main_