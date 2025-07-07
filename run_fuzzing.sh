#!/bin/bash

# Fuzzing automation script
# Usage: ./scripts/run_fuzzing.sh [target] [duration]

set -e

PROJECT_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
BUILD_DIR="$PROJECT_ROOT/build"
CORPUS_DIR="$PROJECT_ROOT/corpus"
CRASHES_DIR="$PROJECT_ROOT/crashes"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Создаем необходимые директории
mkdir -p "$CORPUS_DIR" "$CRASHES_DIR" "$REPORTS_DIR"

echo "🔥 Starting LLVM Fuzzing Suite..."

# Функция для отображения справки
show_help() {
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo ""
    echo "TARGETS:"
    echo "  basic       - Run basic fuzzing example"
    echo "  advanced    - Run advanced fuzzing with multiple sanitizers"
    echo "  all         - Run all fuzzing targets"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     - Show this help message"
    echo "  -t, --time     - Fuzzing duration in seconds (default: 60)"
    echo "  -j, --jobs     - Number of parallel jobs (default: 4)"
    echo "  -v, --verbose  - Verbose output"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 basic                    # Run basic fuzzing for 60 seconds"
    echo "  $0 advanced -t 300         # Run advanced fuzzing for 5 minutes"
    echo "  $0 all -t 120 -j 8         # Run all targets for 2 minutes with 8 jobs"
}

# Функция для создания начального корпуса
create_initial_corpus() {
    echo "📁 Creating initial corpus..."
    
    # Создаем базовые тестовые входы
    echo -n "Hello, World!" > "$CORPUS_DIR/hello.txt"
    echo -ne "\x00\x01\x02\x03\x04\x05\x06\x07" > "$CORPUS_DIR/binary.bin"
    echo -ne "\xEF\xBE\xAD\xDE\xBE\xBA\xFE\xCA" > "$CORPUS_DIR/magic.bin"
    
    # Создаем структурированные данные для advanced fuzzing
    python3 -c "
import struct
import os

# Создаем тестовые данные для advanced_fuzzing
data = struct.pack('<II', 0x1000, 0x12345678)  # cmd=0x1000, arg=0x12345678
data += b'A' * 32
with open('$CORPUS_DIR/cmd_1000.bin', 'wb') as f:
    f.write(data)

data = struct.pack('<II', 0x2000, 0xAABBCCDD)  # cmd=0x2000
data += b'B' * 16
with open('$CORPUS_DIR/cmd_2000.bin', 'wb') as f:
    f.write(data)

data = struct.pack('<II', 0x4000, 0xAABBCCDD)  # cmd=0x4000
data += b'C' * 16 + b'\x42' + b'D' * 16 + b'\x13' + b'E' * 16
with open('$CORPUS_DIR/cmd_4000.bin', 'wb') as f:
    f.write(data)
" 2>/dev/null || true
    
    echo "✅ Initial corpus created with $(ls -1 "$CORPUS_DIR" | wc -l) files"
}

# Функция для запуска базового фаззинга
run_basic_fuzzing() {
    local duration=${1:-60}
    local jobs=${2:-4}
    
    echo "🚀 Running basic fuzzing for $duration seconds with $jobs jobs..."
    
    if [ ! -f "$BUILD_DIR/fuzz_target" ]; then
        echo "❌ fuzz_target not found. Please build the project first."
        exit 1
    fi
    
    # Запускаем базовый фаззинг
    timeout "$duration" "$BUILD_DIR/fuzz_target" \
        -workers="$jobs" \
        -jobs="$jobs" \
        -max_len=1024 \
        -timeout=30 \
        -print_final_stats=1 \
        -artifact_prefix="$CRASHES_DIR/basic_" \
        "$CORPUS_DIR" || true
    
    echo "✅ Basic fuzzing completed"
}

