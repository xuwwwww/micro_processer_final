# 微算機應用期末報告 (Microprocessor Application Final Project)

本專案為台科大微算機應用課程的期末報告，所有代碼以 Verilog 撰寫，並包含部分 Batchfile 用於自動化流程或模擬。  
This project is the final report code for the Microprocessor Application course at NTUST. All code is written in Verilog, with some Batchfiles included for automation or simulation tasks.

---

## 內容簡介 (Project Overview)

本專案內容涵蓋：
- 微算機系統核心設計
- 模組化設計與測試
- 簡易自動化腳本
- 完整測試環境配置

This repository includes:
- Microprocessor system core design
- Modular design and unit testing
- Simple automation scripts
- Complete testbench setup

---

## 專案結構 (Project Structure)

```
├── src/                  # Verilog 原始碼 (Verilog source code)
├── sim/                  # 測試檔案與模擬腳本 (Simulation files & scripts)
├── batch/                # 批次檔、自動化腳本 (Batch scripts for automation)
├── doc/                  # 文件與報告 (Documentation & report)
└── README.md             # 專案說明文件 (This file)
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
