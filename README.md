# Compiler a.out


## Project Structure

```
compiler/
├── modules/
│   ├── riscv64/           # RISC-V backend (submodule)
│   └── midend/            # Middle-end IR library (submodule)
└── src/
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

```bash
xmake
```

### Running

```bash
xmake run
```

This will execute the example in `main.cpp` which demonstrates:
- Creating an IR module
- Building a function that sums an array
- Generating and printing the IR

