# mkcvm
A script for compiling CollabVM server and webapp so that you have to enter just one command

# Supported distros
Currently Ubuntu and Arch Linux are supported. The script will detect your distro automatically (by checking the presence of a package manager).

For now it is assumed that if you have `apt`, you are using Ubuntu, and if you have `pacman`, you are using Arch.

# How to use
1. Download the file: `curl -Lk http://tiny.cc/mkcvm -o mkcvm.sh`
   
   **Or if the short link doesn't work: `curl -Lk https://raw.githubusercontent.com/totallyNotAUser/mkcvm/main/mkcvm.sh -o mkcvm.sh`**
2. Make it executable: `chmod +x mkcvm.sh`
3. Run it: `./mkcvm.sh`

It is recommended ***not*** to run it as sudo, it will request root permissions automatically.
