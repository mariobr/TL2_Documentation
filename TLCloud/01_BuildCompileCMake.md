# CMAKE
## install
- sudo apt install zenity
- sudo apt install build-essential
- sudo apt-get install pkg-config
- sudo apt install cmake
- sudo apt install ninja-build
- sudo apt install -y gcc
- sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
- sudo apt install -y g++-13
- sudo apt-get install libssl-dev

## build Release
- cmake --list-presets all
- cmake --preset *configuration*
- *cmake --build --preset win64-debug*
- cmake --build --preset *build-preset*
- ctest --preset *test-preset*

# Windows for VS Code 
## Independent of Visual Studio
- winget install Kitware.CMake
- winget install Ninja-build.Ninja
- VSCode addins

# Visual Studio 2022
## Compiler Architecture Macros
* https://sourceforge.net/p/predef/wiki/Architectures/
## Reset Intellisense
- Tools -> Options -> [type in "database" in the search box] -> Text Editor -> C/C++ -> Advanced -> Recreate Database = TRUE, and then reopen the solution. 

## VSCode 
### Linux using git - look at Git.md
- git clone git@github.com:mariobr/TL2.git
- sudo code . --user-data-dir='/home/devroot/VSCODE'
- https://stackoverflow.com/questions/40033311/how-to-debug-programs-with-sudo-in-vscode
 
### Compiler GCC 13 (C++ 20)
- https://lindevs.com/install-g-on-ubuntu
- g++ is a symbolic link
- sudo rm /usr/bin/g++
- sudo ln -s g++-13 /usr/bin/g++
- https://askubuntu.com/questions/706522/g-not-installed-even-after-installing-it-sudo-apt-get-install-g
## DevContainer
- Use VSCode !!
- code . --no-sandbox --user-data-dir /home/mariobr/vscode/


## VMWare
* CD/DVD map to IDE not SATA -> crashes Windows
* https://communities.vmware.com/t5/VMware-Workstation-Pro/Windows-10-crashes-on-Vmware-Workstation-10/td-p/2757527
* Visual Studio Setup 
	ASP.net + C++