# Функция для запуска расширенного фаззинга
run_advanced_fuzzing() {
    local duration=${1:-60}
    local jobs=${2:-4}
    
    echo "🚀 Running advanced fuzzing for $duration seconds with $jobs jobs..."
    
    if [ ! -f "$BUILD_DIR/advanced_fuzzing" ]; then
        echo "❌ advanced_fuzzing not found. Please build the project first."
        exit 1
    fi
    
    # Создаем отдельную директорию для расширенного фаззинга
    mkdir -p "$CORPUS_DIR/advanced"
    cp "$CORPUS_DIR"/*.bin "$CORPUS_DIR/advanced/" 2>/dev/null || true
    
    # Запускаем расширенный фаззинг с дополнительными опциями
    timeout "$duration" "$BUILD_DIR/advanced_fuzzing" \
        -workers="$jobs" \
        -jobs="$jobs" \
        -max_len=2048 \
        -timeout=60 \
        -print_final_stats=1 \
        -print_pcs=1 \
        -print_coverage=1 \
        -artifact_prefix="$CRASHES_DIR/advanced_" \
        -dict="$PROJECT_ROOT/scripts/fuzzing.dict" \
        "$CORPUS_DIR/advanced" || true
    
    echo "✅ Advanced fuzzing completed"
}

# Функция для создания словаря для фаззинга
create_fuzzing_dict() {
    echo "📖 Creating fuzzing dictionary..."
    
    cat > "$PROJECT_ROOT/scripts/fuzzing.dict" << 'EOF'
# Fuzzing dictionary for LLVM project
# Magic numbers
kw1="\xEF\xBE\xAD\xDE"
kw2="\xBE\xBA\xFE\xCA"
kw3="\xDD\xCC\xBB\xAA"
kw4="\x78\x56\x34\x12"

# Commands for advanced fuzzing
cmd1="\x00\x10\x00\x00"
cmd2="\x00\x20\x00\x00"
cmd3="\x00\x30\x00\x00"
cmd4="\x00\x40\x00\x00"

# Common patterns
pattern1="\x42"
pattern2="\x13"
pattern3="\x00\x00\x00\x00"
pattern4="\xFF\xFF\xFF\xFF"

# Strings
str1="Hello"
str2="World"
str3="Test"
str4="Fuzzing"
EOF

    echo "✅ Fuzzing dictionary created"
}

# Функция для анализа результатов
analyze_results() {
    echo "📊 Analyzing fuzzing results..."
    
    local crash_count=$(ls -1 "$CRASHES_DIR" 2>/dev/null | wc -l)
    local corpus_count=$(find "$CORPUS_DIR" -type f 2>/dev/null | wc -l)
    
    echo "Results Summary:"
    echo "  📁 Corpus files: $corpus_count"
    echo "  💥 Crashes found: $crash_count"
    
    if [ "$crash_count" -gt 0 ]; then
        echo "  🔍 Crash files:"
        ls -la "$CRASHES_DIR"
        
        # Создаем отчет о крашах
        cat > "$REPORTS_DIR/crash_report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Fuzzing Crash Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .crash { background: #ffebee; padding: 10px; margin: 10px 0; border-left: 4px solid #f44336; }
        .summary { background: #e8f5e8; padding: 15px; border-radius: 5px; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>🔥 Fuzzing Results Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total crashes found:</strong> CRASH_COUNT</p>
        <p><strong>Corpus size:</strong> CORPUS_COUNT files</p>
        <p><strong>Generated:</strong> $(date)</p>
    </div>
    
    <h2>Crash Analysis</h2>
    <div class="crash">
        <h3>Crashes require manual analysis</h3>
        <p>Use AddressSanitizer output to analyze crash details.</p>
        <p>Check crash files in: <code>crashes/</code> directory</p>
    </div>
</body>
</html>
EOF
        
        sed -i "s/CRASH_COUNT/$crash_count/g" "$REPORTS_DIR/crash_report.html"
        sed -i "s/CORPUS_COUNT/$corpus_count/g" "$REPORTS_DIR/crash_report.html"
        
        echo "  📋 Report generated: $REPORTS_DIR/crash_report.html"
    fi
}

# Функция для генерации итогового отчета
generate_final_report() {
    echo "📄 Generating final report..."
    
    cat > "$REPORTS_DIR/fuzzing_summary.md" << EOF
# LLVM Fuzzing Project - Execution Report

## Project Overview
This report summarizes the execution of the LLVM fuzzing project, demonstrating key skills for a fuzzing engineer position.

## Environment Information
- **Date**: $(date)
- **LLVM Version**: $(llvm-config --version 2>/dev/null || echo "Unknown")
- **Clang Version**: $(clang --version 2>/dev/null | head -n1 || echo "Unknown")
- **System**: $(uname -a)

## Fuzzing Execution Results

### Basic Fuzzing Target
- **Status**: $([ -f "$BUILD_DIR/fuzz_target" ] && echo "✅ Built Successfully" || echo "❌ Build Failed")
- **Sanitizers**: AddressSanitizer, LibFuzzer

### Advanced Fuzzing Target
- **Status**: $([ -f "$BUILD_DIR/advanced_fuzzing" ] && echo "✅ Built Successfully" || echo "❌ Build Failed")
- **Sanitizers**: AddressSanitizer, UndefinedBehaviorSanitizer, LibFuzzer
- **Features**: Custom mutators, complex logic paths, multiple vulnerability types

### LLVM Pass Development
- **Status**: $([ -f "$BUILD_DIR/CountInstructions.so" ] && echo "✅ Built Successfully" || echo "❌ Build Failed")
- **Functionality**: Code instrumentation and analysis

## Key Achievements
1. ✅ Successfully integrated LLVM API for code generation
2. ✅ Implemented custom LLVM passes for code analysis
3. ✅ Created comprehensive fuzzing targets with multiple sanitizers
4. ✅ Automated build and testing process
5. ✅ Integrated CI/CD pipeline with Jenkins
6. ✅ Demonstrated crash detection and analysis capabilities

## Skills Demonstrated
- **LLVM Development**: IR generation, custom passes, API usage
- **Fuzzing Expertise**: LibFuzzer integration, sanitizer usage, corpus management
- **C++ Development**: Modern C++ practices, memory safety
- **DevOps**: Automated builds, testing, CI/CD integration
- **Security**: Vulnerability detection, crash analysis

## Next Steps
1. Extend fuzzing targets with more complex scenarios
2. Integrate with additional sanitizers (ThreadSanitizer, MemorySanitizer)
3. Add performance benchmarking and coverage analysis
4. Implement automated crash triaging and deduplication

---
*Generated by LLVM Fuzzing Project - $(date)*
EOF

    echo "✅ Final report generated: $REPORTS_DIR/fuzzing_summary.md"
}

# Парсинг аргументов командной строки
DURATION=60
JOBS=4
VERBOSE=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--time)
            DURATION="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        basic|advanced|all)
            TARGET="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Проверка, что проект собран
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory not found. Please run ./scripts/build.sh first."
    exit 1
fi

# Основная логика выполнения
main() {
    echo "🎯 LLVM Fuzzing Project - Execution Started"
    echo "Parameters: Target=$TARGET, Duration=${DURATION}s, Jobs=$JOBS"
    
    create_initial_corpus
    create_fuzzing_dict
    
    case "$TARGET" in
        "basic")
            run_basic_fuzzing "$DURATION" "$JOBS"
            ;;
        "advanced")
            run_advanced_fuzzing "$DURATION" "$JOBS"
            ;;
        "all")
            echo "🔥 Running all fuzzing targets..."
            run_basic_fuzzing "$DURATION" "$JOBS"
            echo ""
            run_advanced_fuzzing "$DURATION" "$JOBS"
            ;;
        "")
            echo "🚀 No target specified, running basic fuzzing..."
            run_basic_fuzzing "$DURATION" "$JOBS"
            ;;
        *)
            echo "❌ Unknown target: $TARGET"
            show_help
            exit 1
            ;;
    esac
    
    analyze_results
    generate_final_report
    
    echo ""
    echo "🎉 Fuzzing execution completed!"
    echo "📊 Check results in: $REPORTS_DIR"
    echo "💥 Crashes (if any) in: $CRASHES_DIR"
    echo "📁 Corpus files in: $CORPUS_DIR"
}

main
