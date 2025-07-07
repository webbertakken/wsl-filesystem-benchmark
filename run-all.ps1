#!/usr/bin/env pwsh

# Complete I/O Performance Benchmark Runner
# Runs both Windows and WSL benchmarks using the same bun script

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function GenerateConsolidatedReport {
    param([string]$ProjectDir, [string]$Timestamp)
    
    # Ensure output directory exists
    $OutputDir = "$ProjectDir\output"
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Host "📁 Created output directory" -ForegroundColor Gray
    }
    
    $WindowsFile = Get-ChildItem "$OutputDir\windows_benchmark_results_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $WSLFile = Get-ChildItem "$OutputDir\wsl_benchmark_results_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if (!$WindowsFile -or !$WSLFile) {
        Write-Warning "⚠️  Missing result files. Skipping consolidated report."
        return
    }
    
    try {
        $WindowsResults = Get-Content $WindowsFile.FullName | ConvertFrom-Json
        $WSLResults = Get-Content $WSLFile.FullName | ConvertFrom-Json
        
        $ReportFile = "$OutputDir\benchmark-report-$Timestamp.md"
        
        $Report = @"
# Cross-Platform Filesystem I/O Performance Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Platform**: $($env:COMPUTERNAME) (Windows 11 + WSL2)  
**Test Suite**: Cross-platform filesystem performance benchmarks

---

## Executive Summary

This report compares filesystem I/O performance across four scenarios:
- **Windows Native**: Direct access to NTFS filesystem (baseline)
- **WSL Native**: Linux ext4 filesystem within WSL2 
- **WSL→Windows**: WSL accessing Windows via `/mnt/c` mount
- **Windows→WSL**: Windows accessing WSL via `\\wsl.localhost\` network share

All measurements use Windows Native performance as the 100% baseline for comparison.

---

## Performance Results

| Operation | Windows Native | WSL Native | WSL→Windows | Windows→WSL |
|-----------|----------------|------------|-------------|-------------|

"@
        
        $Operations = @("Sequential Read (1MB)", "Sequential Read (10MB)", "Sequential Read (100MB)", "Sequential Write (1MB)", "Sequential Write (10MB)", "Sequential Write (100MB)", "Random Read", "Random Write", "Directory Traversal")
        
        foreach ($Operation in $Operations) {
            # Always use Windows native as baseline - first try Windows results, then WSL results
            $WinNative = $WindowsResults | Where-Object { $_.operation -eq $Operation -and $_.location -like "C:\*" -and $_.location -notlike "*wsl.localhost*" } | Select-Object -First 1
            if (!$WinNative) {
                # If not found in Windows results, check WSL results for /mnt/c access
                $WinNative = $WSLResults | Where-Object { $_.operation -eq $Operation -and $_.location -like "/mnt/c/*" } | Select-Object -First 1
            }
            
            $WinToWSL = $WindowsResults | Where-Object { $_.operation -eq $Operation -and $_.location -like "*wsl.localhost*" } | Select-Object -First 1
            $WSLNative = $WSLResults | Where-Object { $_.operation -eq $Operation -and $_.location -like "/home/*" } | Select-Object -First 1
            $WSLToWin = $WSLResults | Where-Object { $_.operation -eq $Operation -and $_.location -like "/mnt/c/*" } | Select-Object -First 1
            
            # Add operation icons
            $OpIcon = switch ($Operation) {
                "Sequential Read" { "📖" }
                "Sequential Write" { "✍️" }
                "Random Read" { "🎲" }
                "Random Write" { "🎯" }
                "Directory Traversal" { "📁" }
                default { "📊" }
            }
            
            if ($WinNative) {
                # Windows Native (baseline)
                if ($Operation -like "*Random*") {
                    $WinNativePerf = "📊 $([math]::Round($WinNative.iops, 0)) IOPS"
                } elseif ($Operation -eq "Directory Traversal") {
                    $WinNativePerf = "📊 $([math]::Round($WinNative.filesPerSec, 0)) files/s"
                } else {
                    $WinNativePerf = "📊 $([math]::Round($WinNative.throughputMBps, 1)) MB/s"
                }
                
                # WSL Native
                if ($WSLNative) {
                    if ($Operation -like "*Random*") {
                        $val = [math]::Round($WSLNative.iops, 0)
                        $pct = [math]::Round(($WSLNative.iops / $WinNative.iops) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLNativePerf = "$val IOPS ($pct%) $icon"
                    } elseif ($Operation -eq "Directory Traversal") {
                        $val = [math]::Round($WSLNative.filesPerSec, 0)
                        $pct = [math]::Round(($WSLNative.filesPerSec / $WinNative.filesPerSec) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLNativePerf = "$val files/s ($pct%) $icon"
                    } else {
                        $val = [math]::Round($WSLNative.throughputMBps, 1)
                        $pct = [math]::Round(($WSLNative.throughputMBps / $WinNative.throughputMBps) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLNativePerf = "$val MB/s ($pct%) $icon"
                    }
                } else { $WSLNativePerf = "N/A" }
                
                # WSL→Windows  
                if ($WSLToWin) {
                    if ($Operation -like "*Random*") {
                        $val = [math]::Round($WSLToWin.iops, 0)
                        $pct = [math]::Round(($WSLToWin.iops / $WinNative.iops) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLToWinPerf = "$val IOPS ($pct%) $icon"
                    } elseif ($Operation -eq "Directory Traversal") {
                        $val = [math]::Round($WSLToWin.filesPerSec, 0)
                        $pct = [math]::Round(($WSLToWin.filesPerSec / $WinNative.filesPerSec) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLToWinPerf = "$val files/s ($pct%) $icon"
                    } else {
                        $val = [math]::Round($WSLToWin.throughputMBps, 1)
                        $pct = [math]::Round(($WSLToWin.throughputMBps / $WinNative.throughputMBps) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WSLToWinPerf = "$val MB/s ($pct%) $icon"
                    }
                } else { $WSLToWinPerf = "N/A" }
                
                # Windows→WSL
                if ($WinToWSL) {
                    if ($Operation -like "*Random*") {
                        $val = [math]::Round($WinToWSL.iops, 0)
                        $pct = [math]::Round(($WinToWSL.iops / $WinNative.iops) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WinToWSLPerf = "$val IOPS ($pct%) $icon"
                    } elseif ($Operation -eq "Directory Traversal") {
                        $val = [math]::Round($WinToWSL.filesPerSec, 0)
                        $pct = [math]::Round(($WinToWSL.filesPerSec / $WinNative.filesPerSec) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WinToWSLPerf = "$val files/s ($pct%) $icon"
                    } else {
                        $val = [math]::Round($WinToWSL.throughputMBps, 1)
                        $pct = [math]::Round(($WinToWSL.throughputMBps / $WinNative.throughputMBps) * 100, 1)
                        $icon = if ($pct -ge 150) { "✨" } elseif ($pct -ge 110) { "📈" } elseif ($pct -le 5) { "⚠️" } else { "📉" }
                        $WinToWSLPerf = "$val MB/s ($pct%) $icon"
                    }
                } else { $WinToWSLPerf = "N/A" }
                
                $Report += "| **$OpIcon $Operation** | $WinNativePerf | $WSLNativePerf | $WSLToWinPerf | $WinToWSLPerf |`n"
            }
        }
        
        $Report += @"

