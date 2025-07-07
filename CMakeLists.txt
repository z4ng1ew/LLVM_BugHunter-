cmake_minimum_required(VERSION 3.10)
project(LLVMFuzzingProject)

# Принудительно использовать Clang для фаззинга
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Найти LLVM
find_package(LLVM REQUIRED CONFIG)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")

# Добавить LLVM definitions и include directories
add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})

# Получить LLVM libraries
llvm_map_components_to_libnames(llvm_libs support core irreader)

# Создать библиотеку для LLVM Pass (ТОЛЬКО ОДИН РАЗ!)
add_library(CountInstructions MODULE src/CountInstructions.cpp)
# Используем либо явные библиотеки, либо llvm_libs - но не оба варианта
target_link_libraries(CountInstructions ${llvm_libs})

# Создать исполняемый файл для основного примера
add_executable(llvm_example examples/llvm_example.cpp)
target_link_libraries(llvm_example ${llvm_libs})

# Создать исполняемый файл для фаззинга (только с Clang)
add_executable(fuzz_target examples/fuzz_target.cpp)
target_compile_options(fuzz_target PRIVATE -fsanitize=fuzzer,address)
target_link_options(fuzz_target PRIVATE -fsanitize=fuzzer,address)

# Создать расширенный пример фаззинга (только с Clang)
add_executable(advanced_fuzzing advanced_fuzzing.cpp)
target_compile_options(advanced_fuzzing PRIVATE -fsanitize=fuzzer,address,undefined)
target_link_options(advanced_fuzzing PRIVATE -fsanitize=fuzzer,address,undefined)

# Установка
install(TARGETS llvm_example fuzz_target advanced_fuzzing
        RUNTIME DESTINATION bin)
install(TARGETS CountInstructions
        LIBRARY DESTINATION lib)
