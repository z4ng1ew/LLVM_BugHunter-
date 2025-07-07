### Краткое описание проекта 

🇷🇺 **Русский**:  
Проект демонстрирует техники фаззинга на основе LLVM, включая кастомные проходы, инструментацию и анализ сбоев. Идеален для изучения продвинутого фаззинга с LLVM.

🇬🇧 **English**:  
Project demonstrates LLVM-based fuzzing techniques with custom passes, instrumentation, and crash analysis. Ideal for learning advanced fuzzing with LLVM.

---

### README.md для проекта

```markdown
# LLVM Fuzzing Project

[🇬🇧 English](#english) | [🇷🇺 Русский](#русский)

<a name="english"></a>
## 🇬🇧 LLVM Fuzzing Framework

Advanced fuzzing toolkit using LLVM for:
- Custom instrumentation passes
- Crash analysis
- Coverage-guided fuzzing
- Integration with sanitizers

### Features
- Custom LLVM Pass for instruction counting
- Fuzzing targets with libFuzzer
- Crash triage system
- Docker support for reproducible environments

### Quick Start
```bash
git clone https://github.com/yourusername/llvm-fuzzing-project.git
cd llvm-fuzzing-project
./build.sh clean
./run_fuzzing.sh
```

### Documentation
See [docs/](docs/) for advanced usage and API reference.

---

<a name="русский"></a>
## 🇷🇺 Фреймворк для фаззинга на LLVM

Продвинутый инструментарий для фаззинга с использованием LLVM:
- Кастомные инструментирующие проходы
- Анализ сбоев
- Фаззинг с учетом покрытия
- Интеграция с санитайзерами

### Возможности
- Кастомный LLVM Pass для подсчета инструкций
- Цели для фаззинга с libFuzzer
- Система анализа сбоев
- Поддержка Docker для воспроизводимых окружений

### Быстрый старт
```bash
git clone https://github.com/yourusername/llvm-fuzzing-project.git
cd llvm-fuzzing-project
./build.sh clean
./run_fuzzing.sh
```

### Документация
Подробности в [docs/](docs/) (на английском).
```

---

### Структура проекта
```
llvm-fuzzing-project/
├── CMakeLists.txt          # Конфигурация сборки
├── build.sh                # Скрипт сборки
├── run_fuzzing.sh          # Скрипт запуска фаззинга
├── src/
│   └── CountInstructions.cpp # Кастомный LLVM Pass
├── examples/
│   ├── fuzz_target.cpp     # Пример цели для фаззинга
│   └── llvm_example.cpp    # Базовый пример работы с LLVM
├── advanced_fuzzing.cpp    # Расширенный пример фаззинга
├── Dockerfile              # Конфигурация Docker
├── tests/                  # Тестовые данные
├── reports/                # Отчеты фаззинга
└── docs/                   # Документация
```

### Ключевые компоненты
1. **Кастомный LLVM Pass** (`src/CountInstructions.cpp`):  
   - Подсчитывает инструкции в функциях и модулях
   - Работает с новой системой проходов LLVM (New Pass Manager)

2. **Интеграция с libFuzzer** (`examples/fuzz_target.cpp`):  
   - Пример цели для фаззинга
   - Автоматическая генерация тестовых данных

3. **Система сборки** (`build.sh`):  
   - Автоматическая проверка зависимостей
   - Создание тестовых данных
   - Запуск базовых тестов

4. **Docker поддержка**:  
   ```Dockerfile
   FROM ubuntu:22.04
   RUN apt-get update && apt-get install -y \
        clang-14 llvm-14 cmake make
   COPY . /app
   WORKDIR /app
   CMD ["./build.sh"]
   ```
