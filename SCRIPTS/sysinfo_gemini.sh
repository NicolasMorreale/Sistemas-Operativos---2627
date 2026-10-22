#!/bin/bash

# PRACTICA DE SSOO

##### Constantes

TITLE="Información del sistema para $HOSTNAME"
RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="Actualizada el $RIGHT_NOW por $USER"

#### Variables que uso en las funciones
interactivo=""
filename="$HOME/sysinfo.txt"
mostrar_procesos=0  # Variable para controlar si se especificó la opción -c

##### Estilos

TEXT_BOLD=$'\x1b[1m'
TEXT_GREEN=$'\x1b[32m'
TEXT_RESET=$'\x1b[0m'
TEXT_ULINE=$'\x1b[4m'

##### Funciones

system_info()
{
	echo
	echo "${TEXT_ULINE}Version del sistema${TEXT_RESET}"
	uname -a
}

show_uptime()
{
	echo
	echo "${TEXT_ULINE}Tiempo encendido del sistema${TEXT_RESET}" 
	uptime
}

drive_space()
{	
	echo
	echo "${TEXT_ULINE}Espacio ocupado por particiones o discos duros del sistema${TEXT_RESET}"
	df
}

home_space()
{
	echo
	echo -e "${TEXT_ULINE}USADO\tDIRECTORIO${TEXT_RESET}"

	if [ "$USER" == "root" ]; then
		du -s /home/* | sort -nr | sed 's|/home/||'
	else
		du -s /home/$USER | sed "s|\t.*|\t$USER|"
	fi
}

procesos_usuario() {
	echo -e "\n${TEXT_ULINE}USUARIOS\tPROCESOS${TEXT_RESET}"
	usuarios=$(cut -d":" -f1 /etc/passwd)
	for usuario in $usuarios; do
		numero_procesos=$(ps -u "$usuario" 2>/dev/null | tail -n +2 | wc -l)
		echo -e "$usuario\t$numero_procesos"	
	done
}

#### Plantilla del informe
write_page() {
	cat << _EOF_
$TEXT_BOLD$TITLE$TEXT_RESET
$TEXT_GREEN$TIME_STAMP$TEXT_RESET

$(system_info)

$(show_uptime)		

$(drive_space)

$(home_space)
_EOF_

	# Si el usuario pasó la opción -c, añadimos la tabla de procesos
	if [[ "$mostrar_procesos" == 1 ]]; then
		procesos_usuario
	fi
}

usage() {
    echo "Uso: script_ssoo.sh [-f archivo] [-i] [-h] [-c]"
    echo "  -f  Específica el archivo donde guardar el informe."
    echo "  -i  Ejecuta el script en modo interactivo."
    echo "  -h  Muestra este mensaje de ayuda."
    echo "  -c  Muestra los procesos que tiene cada usuario."
}

actividad3_procesar_opciones() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f|--file)
				shift
				filename="$1"
				;;
			-i|--interactive)
				interactivo=1
				;;
			-h|--help)
				usage
				exit 0
				;;
			-c)
				mostrar_procesos=1
				;;
			*)
				echo "Opcion no valida: $1"
				exit 1
				;;
		esac
		shift # Avanza al siguiente argumento
	done
}

actividad4_interactivo() {
	# 1. Preguntamos si quiere que se muestre el informe por pantalla
	echo -n "Mostrar el informe del sistema en pantalla (S/N): "
	read respuesta_mostrar
	if [[ "$respuesta_mostrar" == "S" || "$respuesta_mostrar" == "s" ]]; then
		filename="" # Vaciamos la variable que contiene la ruta del archivo

	# 2. Si no se muestra por pantalla, a un archivo
	else 
		echo -n "Introduzca el nombre del archivo [$filename]: "
		read nuevo_nombre

		if [[ "$nuevo_nombre" != "" ]]; then
			filename="$nuevo_nombre"
		fi

		# 3. Comprobacion de que exista el archivo
		if [[ -f "$filename" ]]; then
			echo -n "El archivo $filename existe. ¿Desea sobreescribirlo? (S/N): "
			read respuesta_sobreescribir

			if [[ "$respuesta_sobreescribir" != "S" && "$respuesta_sobreescribir" != "s" ]]; then
				echo "Operacion cancelada."
				exit 0
			fi
		fi
	fi
}

# ==================
# Programa principal
# ==================

# Llamamos a la funcion pasandole todos los argumentos de la linea de comandos
actividad3_procesar_opciones "$@"

# Si el usuario activo el modo interactivo, llamamos a la funcion
if [[ "$interactivo" == 1 ]]; then
	actividad4_interactivo
fi

# Comprobamos si el usuario quiso mostrar por pantalla o a un fichero y lo hacemos
if [[ "$filename" == "" ]]; then
	write_page
else
	write_page > "$filename"
	echo "Informe guardado con éxito en $filename"
fi
