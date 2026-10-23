#!/bin/bash

# Variables


SORT="" # -s
OFFLINE="" # -o
LISTA_USERS="" # -u
REGEX="" # -f
DIR="${OPEN_FILES_FOLDER:-""}"


# Funciones
# Funcion que muestra el error por la salida de error
error_exit() {
    echo "ERROR: $1" >&2
    echo "" >&2
    usage >&2
    exit 1
}


# Funcion que muestra el uso del script
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


# Funcion que comprueba si un directorio existe (nos interesa solo el estado de salida; 0 o 1)
existe_directorio() {

    if [[ -d "$1" ]]; then
        return 0
    else 
        return 1
    fi
}


# Funcion que comprueba si un usuario existe (nos interesa solo el estado de salida; 0 o 1)
existe_usuario() {
    id "$1" > /dev/null 2> /dev/null
}


# Funcion que obtiene la id de un usuario
get_id_usuario() {
    id -u "$1" 2> /dev/null
}


# Funcion que comprueba si el comando lsof esta instalado en el sistema
lsof_instalado() {
    type lsof > /dev/null 2> /dev/null
}


# Funcion que obtiene la cantidad de archivos abiertos en funcion de los datos que tengamos
get_open_files() {
    if [[ "$DIR" != "" && "$REGEX" != "" ]]; then
        lsof -u "$1" -a +D "$DIR" 2> /dev/null | awk -v regexpr="$REGEX" 'NR > 1 && $5 == "REG" && $9 ~ regexpr' | wc -l
    elif [[ "$DIR" != "" ]]; then
        lsof -u "$1" -a +D "$DIR" 2> /dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
    elif [[ "$REGEX" != "" ]]; then
        lsof -u "$1" 2> /dev/null | awk -v regexpr="$REGEX" 'NR > 1 && $5 == "REG" && $9 ~ regexpr' | wc -l 
    else 
        lsof -u "$1" 2> /dev/null | awk 'NR >1 && $5 == "REG"' | wc -l
    fi
}


# Funcion que procesa los argumentos recibidos por la linea de comandos
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
                REGEX="$1"
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
            -s | -sort | --sort)
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


# ===============================================================================================
# 2. Comprobaciones de ejecucion
# ===============================================================================================


if [[ "$DIR" != "" ]]; then
    if ! existe_directorio "$DIR"; then
        error_exit "El directorio de la variable de entorno $DIR no existe o no es un directorio."
    fi
fi



if ! lsof_instalado; then
    error_exit "No esta instalado el comando lsof."
fi


# - Comprobacion de que los usuarios existan

for users in $LISTA_USERS; do
    if ! existe_usuario "$users"; then
        # Usamos comillas simples ('') para que cuando se imprima se vea el nombre de usuario entre comillas simples, no por sintaxis
        error_exit "El usuario '$users' no existe en el sistema."
    fi
done


# ======================================================================================================================================
# 3. Logica del programa
# ======================================================================================================================================


main() {

    USUARIOS_ONLINE=""
    # - Obtenemos usuarios conectados
    if [[ "$OFFLINE" == "1" ]]; then
        USUARIOS_ONLINE=$(who | cut -d' ' -f1 | sort | uniq)
    fi

    ARGUMENTOS_LSOF=""
    # - Obtenemos argumentos para lsof
    if [[ "$OPEN_FILES_FOLDER" != "" ]]; then
        ARGUMENTOS_LSOF="+D $OPEN_FILES_FOLDER"
    fi

    # - Ejecutamos el comando 'lsof' con los argumentos que acabamos de obtener
    DATOS=$(lsof $ARGUMENTOS_LSOF 2> /dev/null | tail -n +2 | while read -r cmd pid user fd type device size node name; do

    # Filtro 1: Ignorar aquellos que no sean regulares (directorios, etc)
    if [[ "$type" != "REG" ]]; then
        continue
    fi

    # Filtro 2: (-o | --offline) Ignorar usuarios conectados
    if [[ "$OFFLINE" == "1" ]] && [[ " $USUARIOS_ONLINE " == *" $user "* ]]; then
        continue
    fi

    # Filtro 3: (-u | --user) Solo usuarios indicados
    if [[ "$LISTA_USERS" != "" ]] && [[ " $LISTA_USERS " != *" $user"* ]]; then
        continue
    fi

    # Filtro 4: (-f | --file) Comprobar que la ruta del fichero es correcta
    if [[ "$REGEX" != "" ]] && [[ ! "$name" =~ $REGEX ]]; then # no ponemos comillas en $REGEX_ARCHIVO para funcione como exp regular
        continue
    fi

    done)

}