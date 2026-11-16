/**
 * Universidad de La Laguna
 * Escuela Superior de Ingeniería y Tecnología
 * Grado en Ingeniería Informática
 * Asignatura: Sistemas Operativos
 * Curso: 2º
 * Autor: Nicolas Morreale Toledo
 * Correo: alu010829173@ull.edu.es
 * Fecha: 14/11/2026
**/

/**
 * @file copy_files.h
 * @brief Contiene declaraciones de funciones e inclusiones de librerias utiles para la manipulacion y copia de archivos
 * utilizando llamadas al sistema. El cometido del programa sera copiar el contenido de un archivo ORIGEN a otro DESTINO,
 * obtenidos desde la linea de comandos, implementandolo con llamadas al sistema POSIX como open(), read() 
 * write(), stat() y close(), ademas de preveniendo los posibles errores.
 */

#ifndef COPY_FILES_H
#define COPY_FILES_H

#include <fcntl.h> // open() y O_RDONLY, O_WRONLY, O_CREAT, O_TRUNC
#include <unistd.h> // read(), write(), close()
#include <expected> // std::unexpected
#include <cstdlib> // EXIT_SUCCESS, EXIT_FAILURE
#include <print>  // std::println()
#include <sys/stat.h> // stat(), S_ISDIR(), struct stat, mode_t
#include <string> // std::string
#include <errno.h> // errno, EINTR
#include <system_error> // std::system_error, std::system_category()
#include <utility> // std::move()
#include <filesystem> // std::filesystem::path
#include <exception> // std::exception
#include <vector> // std::vector
#include <cstdint> // std::uint8_t

// Crea el objeto std::unexpected que contiene el std::system_error, empaquetando el error actual del sistema (errno) en un objeto compatible con C++23.
std::unexpected<std::system_error> system_error_from_errno(std::string context);

// Valida que el numero y tipo de argumentos recibidos por la linea de comandos sea correcto.
bool check_args(int argc, char* argv[]);

// Valida que la ruta introducida sea un directorio.
bool is_directory(const std::string& path);

// Valida si las rutas son iguales.
bool is_same_file(const std::string& src_path, const std::string& dest_path);

// Funcion que realiza todo el trabajo de copiar el contenido de ORIGEN en DESTINO.
std::expected<void, std::system_error> copy_file(const std::string& src_path, const std::string& dest_path, mode_t dest_perms = 0644,
 const std::string& log_path = "/tmp/copy_logfile");

// Modificacionpara llevar un registro de los ficheros que se han copiado y su tamaño.
std::expected<void, std::system_error> log_copied_file(const std::string& log_path, const std::string& file_path, std::size_t file_size)

#endif
