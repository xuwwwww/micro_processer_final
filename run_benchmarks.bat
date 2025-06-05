@echo off
echo ===============================================
echo    MIPS vs 8051 Performance Benchmark
echo ===============================================

echo.
echo [1/4] Compiling MIPS...
iverilog -o mips_benchmark pipeline_top.v testbench.v
if %ERRORLEVEL% neq 0 (
    echo ERROR: MIPS compilation failed!
    pause
    exit /b 1
)

echo [2/4] Running MIPS benchmark...
vvp mips_benchmark > mips_results.txt
if %ERRORLEVEL% neq 0 (
    echo ERROR: MIPS simulation failed!
    pause
    exit /b 1
)

echo [3/4] Compiling 8051...
iverilog -o processor_8051_benchmark processor_8051.v testbench_8051.v
if %ERRORLEVEL% neq 0 (
    echo ERROR: 8051 compilation failed!
    pause
    exit /b 1
)

echo [4/4] Running 8051 benchmark...
vvp processor_8051_benchmark > 8051_results.txt
if %ERRORLEVEL% neq 0 (
    echo ERROR: 8051 simulation failed!
    pause
    exit /b 1
)

echo.
echo ===============================================
echo                 RESULTS
echo ===============================================
echo.
echo MIPS Results:
type mips_results.txt | findstr "Testbench:"
echo.
echo 8051 Results:  
type 8051_results.txt | findstr "8051"
echo.
echo VCD files generated:
echo - mips_branch_bench.vcd
echo - benchmark_8051.vcd
echo.
echo ===============================================
pause 