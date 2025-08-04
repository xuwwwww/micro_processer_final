# 微算機應用期末報告 (Microprocessor Application Final Project)

本專案為台科大微算機應用課程的期末報告，所有代碼以 Verilog 撰寫，並包含部分 Batchfile 用於自動化流程或模擬。  
This project is the final report code for the Microprocessor Application course at NTUST. All code is written in Verilog, with some Batchfiles included for automation or simulation tasks.

---

## 內容簡介 (Project Overview)

本專案內容涵蓋：
- 8051 微處理器設計與模擬
- MIPS 處理器設計與模擬
- 模組化設計與測試平台
- 基準測試與結果分析
- 自動化腳本與模擬結果彙整

This repository includes:
- 8051 microprocessor design and simulation
- MIPS processor design and simulation
- Modular design and testbenches
- Benchmarking and result analysis
- Automation scripts and simulation outputs

---

## 專案架構 (Project Structure)

```
.
├── 8051/                  # 8051 處理器相關設計與檔案 (8051 processor related design and files)
├── MIPS/                  # MIPS 處理器相關設計與檔案 (MIPS processor related design and files)
├── .gitattributes         # Git 屬性設定 (Git attributes configuration)
├── 8051_results.txt       # 8051 基準測試結果 (8051 benchmark results)
├── README.md              # 專案說明文件 (This file)
├── benchmark_8051.vcd     # 8051 測試波形檔 (8051 simulation waveform)
├── mips_benchmark         # MIPS 基準測試檔 (MIPS benchmark file)
├── pipeline_top.v         # MIPS Pipeline 架構頂層 (MIPS pipeline top module)
├── processor_8051.v       # 8051 處理器主程式 (8051 processor main module)
├── run_benchmarks.bat     # 自動化基準測試腳本 (Automation batch script for benchmarks)
├── testbench.v            # 通用測試平台 (General testbench)
└── testbench_8051.v       # 8051 測試平台 (8051 testbench)
```

---

## 快速開始 (Getting Started)

### 安裝需求 (Requirements)

- Verilog 編譯器（如 Icarus Verilog, ModelSim, Vivado 等）
- 可執行 Batchfile 的 Windows 環境 (Windows environment for Batchfiles)

### 執行方式 (How to Run)

1. 進入 `src/` 資料夾，檢查 Verilog 原始碼。
2. 使用模擬工具執行 `sim/` 目錄下的測試檔案。
3. 若需自動化流程，可於 Windows 環境下執行 `batch/` 內批次檔。

1. Enter the `src/` folder to review Verilog source code.
2. Use your simulator to run the testbenches in the `sim/` directory.
3. For automation, run Batchfiles in the `batch/` directory under Windows.