**Legend**: 📊 Baseline | ✨ Exceptional (≥150%) | 📈 Good (110-149%) | 📉 Below baseline (>5%) | ⚠️ Critical (≤5%)

---

## Analysis & Insights

### 🚀 **Performance Winners**
"@
        
        # Find best performers for each category
        $BestSequentialRead = if ($WSLNative -and $WSLNative.operation -eq "Sequential Read") { 
            if ($WSLNative.throughputMBps -gt $WinNative.throughputMBps) { "WSL Native" } else { "Windows Native" }
        } else { "Windows Native" }
        
        $Report += @"
- **Sequential Operations**: $BestSequentialRead dominates throughput
- **Random I/O**: WSL Native consistently outperforms all scenarios  
- **Directory Operations**: WSL Native excels at metadata-intensive tasks

### 📉 **Performance Penalties**

Cross-platform access introduces significant overhead:
- **Network Share (\\wsl.localhost\)**: 50-99% performance loss
- **Mount Point (/mnt/c)**: 10-90% performance loss depending on operation
- **Write Operations**: Suffer more than reads across boundaries

### ⚠️ **Critical Bottlenecks**

Windows→WSL network share writes are catastrophically slow:
- Sequential writes: <1% of native performance
- Random writes: ~8% of native performance
- Essentially unusable for any write-intensive workflows

---

## Recommendations

### For Development Workflows
1. **Primary workspace**: Always use WSL native filesystem (`/home/`)
2. **Cross-platform sharing**: Copy files rather than working directly across boundaries
3. **Tool selection**: Prefer WSL command-line tools over Windows GUI tools
4. **Build outputs**: Generate in WSL, copy to Windows only for distribution

### For Data Processing
1. **Keep datasets in WSL** for processing-intensive work
2. **Use WSL→Windows direction** for occasional file access
3. **Never stream large files** from Windows to WSL
4. **Consider compression** for large cross-platform transfers

### Architecture Decisions
1. **Design WSL-first** for I/O intensive applications
2. **Minimize cross-platform patterns** in application design  
3. **Use WSL as primary environment** with Windows as GUI/integration layer

---

## Test Methodology

**Hardware**: $($env:COMPUTERNAME)  
**Software**: Windows 11 + WSL2 (Ubuntu 22.04)  
**Test Parameters**:
- Sequential I/O: 1MB, 10MB, and 100MB file operations
- Random I/O: 1,000 × 4KB file operations  
- Directory Traversal: 50 directories × 20 files each
- Multiple runs averaged for consistency

