#!/usr/bin/env bun

import { promises as fs } from 'fs';
import { join } from 'path';
import { performance } from 'perf_hooks';
import { platform } from 'os';

interface BenchmarkResult {
  operation: string;
  location: string;
  throughputMBps: number;
  iops?: number;
  filesPerSec?: number;
  timeMs: number;
  fileSize?: number;
}

class IOBenchmark {
  private results: BenchmarkResult[] = [];
  
  async createTestData(baseDir: string, size: number): Promise<string> {
    const testFile = join(baseDir, `test_${size}MB.bin`);
    const chunkSize = 1024 * 1024;
    const buffer = Buffer.alloc(chunkSize, 'A');
    
    await fs.writeFile(testFile, '');
    const handle = await fs.open(testFile, 'w');
    
    for (let i = 0; i < size; i++) {
      await handle.write(buffer);
    }
    
    await handle.close();
    return testFile;
  }

  async sequentialReadTest(baseDir: string, fileSizeMB: number): Promise<void> {
    console.log(`\n📖 Sequential Read Test (${fileSizeMB}MB) - ${baseDir}`);
    
    const testFile = await this.createTestData(baseDir, fileSizeMB);
    const start = performance.now();
    
    const data = await fs.readFile(testFile);
    
    const end = performance.now();
    const timeMs = end - start;
    const throughputMBps = (data.length / (1024 * 1024)) / (timeMs / 1000);
    
    this.results.push({
      operation: 'Sequential Read',
      location: baseDir,
      throughputMBps,
      timeMs,
      fileSize: fileSizeMB
    });
    
    console.log(`  ⏱️  Time: ${timeMs.toFixed(2)}ms`);
    console.log(`  🚀 Throughput: ${throughputMBps.toFixed(2)} MB/s`);
    
    await fs.unlink(testFile);
  }

  async sequentialWriteTest(baseDir: string, fileSizeMB: number): Promise<void> {
    console.log(`\n✍️  Sequential Write Test (${fileSizeMB}MB) - ${baseDir}`);
    
    const testFile = join(baseDir, `write_test_${fileSizeMB}MB.bin`);
    const buffer = Buffer.alloc(fileSizeMB * 1024 * 1024, 'B');
    
    const start = performance.now();
    await fs.writeFile(testFile, buffer);
    const end = performance.now();
    
    const timeMs = end - start;
    const throughputMBps = fileSizeMB / (timeMs / 1000);
    
    this.results.push({
      operation: 'Sequential Write',
      location: baseDir,
      throughputMBps,
      timeMs,
      fileSize: fileSizeMB
    });
    
    console.log(`  ⏱️  Time: ${timeMs.toFixed(2)}ms`);
    console.log(`  🚀 Throughput: ${throughputMBps.toFixed(2)} MB/s`);
    
    await fs.unlink(testFile);
  }

  async randomIOTest(baseDir: string, numFiles: number, fileSizeKB: number): Promise<void> {
    console.log(`\n🎲 Random I/O Test (${numFiles} files, ${fileSizeKB}KB each) - ${baseDir}`);
    
    const testDir = join(baseDir, 'random_test');
    await fs.mkdir(testDir, { recursive: true });
    
    const buffer = Buffer.alloc(fileSizeKB * 1024, 'C');
    const files: string[] = [];
    
    const writeStart = performance.now();
    for (let i = 0; i < numFiles; i++) {
      const file = join(testDir, `random_${i}.dat`);
      files.push(file);
      await fs.writeFile(file, buffer);
    }
    const writeEnd = performance.now();
    
    const readStart = performance.now();
    for (let i = 0; i < numFiles; i++) {
      const randomFile = files[Math.floor(Math.random() * files.length)];
      await fs.readFile(randomFile);
    }
    const readEnd = performance.now();
    
    const writeTimeMs = writeEnd - writeStart;
    const readTimeMs = readEnd - readStart;
    const totalDataMB = (numFiles * fileSizeKB) / 1024;
    
    const writeIOPS = numFiles / (writeTimeMs / 1000);
    const readIOPS = numFiles / (readTimeMs / 1000);
    
    this.results.push({
      operation: 'Random Write',
      location: baseDir,
      throughputMBps: totalDataMB / (writeTimeMs / 1000),
      iops: writeIOPS,
      timeMs: writeTimeMs
    });
    
    this.results.push({
      operation: 'Random Read',
      location: baseDir,
      throughputMBps: totalDataMB / (readTimeMs / 1000),
      iops: readIOPS,
      timeMs: readTimeMs
    });
    
    console.log(`  ✍️  Write IOPS: ${writeIOPS.toFixed(2)}, Time: ${writeTimeMs.toFixed(2)}ms`);
    console.log(`  📖 Read IOPS: ${readIOPS.toFixed(2)}, Time: ${readTimeMs.toFixed(2)}ms`);
    
    for (const file of files) {
      await fs.unlink(file);
    }
    await fs.rmdir(testDir);
  }

