// Universidad de La Laguna
// Sistemas Operativos
// Programacion de Aplicaciones en C++
// Nombre: Nicolas Morreale Toledo
// Correo: alu0101829173@ull.edu.es
// Programa: copy_u1.cpp

#include <expected> // std::expected y std::unexpected
#include <print> // std::println()
#include <string>
#include <vector>
#include <errno.h> // declara la variable global "errno", donde el SO almacena el codigo de erro al fallar una llamada


// Contiene la declaracion de la llamada al sistema stat(), la declaracion de struct stat
#include <sys/stat.h>

// Proporciona la declaración de open()
// y las constantes para los modos y opciones de apertura (O_RDONLY, O_WRONLY, O_CREAT, O_TRUNC)
#include <fcntl.h>

// Necesarias para llamar a read(), write(), close()
#include <unistd.h>

/**
@brief Funcion que construye el objeto std::system_error una vez y asi lo llamamos en cualquier lugar del codigo
y captura 'errno' en el instante que detecte el error.
*/

std::unexpected<std::system_error> system_error_from_errno(std::string context) {
     return std::unexpected(std::system_error(errno, std::system_category(), std::move(context)));
}



/* 
@brief Funcion para comprobar las condiciones sobre el número de argumentos indicados en la línea de
comandos, implementa la siguiente función: bool check_args()
*/

bool check_args(int argc, char* argv[]) {
     if(argc != 3) {
          std::println(stderr,"copy: se deben indicar los archivos ORIGEN y DESTINO.");
          return false;
     }
     return true;
}



/*
Para comprobar si el archivo indicado en DESTINO es un directorio, implementa la siguiente
función: bool is_directory()

Esta función debe devolver true si la ruta path corresponde a un directorio y false en caso
contrario. Para comprobarlo se puede usar la función stat() descrita en la Sección A.7.
*/

bool is_directory(const std::string& path) {

     // estructura local donde el núcleo almacenará los atributos del archivo (tipo, permisos, tamaño)
     struct stat st{};

     // llamada a stat() pasandole la ruta (path) convertida a cadena de C, y la direccion de memoria de st.
     // si la llamada retorna -1, es porque no es un directorio
     if(stat(path.c_str(), &st) == -1) {
          return false;
     }

     // se usa la macro S_ISDIR para inspeccionar el campo st_mode (donde se codifican permisos, tipos de entrada)
     // y la macro devuelve verdadero si la ruta es un directorio y falso si es cualquier otro tipo de archivo.
     return S_ISDIR(st.st_mode);
}



/*
@brief Funcion para comprobar si las rutas de origen y destino conducen al mismo archivo, implementa la
siguiente función: bool is_same_file().

Esta función debe devolver true si ambas rutas corresponden al mismo archivo y false en
caso contrario, usando la técnica descrita en la Sección A.7.1.
*/

bool is_same_file(const std::string& src_path, const std::string& dest_path) {
     // Almacenamos por separado los atributos del archivo ORIGEN y el DESTINO
     struct stat src_st{};
     struct stat dest_st{};

     // Comprobacion de que las rutas sean correctas
     if(stat(src_path.c_str(), &src_st) == -1 || stat(dest_path.c_str(), &dest_st)) {
          return false;
     }

     // Comprobamos que coincidan el verificador de dispositivo
     // y el numero de inodo (que identifica de forma única a un archivo dentro de un mismo sistema de archivos.)
     return (src_st.st_dev == dest_st.st_dev) && (src_st.st_ino == dest_st.st_ino);
}



/**
@brief 
*/

std::expected<void, std::system_error> copy_file(const std::string& src_path, const std::string& dest_path,
     mode_t dst_perms = 0644) {
          // Abrimos el archivo ORIGEN
          int src_fd = open(src_path.c_str(), O_RDONLY);
          if(src_fd == -1) {
               system_error_from_errno("error al abrir el archivo ORIGEN.");
          }

          // Abrimos el archivo DESTINO
          // Siempre que se usa O_CREAT , se pasa dst_perms, por que sino se crea el archivo con permisos aleatorios
          int dest_fd = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dst_perms);
          if(dest_fd == -1) {
               auto error = system_error_from_errno("error al abrir el archivo DESTINO.");
               close(dest_fd);
               return error;
          }
          // Reservamos un buffer de tamaño 128KB
          constexpr std::size_t buffer_size=131072;
          std::vector<std::uint8_t> buffer(buffer_size);

     }