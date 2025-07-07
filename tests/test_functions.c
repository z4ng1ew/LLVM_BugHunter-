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