  async directoryTraversalTest(baseDir: string, numDirs: number, filesPerDir: number): Promise<void> {
    console.log(`\n📁 Directory Traversal Test (${numDirs} dirs, ${filesPerDir} files/dir) - ${baseDir}`);
    
    const testRoot = join(baseDir, 'traversal_test');
    await fs.mkdir(testRoot, { recursive: true });
    
    for (let d = 0; d < numDirs; d++) {
      const dirPath = join(testRoot, `dir_${d}`);
      await fs.mkdir(dirPath, { recursive: true });
      
      for (let f = 0; f < filesPerDir; f++) {
        const filePath = join(dirPath, `file_${f}.txt`);
        await fs.writeFile(filePath, `Content of file ${f} in dir ${d}`);
      }
    }
    
    const traverseStart = performance.now();
    let totalFiles = 0;
    
    async function traverse(dir: string): Promise<void> {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = join(dir, entry.name);
        if (entry.isDirectory()) {
          await traverse(fullPath);
        } else {
          totalFiles++;
        }
      }
    }
    
    await traverse(testRoot);
    const traverseEnd = performance.now();
    
    const traverseTimeMs = traverseEnd - traverseStart;
    const filesPerSecond = totalFiles / (traverseTimeMs / 1000);
    
    this.results.push({
      operation: 'Directory Traversal',
      location: baseDir,
      throughputMBps: filesPerSecond / 1000, // Keep for backwards compatibility
      filesPerSec: filesPerSecond,
      timeMs: traverseTimeMs
    });
    
    console.log(`  📊 Files found: ${totalFiles}`);
    console.log(`  ⏱️  Traversal time: ${traverseTimeMs.toFixed(2)}ms`);
    console.log(`  🚀 Files/sec: ${filesPerSecond.toFixed(2)}`);
    
