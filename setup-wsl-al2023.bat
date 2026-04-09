@echo off
:: ---------------------------------------------
::  AL2023 WSL Setup Script -- Run as Administrator
:: ---------------------------------------------

setlocal EnableDelayedExpansion

set DEFAULT_TAR=C:\WSL\al2023-wsl.tar
set TAR_PATH=
set SERVER_NAME=

echo.
echo =========================================
echo    Amazon Linux 2023 WSL Setup
echo =========================================
echo.

:: -- Determine TAR source ----------------------
if exist "%DEFAULT_TAR%" (
    echo [*] Found: %DEFAULT_TAR%
    echo.
    set TAR_PATH=%DEFAULT_TAR%
    goto ASK_SERVER_NAME
)

echo [*] No al2023-wsl.tar found at default location.
echo.
set /p USER_CHOICE="  (1) Provide TAR file  or  (2) Pull from Docker? [1/2] (default: 2): "
if "!USER_CHOICE!"=="" set USER_CHOICE=2
if "!USER_CHOICE!"=="1" goto GET_TAR_PATH
if "!USER_CHOICE!"=="2" goto DOCKER_PULL
echo   [ERROR] Invalid choice. Please enter 1 or 2.
pause
exit /b 1

:GET_TAR_PATH
set /p TAR_PATH="  Path to al2023-wsl.tar: "
set TAR_PATH=!TAR_PATH:"=!
if not exist "!TAR_PATH!" (
    echo   [!] File not found, try again.
    goto GET_TAR_PATH
)
goto ASK_SERVER_NAME

:DOCKER_PULL
call :DO_DOCKER_PULL
set TAR_PATH=%DEFAULT_TAR%

:ASK_SERVER_NAME
set /p SERVER_NAME="  Enter server name (default: AmazonLinux2023): "
if "!SERVER_NAME!"=="" set SERVER_NAME=AmazonLinux2023
wsl --list 2>nul | findstr /i "!SERVER_NAME!" >nul
if %ERRORLEVEL%==0 (
    echo.
    echo   [!] Server '!SERVER_NAME!' already exists.
    set /p OVERRIDE="  Override it? [y/n] (default: n): "
    if "!OVERRIDE!"=="" set OVERRIDE=n
    if /i not "!OVERRIDE!"=="y" goto ASK_SERVER_NAME
    echo   Will override.
)

:: -- Main Setup --------------------------------
set INSTALL_DIR=C:\WSL\!SERVER_NAME!
echo.

echo [1/5] Setting WSL default version to 2...
wsl --set-default-version 2 2>nul
echo   Done

echo [2/5] Removing existing server (if any)...
wsl --list 2>nul | findstr /i "!SERVER_NAME!" >nul
if %ERRORLEVEL%==0 (
    wsl --unregister !SERVER_NAME! 2>nul
    echo   Removed existing server
) else (
    echo   No existing server found
)

echo [3/5] Importing AL2023 into WSL...
if not exist "!INSTALL_DIR!" mkdir "!INSTALL_DIR!"
wsl --import !SERVER_NAME! "!INSTALL_DIR!" "!TAR_PATH!" --version 2 2>nul
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Import failed. Please check the tar file and try again.
    pause
    exit /b 1
)
echo   Imported successfully to !INSTALL_DIR!

echo [4/5] Configuring server (wsl.conf + ec2-user)...

:: Write wsl.conf using printf inside WSL (run as root - default user not set yet)
wsl -d !SERVER_NAME! -u root /bin/sh -c "printf '[automount]\nenabled = false\nmountFsTab = false\n\n[boot]\nsystemd = true\n\n[interop]\nenabled = false\nappendWindowsPath = false\n\n[user]\ndefault = ec2-user\n' > /etc/wsl.conf" 2>nul
echo   wsl.conf written

:: Install shadow-utils BEFORE restart (still running as root at this point)
echo   Installing user management tools...
wsl -d !SERVER_NAME! -u root dnf install -y shadow-utils 2>nul

:: Create ec2-user before restart
echo   Creating ec2-user...
wsl -d !SERVER_NAME! -u root /bin/bash -c "useradd -m -s /bin/bash ec2-user 2>/dev/null; usermod -aG wheel ec2-user 2>/dev/null; mkdir -p /etc/sudoers.d; echo 'ec2-user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ec2-user; chmod 0440 /etc/sudoers.d/ec2-user" 2>nul
wsl -d !SERVER_NAME! -u root id ec2-user >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   ec2-user created successfully
) else (
    echo   [!] ec2-user creation failed - launch as root and run: useradd -m -s /bin/bash ec2-user
)

