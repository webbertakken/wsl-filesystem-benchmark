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
| **📖 Sequential Read (1MB)** | 📊 1963.5 MB/s | 2392.8 MB/s (121.9%) 📈 | 85.9 MB/s (4.4%) ⚠️ | 155.8 MB/s (7.9%) 📉 |
| **📖 Sequential Read (10MB)** | 📊 3162.5 MB/s | 2588.1 MB/s (81.8%) 📉 | 286 MB/s (9%) 📉 | 387.3 MB/s (12.2%) 📉 |
| **📖 Sequential Read (100MB)** | 📊 2921.6 MB/s | 2804.1 MB/s (96%) 📉 | 307 MB/s (10.5%) 📉 | 376.8 MB/s (12.9%) 📉 |
| **✍️ Sequential Write (1MB)** | 📊 1904.4 MB/s | 2142.5 MB/s (112.5%) 📈 | 159.8 MB/s (8.4%) 📉 | 150.8 MB/s (7.9%) 📉 |
| **✍️ Sequential Write (10MB)** | 📊 4844 MB/s | 4270.9 MB/s (88.2%) 📉 | 284.4 MB/s (5.9%) 📉 | 114.3 MB/s (2.4%) ⚠️ |
| **✍️ Sequential Write (100MB)** | 📊 1642.9 MB/s | 2826.6 MB/s (172%) ✨ | 293.8 MB/s (17.9%) 📉 | 10 MB/s (0.6%) ⚠️ |
| **🎲 Random Read** | 📊 22607 IOPS | 24554 IOPS (108.6%) 📉 | 725 IOPS (3.2%) ⚠️ | 1271 IOPS (5.6%) 📉 |
| **🎯 Random Write** | 📊 4552 IOPS | 16227 IOPS (356.5%) ✨ | 472 IOPS (10.4%) 📉 | 364 IOPS (8%) 📉 |
| **📁 Directory Traversal** | 📊 94544 files/s | 343338 files/s (363.2%) ✨ | 13561 files/s (14.3%) 📉 | 28045 files/s (29.7%) 📉 |

**Legend**: 📊 Baseline | ✨ Exceptional (≥150%) | 📈 Good (110-149%) | 📉 Below baseline (>5%) | ⚠️ Critical (≤5%)

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