    await fs.rm(testRoot, { recursive: true, force: true });
  }

  async runAllTests(location: string): Promise<void> {
    console.log(`\n🏃 Running all tests for: ${location}`);
    console.log('='.repeat(60));
    
    try {
      await this.sequentialReadTest(location, 100);
      await this.sequentialWriteTest(location, 100);
      await this.randomIOTest(location, 1000, 4);
      await this.directoryTraversalTest(location, 50, 20);
    } catch (error) {
      console.error(`❌ Error testing ${location}:`, error instanceof Error ? error.message : String(error));
    }
  }

  generateReport(): void {
    console.log('\n📈 BENCHMARK RESULTS SUMMARY');
    console.log('='.repeat(80));
    
    const locations = [...new Set(this.results.map(r => r.location))];
    const operations = [...new Set(this.results.map(r => r.operation))];
    
    for (const operation of operations) {
      console.log(`\n${operation}:`);
      
      // Use appropriate baseline depending on available results
      // For WSL-only runs, use WSL native (/home) as baseline
      // For Windows-only runs, use Windows native as baseline
      let baselineResult = this.results.find(r => 
        r.operation === operation && (
          r.location.includes('C:\\Users\\Webber') || 
          r.location.includes('/mnt/c/Users/Webber')
        )
      );
      
      // Fallback to WSL native if no Windows native found
      if (!baselineResult) {
        baselineResult = this.results.find(r => 
          r.operation === operation && r.location.includes('/home')
        );
      }
      
      for (const location of locations) {
        const result = this.results.find(r => 
          r.operation === operation && r.location === location
        );
        
        if (result) {
          let percentage = '100%';
          if (baselineResult && result !== baselineResult) {
            const pct = (result.throughputMBps / baselineResult.throughputMBps) * 100;
            percentage = `${pct.toFixed(1)}%`;
          }
          
          let locationLabel;
          if (location.includes('C:\\Users\\Webber') && !location.includes('wsl.localhost')) {
            locationLabel = 'Windows Native';
          } else if (location.includes('wsl.localhost')) {
            locationLabel = 'Windows→WSL';
          } else if (location.includes('/home')) {
            locationLabel = 'WSL Native';
          } else if (location.includes('/mnt/c')) {
            locationLabel = 'WSL→Windows';
          } else {
            locationLabel = 'Unknown';
          }
          
          console.log(`  ${locationLabel.padEnd(15)} ${result.throughputMBps.toFixed(2).padStart(8)} MB/s (${percentage})`);
          if (result.iops) {
            console.log(`${' '.repeat(17)}${result.iops.toFixed(0).padStart(8)} IOPS`);
          }
        }
      }
    }
  }

  getResults(): BenchmarkResult[] {
    return this.results;
  }
}

async function main() {
  const benchmark = new IOBenchmark();
  
  console.log('🧪 I/O Performance Benchmark Suite');
  console.log('Cross-platform filesystem performance testing\n');
  
  // Auto-detect platform and set test locations
  const isWindows = platform() === 'win32';
  const testLocations = isWindows ? [
    'C:\\Users\\Webber\\benchmark_test',
    '\\\\wsl.localhost\\Ubuntu-22.04\\home\\webber\\benchmark_test',
  ] : [
    '/home/webber/benchmark_test',
    '/mnt/c/Users/Webber/benchmark_test',
  ];
  
  console.log(`🔍 Platform: ${isWindows ? 'Windows' : 'WSL/Linux'}`);
  console.log(`📁 Test locations: ${testLocations.join(', ')}\n`);
  
  // Ensure test directories exist
  for (const location of testLocations) {
    try {
      await fs.mkdir(location, { recursive: true });
      console.log(`✅ Test directory ready: ${location}`);
    } catch (error) {
      console.error(`❌ Failed to create ${location}:`, error);
    }
  }
  
  // Run benchmarks
  for (const location of testLocations) {
    await benchmark.runAllTests(location);
  }
  
  // Generate report
  benchmark.generateReport();
  
  // Save results
  const results = benchmark.getResults();
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const platformPrefix = isWindows ? 'windows' : 'wsl';
  
  // Ensure output directory exists
  try {
    await fs.mkdir('./output', { recursive: true });
  } catch (error) {
    // Directory might already exist, continue
  }
  
  const resultsFile = `./output/${platformPrefix}_benchmark_results_${timestamp}.json`;
  
  try {
    await fs.writeFile(resultsFile, JSON.stringify(results, null, 2));
    console.log(`\n💾 Results saved to: ${resultsFile}`);
  } catch (error) {
    console.error(`❌ Failed to save results: ${error}`);
  }
  
  // Cleanup
  for (const location of testLocations) {
    try {
      await fs.rmdir(location);
      console.log(`🧹 Cleaned up: ${location}`);
    } catch (error) {
      console.warn(`⚠️  Could not cleanup ${location}:`, error instanceof Error ? error.message : String(error));
    }
  }
  
  console.log(`\n✨ ${isWindows ? 'Windows' : 'WSL'} benchmarks completed!`);
}

if (typeof process !== 'undefined' && process.argv0 !== undefined) {
  main().catch(console.error);
}