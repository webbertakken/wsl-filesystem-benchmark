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

Performance comparison with Windows Native as baseline (100%):

| Operation | Windows Native | WSL Native | WSL→Windows | Windows→WSL |
|-----------|----------------|------------|-------------|-------------|
| **📖 Sequential Read (10MB)** | 📊 3094.7 MB/s | 4086.1 MB/s (132%) 📈 | 260.3 MB/s (8.4%) ⚠️ | 384.2 MB/s (12.4%) 📉 |
| **📖 Sequential Read (100MB)** | 📊 2962.9 MB/s | 2758.2 MB/s (93.1%) 📉 | 309.6 MB/s (10.5%) 📉 | 426.5 MB/s (14.4%) 📉 |
| **✍️ Sequential Write (10MB)** | 📊 4691.1 MB/s | 4268.5 MB/s (91%) 📉 | 264.8 MB/s (5.6%) ⚠️ | 128.9 MB/s (2.7%) ⚠️ |
| **✍️ Sequential Write (100MB)** | 📊 1017.3 MB/s | 2894.2 MB/s (284.5%) 📈 | 284.7 MB/s (28%) 📉 | 10.3 MB/s (1%) ⚠️ |
| **🎲 Random Read** | 📊 22412 IOPS | 23370 IOPS (104.3%) 📉 | 726 IOPS (3.2%) ⚠️ | 1567 IOPS (7%) ⚠️ |
| **🎯 Random Write** | 📊 4408 IOPS | 14961 IOPS (339.4%) 📈 | 490 IOPS (11.1%) 📉 | 444 IOPS (10.1%) 📉 |
| **📁 Directory Traversal** | 📊 97941 files/s | 340201 files/s (347.4%) 📈 | 13295 files/s (13.6%) 📉 | 32712 files/s (33.4%) 📉 |

## Key Insights

- 🚀 **WSL Native dominates** random I/O and metadata operations  
- 📉 **Cross-platform penalties** range from 10-90% performance loss  
- ⚠️ **Windows→WSL writes** are catastrophically slow (<1% performance)

## Recommendations

- 🏠 **Develop in WSL native** filesystem (`/home`) for I/O intensive work
- 🔄 **Prefer writing WSL→Windows** to Windows→WSL
- 📦 **Copy files rather than working** directly across platform boundaries

## 📜 License

[MIT](LICENSE) License.