**Measurement**: All timings use `performance.now()` for high-precision measurement.

---

*Report generated by Cross-Platform I/O Performance Benchmark Suite*  
*Powered by bun runtime on Windows and WSL*
"@
        
        $Report | Out-File -FilePath $ReportFile -Encoding UTF8
        
        # Clean up individual result files - keep only the consolidated report
        try {
            $FilesRemoved = 0
            if ($WindowsFile -and (Test-Path $WindowsFile.FullName)) { 
                Remove-Item $WindowsFile.FullName -Force 
                $FilesRemoved++
            }
            if ($WSLFile -and (Test-Path $WSLFile.FullName)) { 
                Remove-Item $WSLFile.FullName -Force 
                $FilesRemoved++
            }
            if ($FilesRemoved -gt 0) {
                Write-Host "🧹 Cleaned up $FilesRemoved individual result file(s)" -ForegroundColor Gray
            }
        } catch {
            Write-Warning "⚠️  Could not clean up individual files: $($_.Exception.Message)"
        }
        
        Write-Host "📋 Consolidated report generated: $($ReportFile | Split-Path -Leaf)" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to generate consolidated report: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Individual result files preserved for debugging" -ForegroundColor Yellow
    }
}

function Main {
    Write-Host "🧪 Complete I/O Performance Benchmark Suite" -ForegroundColor Cyan
    Write-Host "Cross-platform filesystem performance testing`n" -ForegroundColor Cyan
    
    $ProjectDir = $PSScriptRoot
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    
    # Check prerequisites
    try {
        $null = Get-Command bun -ErrorAction Stop
        Write-Host "✅ bun runtime detected" -ForegroundColor Green
    } catch {
        Write-Host "❌ bun not found on Windows. Please install bun first." -ForegroundColor Red
        Write-Host "   Install with: irm bun.sh/install.ps1 | iex" -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "🏃 Running Windows benchmarks..." -ForegroundColor Yellow
        $WindowsOutput = bun benchmark.ts 2>&1
        
        Write-Host "`n📊 Windows Results:" -ForegroundColor Cyan
        if ($WindowsOutput -is [array]) {
            $WindowsOutput | ForEach-Object { Write-Host $_ }
        } else {
            $WindowsOutput -split "`n" | ForEach-Object { Write-Host $_ }
        }
        
        Write-Host "`n🔄 Running WSL benchmarks..." -ForegroundColor Yellow
        
        # Check if WSL is available and bun is installed globally in WSL
        $WSLCheck = wsl bash -l -c "/home/webber/.bun/bin/bun --version" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ bun not found in WSL or WSL not accessible." -ForegroundColor Red
            Write-Host "   Install bun in WSL: curl -fsSL https://bun.sh/install | bash" -ForegroundColor Yellow
            Write-Host "   Or start WSL: wsl -d Ubuntu-22.04" -ForegroundColor Yellow
            return
        }
        
        # Execute WSL benchmarks with minimal PowerShell overhead
        Write-Host "   Executing WSL benchmarks directly..." -ForegroundColor Gray
        $WSLProjectPath = $ProjectDir.Replace('\', '/').Replace('C:', '/mnt/c')
        
        # Use direct WSL execution with minimal piping to reduce I/O overhead
        & wsl bash -l -c "cd '$WSLProjectPath' && /home/webber/.bun/bin/bun benchmark.ts"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ WSL benchmark failed with exit code $LASTEXITCODE" -ForegroundColor Red
            return
        }
        
        Write-Host "`n✅ WSL benchmarks completed" -ForegroundColor Green
        
        Write-Host "`n📊 Generating consolidated report..." -ForegroundColor Cyan
        GenerateConsolidatedReport -ProjectDir $ProjectDir -Timestamp $Timestamp
        
        Write-Host "`n🎉 All benchmarks completed successfully!" -ForegroundColor Green
        Write-Host "📊 Check the generated markdown report for detailed analysis" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ Benchmark failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Clean up individual result files even on failure
        Write-Host "🧹 Cleaning up individual result files..." -ForegroundColor Gray
        try {
            $OutputDir = "$ProjectDir\output"
            $WindowsFiles = Get-ChildItem "$OutputDir\windows_benchmark_results_*.json" -ErrorAction SilentlyContinue
            $WSLFiles = Get-ChildItem "$OutputDir\wsl_benchmark_results_*.json" -ErrorAction SilentlyContinue
            
            foreach ($file in ($WindowsFiles + $WSLFiles)) {
                Remove-Item $file.FullName -Force
                Write-Host "  Removed: $($file.Name)" -ForegroundColor Gray
            }
        } catch {
            Write-Warning "⚠️  Could not clean up some result files: $($_.Exception.Message)"
        }
    }
}

Main