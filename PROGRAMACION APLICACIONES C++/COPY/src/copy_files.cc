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
 * @file copy_files.cc
 * @brief Contiene las definiciones de las funciones declaradas en el fichero copy_files.h
 * 
 */

#include "copy_files.h"


/**
 * @brief Genera un objeto std::unexpected que contiene el std::system_error, empaquetando el error actual del sistema (errno), variable global
 * que adquiere un valor cuando falla una llamada al sistema, junto a un mensaje de error
 * personalizado para utilizarse en diferentes casos.
 * 
 * @param context Cadena de texto que describe donde, como o porque surgio el error.
 * @return std::unexpected<std::system_error> Objeto inesperado con el codigo de error.
 */

std::unexpected<std::system_error> system_error_from_errno(std::string context) {
    return std::unexpected(std::system_error(errno, std::system_category(), std::move(context)));
}



/**
 * @brief Realiza los siguientes pasos:
    1. Comprueba que se hayan pasado exactamente 3 argumentos por la linea de comandos (ejecutable, ORIGEN, DESTINO).
    2. Si no se introdujo correctamente, retorna false.
    3. En caso de exito, retorna true.
 * 
 * @param argc Numero de argumentos en la linea de comandos (contando el nombre del ejecutable).
 * @param argv Array con los argumentos introducidos por linea de comandos (contando con el nombre del ejecutable).
 * @return true 
 * @return false 
 */

bool check_args(int argc, char* argv[]) {
    if(argc != 3) {
        std::println(stderr, "copy: se deben indicar los archivos ORIGEN y DESTINO.");
        return false;
    }
    return true;
}



/**
 * @brief Valida si la ruta especificada es un directorio
    Declara la estructura struct stat st{} para invocar a 
    la llamada a la funcion del sistema stat() y usa la macro S_ISDIR()
    y luego, si stat() tuvo exito, devolver la macro pasandole el campo
    st_mode, donde esta el tipo de archivo, que retornara true si es un
    directorio
    
 * 
 * @param path Cadena de texto que contiene la ruta del directorio a comprobar
 * @return true 
 * @return false 
 */

bool is_directory(const std::string& path) {
    struct stat st {};
    if(stat(path.c_str(), &st) == -1) {
        return false;
    }
    return S_ISDIR(st.st_mode);
}



/**
 * @brief Valida si las rutas especificadas coinciden
    Declara las estructuras src_st y dest_st inicializadas a cero, donde el sistema operativo
    almacenara los atributos del archivo ORIGEN y DESTINO, luego invoca
 la llamada al sistema stat() para cada ruta, consultando los metadatos de los archivos y comprueba si falla, en ese caso, retorna false,
    y en caso de exito, comprueba si coinciden el identificador de dispositivo (st_dev) y el numero de nodo (st_ino) de ambos archivos.
 * 
 * @param src_path 
 * @param dest_path 
 * @return true Si nada coincide y no hay errores
 * @return false En caso contrario
 */

bool is_same_file(const std::string& src_path, const std::string& dest_path) {
    struct stat src_st{};
    struct stat dest_st{};

    if(stat(src_path.c_str(), &src_st) == -1 || stat(dest_path.c_str(), &dest_st) == -1) {
        return false;
    }
    return (src_st.st_dev == dest_st.st_dev) && (src_st.st_ino == dest_st.st_ino);
}




/**
 * @brief Copia el contenido del archivo ORIGEN en el archivo DESTINO.
    Primero, abre los descriptores de ORIGEN y DESTINO con open(), el de ORIGEN lo abre solo con el permiso de lectura O_RDONLY,
    y comprueba que se haya abierto exitosamente. Luego, el de DESTINO lo abre con mas permisos.

    Luego, creamos un buffer de 128kB y con bucle empezaremos a leer el fichero de ORIGEN, comprobamos que no hayan errores, y cuando
    bytes_read sea 0, hemos alcanzado el final del archivo, parara nuestro bucle while(true).

    Convertimos a entero sin signo el bytes_to_write, ya que no necesitamos leer mas ningun -1. Creamos una variable que sirva de contador para saber 
    cuantos bytes hemos leido y otra donde vayamos a escribir, llamando a la funcion del sistema write(). Capturamos los errores y cerramos los archivos
    en caso de fallo, mientras que en caso de exito, actualizamos el contador de bytes totales. Finalmente, cerramos los descriptores y retornamos.


 * 
 * @param src_path 
 * @param dest_path 
 * @param dest_perms 
 * @return std::expected<void, std::system_error> 
 */

std::expected<void, std::system_error> copy_file(const std::string& src_path, const std::string& dest_path, mode_t dest_perms) {
    int src_fd = open(src_path.c_str(), O_RDONLY);
    if(src_fd == -1) {
        return system_error_from_errno("ERROR al abrir el fichero ORIGEN.");
    }

    int dest_fd = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dest_perms);
    if(dest_fd == -1) {
        auto error = system_error_from_errno("ERROR al abrir el fichero DESTINO.");
        close(src_fd);
        return error;
    }

    constexpr std::size_t buffer_size(128*1024);
    std::vector<std::uint8_t> buffer(buffer_size);

    while(true) {

        ssize_t bytes_read = read(src_fd, buffer.data(), buffer.size());
        if(bytes_read == -1) {
            if(errno == EINTR) continue; // No es error, sino interrupcion por la llamada al sistema
            auto error = system_error_from_errno("ERROR al leer el archivo ORIGEN.");
            close(src_fd);
            close(dest_fd);
            return error;
        }

        if(bytes_read == 0) break; // EOF

        std::size_t total_written = 0;
        const auto bytes_to_write = static_cast<std::size_t>(bytes_read);

        while(total_written < bytes_to_write) {

            ssize_t written = write(dest_fd, buffer.data() + total_written, bytes_to_write - total_written);
            if(written == -1) {
                if(errno == EINTR) continue; // No es error, sino interrupcion por la llamada al sistema
                auto error = system_error_from_errno("ERROR al escribor en el archivo DESTINO.");
                close(src_fd);
                close(dest_fd);
                return error;
            }
            total_written += static_cast<std::size_t>(written);
        }
    }

    close(src_fd);
    close(dest_fd);
    return {};
}