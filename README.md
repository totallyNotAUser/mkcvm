# mkcvm
A script for compiling CollabVM server and webapp so that you have to enter just one command

# Supported distros
Currently Ubuntu and Arch Linux are supported. The script will detect your distro automatically (by checking the presence of a package manager).

For now it is assumed that if you have `apt`, you are using Ubuntu, and if you have `pacman`, you are using Arch.

# How to use
Just download the file, make it executable (`chmod +x mkcvm.sh`) and run it (`./mkcvm.sh`).

It is recommended ***not*** to run it as sudo, it will request root permissions automatically.
