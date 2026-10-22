#!/bin/bash

# SCRIPT PARA PRACTICAR OTROS COMANDOS Y FUNCIONES
TITLE="Script para practicar funciones"






# Funcion que muestra archivos de mas de un cierto tamaño ordenados en orden descendente, segun su tamaño
check_large_files() {
	echo
	echo -e "TAMAÑO\tARCHIVO"
	if [ "$USER" == "root" ]; then
		find /var/log/ -type f -size +1M -exec du -h {} + | sed 's|/var/log||' | sort -hr
	else 
		find "$HOME" -type f -size +10M -exec du -h {} + | sed "s|$HOME/||" | sort -hr
	fi
}





proc_monitor() {
	echo
	if [ "$USER" == "root" ]; then
		echo -e "PROCESOS\tUSUARIO"
		ps -eo user= | sort | uniq -c | awk '{print $1 "\t" $2}' | sort -nr
	else
		echo -e "TOP 5 PROCESOS QUE MAS MEMORIA RAM ESTAN CONSUMIENDO DE MI USUARIO"
	       	ps -u $USER -o %mem,pid,cmd | sort -nr | head -n 5	
	fi
}





disk_alert() {
	# Si el usuario es root
	if [ "$USER" == "root" ]; then

		echo -e "SISTEMA\tPORCENTAJE\tESTADO"
		# tail -n +2 significa que ignore la primera fila
		# usamos el while read para ir leyendo linea a linea lo que sale del df -h
		df -h | tail -n +2 | while read -r sistema tam usados disp porc montado; do
		porcentaje_num = $(echo "$porc" | tr -d '%')

		if [ "$porcentaje_num" -gt 80 ]; then 
			echo -e "$sistema\t$porc\t\t[ALERTA]"
		else 
			echo -e "$sistema\t$porc\t\t[OK]"
		fi
		done
	# Si no es root
	fi
}




mem_status() {
	echo "Estado de la memoria RAM del sistema"
	local linea_mem=$(free -m | grep "Mem:" | sed 's/^ *//' | tr -s " ")
	total=$( echo "$linea_mem" | cut -d" " -f2) 	
	usado=$( echo "$linea_mem" | cut -d" " -f3)
	# TAMBIEN ES VALIDO LO SIGUIENTE::
	# free -m | head -n 2 | tail -n 1 | tr -s " " | cut -d" " -f2)
	# free -m | head -n 2 | tail -n 1 | tr -s " " | cut -d" " -f3)
	libre=$(( total - usado ))
	porcentaje=$(( (usado*100) / total )) # Multiplicamos primero por 100 para que la division entera no de 0

	echo "Cantidad total de memoria RAM: $total MB"
	echo "Cantidad usada de memoria RAM: $usado MB"
	echo "Cantidad libre de memoria RAM: $libre MB"
	echo "Porcentaje de uso de la memoria RAM: $porcentaje %"

       	if [[ "$porcentaje" -gt 80 ]]; then
		echo "ALERTA. El porcentaje de consumo de la memoria RAM es superior al 80%."
	fi	
}




# Funcion que acepta el nombre de un servicio como parametro (ssh, cron, systemd-resolved) y comprueba si esta activo o detenido.
# Si el servicio no existe o no se pasa ningun argumento, mostrar error.
check_service() {
	# 1. Si no se pasaron argumentos
	if [[ $# -eq 0 ]]; then
		echo "ERROR. No se han proporcionado argumentos por la linea de comandos."
	else 
		# Dara 0 si esta activo y en ejecucion y cualquier otro numero en otro caso
		service "$1" status >/dev/null 2>&1
		local codigo_salida=$?
		if [[ $codigo_salida -eq 0 ]]; then
			echo "El servicio '$1' esta ACTIVO."
		else
			echo "El servicio '$1' esta INACTIVO."
		fi
	fi
}



# Funcion que solicita a usuario una ruta de directorio y un tamaño minimo en MB. 
# La función debe encontrar y listar los 5 archivos más grandes dentro de esa carpeta que superen dicho tamaño,
# mostrando el tamaño exacto y el nombre de cada archivo ordenados de mayor a menor.
find_big_files() {
	echo -n "Introduzca una ruta de directorio donde buscar los archivos: "
	read ruta_directorio
	if [[ ! -d "$ruta_directorio" ]]; then
		echo "ERROR. La ruta '$ruta_directorio' no existe o no es un directorio."
		return 1
	fi

	echo -n "Introduzca un tamaño minimo de archivo en MB: "
	read min_size
	if [[ "$min_size" == "" || ! "$min_size" =~ ^[0-9]+$ ]]; then
		echo "ERROR. El tamaño introducido es incorrecto."
		return 1
	fi

	resultado=$(find "$ruta_directorio" -type f -size +"$min_size"M | xargs du -m | sort -nr | head -n 5)
	if [[ "$resultado" == "" ]]; then
		echo "No se han encontrado archivos que superen los {$min_size} MB."
	else 
		echo "$resultados" | while read -r tam_archivo nombre; do
			echo "- $nombre -> $tam_archivo MB."
		done
	fi
}





# Funcion que obtenga la direccion IP privada del equipo y compruebe la conectividad a Internet enviando un único paquete de prueba a un servidor externo
# (por ejemplo, 8.8.8.8). Debe mostrar un mensaje indicando si la conexión está activa o si el equipo se encuentra sin red.
network_diagnos() {
	echo "Funcion que comprueba la conectividad a Internet del equipo"
	
	ip_privada=$(hostname -I)
	echo "Direccion IP privada del equipo: $ip_privada"

	if ping -c 1 -w 2 8.8.8.8 >/dev/null 2>&1; then
		echo "Estado de conexion a internet: ACTIVA"
	else
		echo "Estado de conexion a internet: INACTIVA"
	fi
}





# Funcion que scanee el directorio temporal del usuario (carpeta llamada temporal) buscando archivos con extension .tmp,
# debe mostrar el numero total de archivos y el espacio que ocupan
# y debe pedir confirmacion al usuario (S/N) antes de borrarlos.
clean_tmp() {
	numero_total_archivos=$(find temporal/ -type f -name "*.tmp" | wc -l)
	espacio_total_archivos=$(find temporal/ -type f -name "*.tmp" -exec du -ch {} + | tail -n 1 | tr '\t' ' ' | cut -d' ' -f1)
	echo "Numero total de archivos: $numero_total_archivos"
	echo "Espacio total ocupado: $espacio_total_ocupado"
		
}




# PROGRAMA PRINCIPAL
cat << _EOF_
$TITLE
$(network_diagnos)
_EOF_
#echo -n "Introduzca el nombre del servicio a consultar: "
#read servicio
#check_service "$servicio"
