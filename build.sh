#!/bin/bash
# Build script for LLVM Fuzzing Project
# Usage: ./build.sh [clean]

set -e

# Fix: Use single dirname instead of double dirname
PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
BUILD_DIR="$PROJECT_ROOT/build"

echo "🚀 Building LLVM Fuzzing Project..."
echo "Project root: $PROJECT_ROOT"
echo "Build directory: $BUILD_DIR"

# Функция для очистки
clean_build() {
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Функция для проверки зависимостей
check_dependencies() {
    echo "🔍 Checking dependencies..."
    
    if ! command -v clang &> /dev/null; then
        echo "❌ clang not found. Please install LLVM/Clang."
        exit 1
    fi
    
    if ! command -v llvm-config &> /dev/null; then
        echo "❌ llvm-config not found. Please install LLVM development packages."
        exit 1
    fi
    
    if ! command -v cmake &> /dev/null; then
        echo "❌ cmake not found. Please install CMake."
        exit 1
    fi
    
    echo "✅ All dependencies found"
    echo "   - Clang: $(clang --version | head -n1)"
    echo "   - LLVM: $(llvm-config --version)"
    echo "   - CMake: $(cmake --version | head -n1)"
}

# Функция для сборки проекта
build_project() {
    echo "🔨 Building project..."
    
    cd "$BUILD_DIR"
    cmake "$PROJECT_ROOT" -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    
    echo "✅ Build completed successfully!"
}

# Функция для создания тестовых данных
create_test_data() {
    echo "📄 Creating test data..."
    
    # Создаем простой C файл для тестирования
    cat > "$PROJECT_ROOT/tests/test_functions.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int add(int a, int b) {
    return a + b;
}

int vulnerable_function(int a, int b) {
    if (a == 0xDEADBEEF && b == 0xCAFEBABE) {
        // Искусственная уязвимость для демонстрации
        int *p = NULL;
        *p = 42; // Crash!
    }
    return a + b;
}

int main() {
    printf("Test functions compiled successfully!\n");
    return 0;
}
EOF
    
    # Компилируем в LLVM IR
    clang -emit-llvm -S "$PROJECT_ROOT/tests/test_functions.c" -o "$PROJECT_ROOT/tests/test_functions.ll"
    
    echo "✅ Test data created"
}

# Функция для запуска тестов
run_tests() {
    echo "🧪 Running basic tests..."
    
    # Тест базового LLVM примера
    echo "Testing LLVM example..."
    "$BUILD_DIR/llvm_example" > /tmp/llvm_output.txt
    if grep -q "define i32 @add" /tmp/llvm_output.txt; then
        echo "✅ LLVM example test passed"
    else
        echo "❌ LLVM example test failed"
        exit 1
    fi
    
    # Тест LLVM Pass
    echo "Testing LLVM Pass..."
    if [ -f "$BUILD_DIR/libCountInstructions.so" ]; then
        opt -load "$BUILD_DIR/libCountInstructions.so" -countinsts < "$PROJECT_ROOT/tests/test_functions.ll" > /dev/null 2>&1
        echo "✅ LLVM Pass test passed"
    else
        echo "❌ LLVM Pass library not found"
        exit 1
    fi
    
    echo "✅ All tests passed!"
}

# Основная логика
main() {
    check_dependencies
    
    if [ "$1" = "clean" ]; then
        clean_build
    elif [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
    fi
    
    # Создаем необходимые директории
    mkdir -p "$PROJECT_ROOT/tests"
    mkdir -p "$PROJECT_ROOT/reports"
    
    create_test_data
    build_project
    run_tests
    
    echo ""
    echo "🎉 Build completed successfully!"
    echo "📁 Executables are in: $BUILD_DIR"
    echo "🚀 Run './scripts/run_fuzzing.sh' to start fuzzing"
}

main "$@"
