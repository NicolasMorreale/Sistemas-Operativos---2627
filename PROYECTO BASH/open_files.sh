#!/bin/bash
# CLASE PROBLEMAS: VIERNES, 16 OCTUBRE 2026

# open_files -s -u jjtoledo dabreu -f archivo.txt

# Procesar la linea de comandos (descrubir que opciones me pasan)
# - 1. definir una variable para cada opcion que soporta mi programa
SORT=0
USERS=""
FILENAME=""

while [[ "$1" != "" ]]
do
    case "$1" in
        -s | --sort )
            SORT=1
        ;;
        -f | --file )
            # Por si pone la opcion -f y se olvida el nombre del fichero despues
            if [[ $2 == "" || $2 == -* ]]; then
                echo "ERROR. No se ha ingresado el nombre del fichero."
                exit 1
                # Usar funcion error_exit "Falta el argumento de $1"
            fi
            FILENAME=$2
            shift
            ;;
        -u | --user )
            if [[ $2 == "" || $2 == -* ]]; then
                echo "ERROR. Falta el argumento de $1"
                exit 
            fi
            # Usamos una especie de lista para tomar todos los usuarios introducidos
            while [[ $2 != "" || $2 != -* ]] 
            do
            USERS="$USERS $2"
            shift
            done
            ;;
        # Cualquier otra opcion -ALGO que no tenga yo programada
        -* )
            echo "Opcion $1 desconocida"
            exit 1
            ;;
        * )
            echo "Argumento invalido"
            exit 1
            ;;
    esac
    shift
done

# Comprobacion

# - directorio existe ?
directorio_existe() {
    if [[ -d "$1"]]; then
        return 0
    else 
        return 1
    fi
}

if ! directorio_existe $DIR; then
    error_exit "El directorio $DIR no existe"
fi


# - lsof instalado ?
lsof_esta_instalado() {
    # Solo interesa el estado de salida ($?), para luego la llamada, por eso ignoramos todo el texto
    type lsof > /dev/null 2> /dev/null
}

if ! lsof_esta_instalado; then
    error_exit "lsof no esta instalado."
fi

get_id_usuario() {
    id "$1" 2> /dev/null
}

# - los usuarios existen ?
usuario_existe() {
    # Solo interesa estado de salida ($?)
    id "$1" > /dev/null 2> /dev/null
}

for users in $USERS; do
    if ! usuario_existe $user; then
        error_exit "El usuario $1 no existe."
    fi
    ID_USUARIO=$(get_id_usuario $user)
done

# - el archivo existen ?
# - las opciones son compatibles ?



# Logica del programa

# Para la salida  --> printf
SORT_CMD= "sort -k1,1" # ponemos 1,1 para que ordene solo la primera (desde la 1 a la 1)
FORMATO="%s %s %s %s\n"

# Para ordenar numericamente segun la 4ta columna (PID) en caso de que activen la opcion -s (SORT=1)
if [[ $SORT == 1 ]]; then
    SORT_CMD="sort -k4,4n"
fi

printf "$FORMATO" USUARIO UID PID_ANTIGUO N_ARCHIVOS
for user in $USERS
do
    printf "$FORMATO" $user $(get_id_usuario $user) $(get_pid_antiguo $user) $(get_archivos_abiertos $user)
# Esto nos permite , la salida del for se la enchufa al sort, y lo ordena
done | $SORT_CMD 

# ps -u user -o pid --no-header --sort=user 
# lsof -u user --> Los ficheros abiertos por el usuario user
# lsof +D /ruta -> Los ficheros abiertos en el directorio /ruta
# lsof -u user -a +D /ruta -> Los ficheros de user en directorio ruta, el -a es para hacer un AND y que se cumplan ambas condiciones a la vez
# lsof -u user -a +D /ruta | wc -l -> Numero de ficheros que tiene el usuario user en el directorio ruta



