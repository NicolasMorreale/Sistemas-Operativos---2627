/**
 * Universidad de La Laguna
 * Escuela Superior de Ingeniería y Tecnología
 * Grado en Ingeniería Informática
 * Asignatura: Sistemas Operativos
 * Curso: 2º
 * Autor: Nicolas Morreale Toledo
 * Correo: alu010829173@ull.edu.es
 * Fecha: 15/11/2026
**/

/**
 * @file main_copy_files.cc
 * @brief Archivo que contiene el programa principal.
 * Para compilar usar: g++-14 -std=c++23 -Wall -Wextra main_copy_files.cc copy_files.cc -o copy
*/

#include "copy_files.h"


/**
 * @brief Main protegido
    Primero, comprobamos que los argumentos sean correctos, invocando a check_args(), luego instanciamos los archivos ORIGEN y DESTINO como
    std::string, comprobamos que DESTINO sea un directorio, y si lo es,  creamos dos objetos std::filesystem::path para manipular las rutas como
    cadenas de texto.
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

    if(is_directory(dest_path)) {
        std::filesystem::path origen{src_path};
        std::filesystem::path destino{dest_path};
        destino /= origen.filename(); 
        dest_path = destino.string(); // Guarda la ruta completa resultante
    }

    if(is_same_file(src_path, dest_path)) {
        std::println(stderr, "copy: ORIGEN y DESTINO son el mismo archivo.");
        return EXIT_FAILURE;
    }

    auto result = copy_file(src_path, dest_path);
    if(!result.has_value()) {
        std::println(stderr, "copy: {}", result.error().what());
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}



/**
 * @brief Programa principal
    Llamamos a protected_main() dentro de un try, y usamos dos catch para atrapar errores y excepciones.
 * 
 * @param argc 
 * @param argv 
 * @return int 
*/

int main(int argc, char* argv[]) {
    try {
        return protected_main(argc, argv);
    } catch(const std::system_error& e) {
        std::println(stderr, "copy: error inesperado ({}): {}", e.code().value(), e.what());
    } catch(const std::exception& e) {
        std::println(stderr, "copy: error inesperado {}", e.what());
    }
    return EXIT_FAILURE;
}


