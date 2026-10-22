#!/bin/bash

# VARIABLES GLOBALES


SORT="" # -s
OFFLINE="" # -o
LISTA_USERS="" # -u
REGEX_ARCHIVO="" # -f


# Funcion para salida mostrando un error


error_exit() {
    echo "ERROR: $1" >&2
    echo "" >&2
    usage >&2
    exit 1
}


# Funcion para mostrar el uso del programa (-h | --help)


usage() {
    cat << _EOF_
Uso: open_files [-h | --help] [-f regexp] [-o] [--offline] [-u usuario...] [-s] [-sort] [--sort]

Opciones:
  -h, --help       Muestra este mensaje de ayuda y finaliza con estado 0.
  -f regexp        Filtra los archivos contados según una expresión regular en la ruta.
  -o, --offline    Muestra únicamente los usuarios no conectados al sistema.
  -u usuario...    Lista de usuarios específicos a procesar.
  -s, -sort, --sort Ordena la tabla por el número de archivos abiertos (de mayor a menor).
_EOF_
}


# 1. Funcion para procesar la linea de comandos

procesar_argumentos() {

    while [[ "$1" != "" ]]
    do
        case "$1" in
            -h | --help)
                usage 
                exit 0
                ;;
            -o | --offline)
                OFFLINE=1
                shift
                ;;
            -f | --file)
                shift
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "Falta el argumento de -f"
                fi
                REGEX_ARCHIVO="$1"
                shift
                ;;
            -u)
                shift 
                if [[ "$1" == "" || "$1" == -* ]]; then
                    error_exit "Falta el argumento de -u"
                fi
                while [[ "$1" != "" &&  "$1" != -* ]]
                do
                    LISTA_USERS="$LISTA_USERS $1"
                    shift
                done
                ;;
            -s | --sort)
                SORT=1
                shift
                ;;
            -*)
                error_exit "Opcion $1 no valida"
                ;;
            *)
                error_exit "Argumento $1 no valido"
                ;;
        esac
    done
}

# Leer parametros
procesar_argumentos "$@"



# 2. Comprobaciones

# - Comprobacion de OPEN_FILE_FOLDER (si esta definida)


# Funcion que comprueba si un directorio existe (nos interesa solo el estado de salida; 0 o 1)
existe_directorio() {

    if [[ -d "$1" ]]; then
        return 0
    else 
        return 1
    fi
}

if [[ "$OPEN_FILES_FOLDER" != "" ]]; then
    if ! existe_directorio "$OPEN_FILES_FOLDER"; then
        error_exit "La ruta OPEN_FILES_FOLDER no existe o no es un directorio: $OPEN_FILES_FOLDER."
    fi
fi


# - Comprobacion de si lsof esta instalado 


lsof_instalado() {
    type lsof > /dev/null 2> /dev/null
}

if ! lsof_instalado; then
    error_exit "No esta instalado el comando lsof."
fi


# - Comprobacion de que los usuarios existan


# Funcion que comprueba si un usuario existe (nos interesa solo el estado de salida; 0 o 1)
existe_usuario() {
    id "$1" > /dev/null 2> /dev/null
}

for users in $LISTA_USERS; do
    if ! existe_usuario "$users"; then
        # Usamos comillas simples ('') para que cuando se imprima se vea el nombre de usuario entre comillas simples, no por sintaxis
        error_exit "El usuario '$users' no existe en el sistema."
    fi
done

# 3. Logica del programa