# Compiler a.out


## Project Structure

```
compiler/
├── modules/
│   ├── frontend/          # Sysy Frontend (submodule) 
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

### Testing

```bash
xmake test <sy_file|test_case_directory>
```

Compile and run [test-script](https://github.com/BUPT-a-out/test-script). To update test-script, delete the `build` directory and run `xmake test` again.

### Debugging

```bash
xmake debug <sy_file>
```
