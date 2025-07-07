#include <cstdint>
#include <cstdlib>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    if (Size < 4) return 0; // Недостаточно данных
    int a = *reinterpret_cast<const int*>(Data);
    int b = *reinterpret_cast<const int*>(Data + sizeof(int));
    int result = a + b; // Тестируемая функция
    if (result == 42) {
        __builtin_trap(); // Искусственная ошибка
    }
    return 0;
}
