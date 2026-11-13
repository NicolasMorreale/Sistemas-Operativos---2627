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
#include <sys/stat.h>  // Contiene la declaracion de la llamada al sistema stat(), la declaracion de struct stat
#include <fcntl.h> // Proporciona la declaración de open() y constantes para los modos y opciones de apertura (O_RDONLY, O_WRONLY, O_CREAT, O_TRUNC)
#include <unistd.h> // Necesaria para llamar a read(), write(), close()
#include <cstdlib>
#include <filesystem>
#include <system_error>


/**
 * @brief Funcion que construye el objeto std::system_error una vez y asi lo llamamos en cualquier lugar del codigo
y captura 'errno' en el instante que detecte el error.
 * 
 * @param context 
 * @return std::unexpected<std::system_error> 
 */

std::unexpected<std::system_error> system_error_from_errno(std::string context) {
     return std::unexpected(std::system_error(errno, std::system_category(), std::move(context)));
}



/**
 * @brief Funcion para comprobar las condiciones sobre el número de argumentos indicados en la línea de
comandos
 * 
 * @param argc 
 * @param argv 
 * @return true 
 * @return false 
 */

bool check_args(int argc, char* argv[]) {
     if(argc != 3) {
          std::println(stderr,"copy: se deben indicar los archivos ORIGEN y DESTINO.");
          return false;
     }
     return true;
}



/**
 * @brief Funcion para comprobar si el archivo indicado en DESTINO es un directorio
 * 
 * @param path 
 * @return true 
 * @return false 
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



/**
 * @brief Funcion para comprobar si las rutas de origen y destino conducen al mismo archivo, implementa la
     siguiente función: bool is_same_file().
 * 
 * @param src_path 
 * @param dest_path 
 * @return true 
 * @return false 
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
 * @brief Funcion copy_file, que copia lo que hay en el archivo ORIGEN en el archivo DESTINO.
 * 
 * @param src_path 
 * @param dest_path 
 * @param dst_perms 
 * @return std::expected<void, std::system_error> 
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
     // Reservamos un buffer de tamaño 128kB
     constexpr std::size_t buffer_size=131072;
     std::vector<std::uint8_t> buffer(buffer_size);
          
     while(true) {

          // Solicita leer hasta 128kB de src_fd y guardar en el buffer.
          ssize_t bytes_read = read(src_fd, buffer.data(), buffer.size());

          // Si ocurre error de lectura, se captura errno antes de cerrar los descriptores de archivos y se devuelve el error.
          if(bytes_read == -1) {
               auto error = system_error_from_errno("error al leer el archivo de ORIGEN.");
               close(src_fd);
               close(dest_fd);
               return error;
          }

          // Cuando read() devuelve 0, es porque se llego al final del archivo (EOF), por lo que finaliza el bucle de copia.
          if(bytes_read == 0) {
               break;
          }

          std::size_t total_written = 0;
          // : Convierte el número de bytes leídos de ssize_t (con signo) a size_t (sin signo),
          // para operar con tamaños de memoria e inicializa el contador de bytes escritos en este bloque.
          const auto bytes_to_write = static_cast<std::size_t>(bytes_read);
          while (total_written < bytes_to_write) {
               // Escribe a partir de la posición pendiente del búfer (buffer.data() + total_written)
               // los bytes que aún faltan (bytes_to_write - total_written)
               ssize_t bytes_written = write(dest_fd, buffer.data() + total_written, bytes_to_write - total_written);
               
               // Verificamos si hubieron errores a la hora de escribir en el archivo
               if(bytes_written == -1) {
                    auto error = system_error_from_errno("error al escribir en el archivo de DESTINO.");
                    close(src_fd);
                    close(dest_fd);
                    return error;
               }
               // Si no hubo error, acumulamos los bytes de esta iteracion
               total_written += static_cast<std::size_t>(bytes_written);
          }
     }
     // Liberamos los descriptores antes de salir de la funcion
     close(src_fd);
     close(dest_fd);
     // Devuelve un std::expected<void, std::system_error> vacío para comunicar que toda la copia se completó con éxito.
     return {};
}



/**
 * @brief Funcion principal protegida
 * 
 * @param argc 
 * @param argv 
 * @return int 
 */

int protected_main(int argc, char* argv[]) {
     if(!check_args(argc, argv)) {
          return EXIT_FAILURE;
     }

     std::string src_path = argv[1];
     std::string dest_path = argv[2];
     
     // Si son directorios, construimos las rutas.
     if(is_directory(dest_path)) {

          std::filesystem::path src(src_path);
          std::filesystem::path dest(dest_path);

          // Concatenar rutas de archivos o directorios añadiendo el separador de carpetas (/)
          dest /= src.filename();
          dest_path = dest.string();
     }

     if(is_same_file(src_path, dest_path)) {
          std::println(stderr, "copy: ORIGEN y DESTINO son el mismo archivo.");
          return EXIT_FAILURE;
     }

     auto result = copy_file(src_path, dest_path);

     // Si copy_file falla.
     if(!result.has_value()) {
          std::println(stderr, "copy: {}", result.error().what());
          return EXIT_FAILURE;
     }
     
     return EXIT_SUCCESS;
}




/**
 * @brief Funcion principal
 * 
 * @param argc 
 * @param argv 
 * @return int 
 */

int main(int argc, char* argv[]) {

     try {
          return protected_main(argc, argv);
     }
     // Tipo especifico
     catch (const std::system_error& e) {
          std::println(stderr, "copy: error inesperado ({}): {}", e.code().value(), e.what());
     }
     // Tipo mas general
     catch (const std::exception& e) {
          std::println(stderr, "copy: error inesperado: {}", e.what())
     }

     return EXIT_FAILURE;
}