:: Full WSL shutdown so systemd starts as PID 1 on next boot
echo   Restarting WSL (full shutdown to enable systemd)...
wsl --shutdown 2>nul
timeout /t 3 /nobreak >nul

echo [5/5] Package Installation
echo.
echo   Packages: git, wget, unzip, sudo, tar, python3, pip, curl, ncurses, openssh-server, AWS CLI v2
echo.
set /p INSTALL_PACKAGES="  Install packages? [y/n] (default: y): "
if "!INSTALL_PACKAGES!"=="" set INSTALL_PACKAGES=y

if /i "!INSTALL_PACKAGES!"=="y" (
    echo   Updating system packages...
    wsl -d !SERVER_NAME! -u root dnf update -y --skip-broken 2>nul
    echo   Installing core tools...
    wsl -d !SERVER_NAME! -u root dnf install -y git wget unzip sudo tar python3 python3-pip curl ncurses openssh-server --allowerasing --skip-broken 2>nul
    :: Enable and configure sshd
    wsl -d !SERVER_NAME! -u root /bin/bash -c "ssh-keygen -A 2>/dev/null; systemctl enable sshd 2>/dev/null" 2>nul
    echo   Installing AWS CLI v2...
    wsl -d !SERVER_NAME! -u root /bin/bash -c "cd /tmp && curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip && unzip -oq awscliv2.zip && ./aws/install --update && rm -rf awscliv2.zip aws/" 2>nul
    echo   Configuring Git defaults...
    wsl -d !SERVER_NAME! -u ec2-user git config --global core.autocrlf input 2>nul
    wsl -d !SERVER_NAME! -u ec2-user git config --global init.defaultBranch main 2>nul

    echo   Configuring shell environment...
    :: Set hostname to match server name
    wsl -d !SERVER_NAME! -u root /bin/bash -c "echo '!SERVER_NAME!' > /etc/hostname; hostname '!SERVER_NAME!'" 2>nul
    :: Write .bashrc for ec2-user - start in home dir, AWS-style prompt
    wsl -d !SERVER_NAME! -u root /bin/bash -c "cat > /home/ec2-user/.bashrc << 'EOF'
# Start in home directory (prevents inheriting Windows cwd)
cd ~

# AWS-style prompt: [ec2-user@servername ~]$
PS1='[\u@\h \W]\$ '

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'

export EDITOR=vi
export HISTSIZE=1000
export HISTFILESIZE=2000
EOF
chown ec2-user:ec2-user /home/ec2-user/.bashrc" 2>nul
    echo.
    echo   Verifying installed tools...
    wsl -d !SERVER_NAME! -u root git --version 2>nul && echo   git     : OK || echo   git     : FAILED
    wsl -d !SERVER_NAME! -u root python3 --version 2>nul && echo   python3 : OK || echo   python3 : FAILED
    wsl -d !SERVER_NAME! -u root curl --version >nul 2>nul && echo   curl    : OK || echo   curl    : FAILED
    wsl -d !SERVER_NAME! -u root aws --version 2>nul && echo   aws     : OK || echo   aws     : FAILED
    echo   All packages installed
) else (
    echo   Skipped.
)

:: Final full shutdown so everything starts clean with systemd
wsl --shutdown 2>nul

echo.
echo =========================================
echo   Setup Complete!
echo =========================================
echo.
echo   Server : !SERVER_NAME!
echo   Path   : !INSTALL_DIR!
echo.
echo   Launch:   wsl -d !SERVER_NAME! --cd ~
echo.

endlocal
goto :EOF


:: ---------------------------------------------
:DO_DOCKER_PULL
echo   Pulling amazonlinux:2023 from Docker...
docker pull amazonlinux:2023
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Docker pull failed. Ensure Docker Desktop is running.
    pause
    exit /b 1
)
docker run --name al2023-temp amazonlinux:2023 echo done >nul 2>&1
if not exist "C:\WSL" mkdir "C:\WSL"
docker export al2023-temp -o "%DEFAULT_TAR%"
docker rm al2023-temp >nul 2>&1
if not exist "%DEFAULT_TAR%" (
    echo   [ERROR] TAR file was not created.
    pause
    exit /b 1
)
echo   TAR created: %DEFAULT_TAR%
goto :EOF
