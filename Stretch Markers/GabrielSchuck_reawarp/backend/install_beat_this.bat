@echo off
rem reawarp - installs the Beat This! beat detector in this folder.
rem No Python installation is needed: uv downloads a private Python here.
rem Copyright (C) 2026 Gabriel Schuck. GPL-3.0-or-later (see LICENSE).
rem Arguments: [gpu^|cpu] [auto]
rem   gpu: PyTorch for NVIDIA graphics cards (about 2.5 GB); cpu: about 300 MB.
rem   Without one it keeps the kind already installed (cpu on a new install).
rem   auto: started by reawarp. The window closes at the end and reawarp shows the
rem   result (install_status.txt: "ok <device>" or "fail"). The details of every
rem   step go to install.log.
setlocal
set "KIND=%~1"
set "AUTO=%~2"
if /i "%KIND%"=="auto" (set "KIND=" & set "AUTO=auto")
cd /d "%~dp0"
set "LOG=%CD%\install.log"
set "STATUS=%CD%\install_status.txt"
if exist "%STATUS%" del "%STATUS%"
echo reawarp: Beat This! installation> "%LOG%"
call :say reawarp: installing the Beat This! beat detector.
call :say This downloads about 350 MB and needs about 1 GB of disk space
call :say (the version for NVIDIA graphics cards: about 2.5 GB, and 3 GB of disk).
call :say Everything goes inside this folder; no Python installation is needed.
if /i "%AUTO%"=="auto" call :say This window closes by itself when the installation ends.
echo.

set "UV_VERSION=0.12.20"
set "UV_TARGET=x86_64-pc-windows-msvc"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "UV_TARGET=aarch64-pc-windows-msvc"
set "UV=%CD%\uv\uv.exe"
rem keep uv's Python, cache and tools inside this folder, and never use a system Python
set "UV_PYTHON_INSTALL_DIR=%CD%\python"
set "UV_CACHE_DIR=%CD%\uvcache"
set "UV_PYTHON_PREFERENCE=only-managed"
set "UV_NO_CONFIG=1"
rem Windows' own tar (it opens .zip files; another tar on the PATH may not)
set "TAR=tar"
if exist "%SystemRoot%\System32\tar.exe" set "TAR=%SystemRoot%\System32\tar.exe"

if not exist "%UV%" (
  call :say Downloading uv %UV_VERSION%...
  if not exist uv mkdir uv
  curl -L --fail -sS -o "uv\uv.zip" "https://github.com/astral-sh/uv/releases/download/%UV_VERSION%/uv-%UV_TARGET%.zip" >> "%LOG%" 2>&1 || goto fail
  "%TAR%" -xf "uv\uv.zip" -C uv >> "%LOG%" 2>&1 || goto fail
  del "uv\uv.zip"
)
if not exist "%UV%" goto fail

rem --allow-existing keeps the installed packages and repairs an env whose folder was moved
call :say Installing Python...
"%UV%" venv env --python 3.12 --allow-existing >> "%LOG%" 2>&1 || goto fail
rem the PyTorch build installed now: cpu, a CUDA version, or none
set "CUR="
for /f "delims=" %%v in ('env\Scripts\python.exe -c "import torch; print(torch.version.cuda or 0)" 2^>nul') do set "CUR=%%v"
if "%CUR%"=="0" set "CUR=cpu"
if not defined KIND (
  set "KIND=cpu"
  if defined CUR if /i not "%CUR%"=="cpu" set "KIND=keep"
)
set "INDEX=cpu"
if /i "%KIND%"=="gpu" call :cuda_index
set "REINSTALL="
if /i "%KIND%"=="keep" goto torch_install
if /i "%INDEX%"=="cpu" (
  if defined CUR if /i not "%CUR%"=="cpu" set "REINSTALL=--reinstall-package torch --reinstall-package torchaudio"
) else (
  if /i "%CUR%"=="cpu" set "REINSTALL=--reinstall-package torch --reinstall-package torchaudio"
)
:torch_install
if /i "%KIND%"=="keep" (
  call :say PyTorch for the GPU is already installed.
) else (
  if /i "%INDEX%"=="cpu" (call :say Installing PyTorch for the CPU...) else (call :say Installing PyTorch for the NVIDIA GPU [%INDEX%], about 2.5 GB. This takes a while...)
  "%UV%" pip install --python "env\Scripts\python.exe" torch torchaudio --index-url https://download.pytorch.org/whl/%INDEX% %REINSTALL% >> "%LOG%" 2>&1 || goto fail
)
call :say Installing Beat This!...
"%UV%" pip install --python "env\Scripts\python.exe" beat-this==1.1.0 >> "%LOG%" 2>&1 || goto fail
call :say Downloading the model...
"env\Scripts\python.exe" reawarp_beat_this.py --download >> "%LOG%" 2>&1 || goto fail
set "DEVICE=cpu"
for /f "delims=" %%d in ('env\Scripts\python.exe reawarp_beat_this.py --device 2^>nul') do set "DEVICE=%%d"
if exist uvcache rmdir /s /q uvcache
call :say Done. Beat This! runs on: %DEVICE%.
echo ok %DEVICE%> "%STATUS%"
rem started by reawarp (cmd /k): "exit" closes the window too
if /i "%AUTO%"=="auto" exit 0
echo.
pause
exit /b 0

:say
rem a progress line, on the screen and in the log
echo %*
>> "%LOG%" echo %*
goto :eof

:cuda_index
rem the newest CUDA build that the NVIDIA driver supports
set "DRV="
for /f "tokens=1 delims=." %%a in ('nvidia-smi --query-gpu^=driver_version --format^=csv^,noheader 2^>nul') do if not defined DRV set "DRV=%%a"
if not defined DRV (
  call :say No NVIDIA graphics card found: installing the CPU version.
  goto :eof
)
if %DRV% GEQ 580 (set "INDEX=cu130" & goto :eof)
if %DRV% GEQ 570 (set "INDEX=cu128" & goto :eof)
if %DRV% GEQ 560 (set "INDEX=cu126" & goto :eof)
call :say The NVIDIA driver is too old for the GPU version: installing the CPU version.
goto :eof

:fail
rem (the download cache stays, so a retry does not download everything again)
call :say The installation failed. It needs an internet connection; you can run it again to retry.
echo fail> "%STATUS%"
if /i "%AUTO%"=="auto" exit 1
echo.
echo Details:
type "%LOG%"
echo.
pause
exit /b 1
