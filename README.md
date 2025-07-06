# 🧪 Filesystem I/O Performance Benchmarks

Cross-platform filesystem performance testing for Windows and WSL environments.

## Quick Start

```bash
# 🎯 Run complete cross-platform benchmarks (start in PowerShell on Windows)
.\run-all.ps1

# 🏃 Run single platform only  
bun run test
```

## Requirements

- 💻 **PowerShell** 7.0+ on Windows
- 🐧 **WSL2** with Ubuntu 22.04
- 🟢 **Bun** installed on both Windows and WSL

## Latest Results

🎯 Performance comparison with Windows Native as baseline (100%):

| Operation | Windows Native | WSL Native | WSL→Windows | Windows→WSL |
|-----------|----------------|------------|-------------|-------------|
| **📖 Sequential Read** | 📊 3328.9 MB/s | 2768.6 MB/s (83.2%) 📉 | 330.8 MB/s (9.9%) 📉 | 412.4 MB/s (12.4%) 📉 |
| **✍️ Sequential Write** | 📊 1497.9 MB/s | 2943.5 MB/s (196.5%) 📈 | 287.7 MB/s (19.2%) 📉 | 10.3 MB/s (0.7%) ⚠️ |
| **🎲 Random Read** | 📊 21683 IOPS | 24137 IOPS (111.3%) 📈 | 692 IOPS (3.2%) ⚠️ | 1526 IOPS (7%) ⚠️ |
| **🎯 Random Write** | 📊 3943 IOPS | 14792 IOPS (375.1%) 📈 | 468 IOPS (11.9%) 📉 | 432 IOPS (11%) 📉 |
| **📁 Directory Traversal** | 📊 92011 files/s | 302770 files/s (329.1%) 📈 | 13225 files/s (14.4%) 📉 | 33101 files/s (36%) 📉 |

## Key Insights

- 🚀 **WSL Native dominates** random I/O and metadata operations  
- 📉 **Cross-platform penalties** range from 10-90% performance loss  
- ⚠️ **Windows→WSL writes** are catastrophically slow (<1% performance)

## Recommendations

- 🏠 **Develop in WSL native** filesystem (`/home`) for I/O intensive work
- 🔄 **Prefer writing WSL→Windows** to Windows→WSL
- 📦 **Copy files rather than working** directly across platform boundaries

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.
