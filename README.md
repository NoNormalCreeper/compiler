# Compiler a.out


## Project Structure

```
compiler/
├── CMakeLists.txt         # Root CMake configuration
├── modules/
│   └── midend/            # Middle-end IR library (submodule)
│       ├── include/IR/    # IR headers (Module, Function, BasicBlock, etc.)
│       ├── src/IR/        # IR implementation
│       └── tests/         # Unit tests for IR components
└── src/
    ├── CMakeLists.txt     # Source CMake configuration
    └── main.cpp           # Main compiler entry point
```

## Getting Started

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/BUPT-a-out/compiler.git
   cd compiler
   ```

2. **Update submodules**:
   ```bash
   git submodule update --init --recursive
   ```

### Building

1. **Configure with CMake**:
   ```bash
   cmake -B build
   ```

3. **Build the project**:
   ```bash
   cmake --build build -j8
   ```

### Running

After building, run the compiler:

```bash
./build/src/compiler
```

This will execute the example in `main.cpp` which demonstrates:
- Creating an IR module
- Building a function that sums an array
- Generating and printing the IR

