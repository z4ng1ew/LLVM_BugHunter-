#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <vector>
#include <algorithm>

// Структура для демонстрации различных типов уязвимостей
struct TestData {
    uint32_t magic;
    uint32_t size;
    char data[256];
};

// Функция с потенциальным buffer overflow
int process_data(const uint8_t* input, size_t size) {
    if (size < sizeof(TestData)) {
        return 0;
    }
    
    TestData* test_data = (TestData*)input;
    
    // Проверка magic number
    if (test_data->magic != 0xDEADBEEF) {
        return 0;
    }
    
    // Потенциальная уязвимость: использование непроверенного размера
    if (test_data->size > 255) {
        // Искусственная уязвимость для демонстрации
        char buffer[100];
        memcpy(buffer, test_data->data, test_data->size); // Потенциальный overflow
        return 1;
    }
    
    return 0;
}

// Функция с integer overflow
int calculate_checksum(const uint8_t* data, size_t size) {
    if (size == 0) return 0;
    
    uint32_t checksum = 0;
    for (size_t i = 0; i < size; ++i) {
        checksum += data[i];
        // Потенциальный integer overflow
        checksum *= 1337;
    }
    
    // Искусственная уязвимость
    if (checksum == 0x12345678) {
        abort(); // Crash для демонстрации
    }
    
    return checksum;
}

// Функция с использованием после освобождения (use-after-free)
int process_vector(const uint8_t* input, size_t size) {
    if (size < 4) return 0;
    
    std::vector<uint8_t> vec(input, input + size);
    uint8_t* ptr = vec.data();
    
    // Искусственная логика с потенциальной проблемой
    if (size > 10 && input[0] == 0xFF && input[1] == 0xEE) {
        vec.clear();
        // Потенциальное использование после освобождения
        return ptr[0]; // Опасно!
    }
    
    return 0;
}

// Функция для демонстрации различных путей выполнения
int complex_logic(const uint8_t* input, size_t size) {
    if (size < 8) return 0;
    
    uint32_t cmd = *(uint32_t*)input;
    uint32_t arg = *(uint32_t*)(input + 4);
    
    switch (cmd) {
        case 0x1000:
            return process_data(input + 8, size - 8);
        case 0x2000:
            return calculate_checksum(input + 8, size - 8);
        case 0x3000:
            return process_vector(input + 8, size - 8);
        case 0x4000:
            // Сложная логика с множественными условиями
            if (arg == 0xAABBCCDD) {
                if (size > 16 && input[15] == 0x42) {
                    if (size > 32 && input[31] == 0x13) {
                        // Глубоко вложенное условие
                        abort(); // Crash для демонстрации
                    }
                }
            }
            return 0;
        default:
            return 0;
    }
}

// Главная функция для LibFuzzer
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    // Базовая проверка размера
    if (Size < 4) {
        return 0;
    }
    
    // Статистика для мониторинга
    static size_t total_calls = 0;
    static size_t max_size = 0;
    
    total_calls++;
    if (Size > max_size) {
        max_size = Size;
    }
    
    // Периодический вывод статистики
    if (total_calls % 10000 == 0) {
        std::cout << "Fuzzing stats: " << total_calls 
                  << " calls, max size: " << max_size << std::endl;
    }
    
    // Запуск тестирования
    try {
        complex_logic(Data, Size);
    } catch (const std::exception& e) {
        // Обработка исключений
        std::cout << "Exception caught: " << e.what() << std::endl;
        return 0;
    }
    
    return 0;
}

// Функция инициализации для LibFuzzer
extern "C" int LLVMFuzzerInitialize(int *argc, char ***argv) {
    std::cout << "Advanced Fuzzing Target Initialized" << std::endl;
    std::cout << "Compiled with sanitizers: ";
    
#ifdef __has_feature
    #if __has_feature(address_sanitizer)
        std::cout << "AddressSanitizer ";
    #endif
    #if __has_feature(memory_sanitizer)
        std::cout << "MemorySanitizer ";
    #endif
    #if __has_feature(thread_sanitizer)
        std::cout << "ThreadSanitizer ";
    #endif
#endif
    
    std::cout << std::endl;
    return 0;
}

// Функция для создания начальных тестовых данных
extern "C" size_t LLVMFuzzerCustomMutator(uint8_t *Data, size_t Size,
                                         size_t MaxSize, unsigned int Seed) {
    // Простая custom мутация для демонстрации
    if (Size > 0 && MaxSize > Size) {
        // Добавляем случайные байты
        for (size_t i = Size; i < std::min(MaxSize, Size + 4); ++i) {
            Data[i] = rand() % 256;
        }
        return std::min(MaxSize, Size + 4);
    }
    return Size;
}
