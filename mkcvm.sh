#!/bin/sh

install_odb_aur() {
    echo [*] Downloading ODB from AUR
    git clone https://aur.archlinux.org/odb.git
    cd odb
    makepkg -sic
}

build_serv() {
    [[ "$packageman" == pacman ]] && install_odb_aur
    cd serv
    git reset --hard 1.2.10
    chmod +x ./scripts/grab_deps_linux.sh
    ./scripts/grab_deps_linux.sh
    make -j$(nproc)
    cd ..
}

build_webapp() {
    cd webapp
    sudo npm config -g set registry http://registry.npmjs.org
    sudo npm i -g gulp-cli
    npm i
    gulp
    cd ..
}

echo '[***]   mkcvm by totallyNotAUser   [***]'
echo '[***] Make a CVM mirror, and fast! [***]'
echo

echo '[*] Detecting package manager (distro)'
if which apt > /dev/null 2>&1; then
    packageman=apt
elif which pacman > /dev/null 2>&1; then
    packageman=pacman
else
    echo '[!] Unknown package manager (only apt and pacman are supported), failing'
    exit 1
fi

cd ~
mkdir cvm
cd cvm
echo [*] Installing build essentials
case "$packageman" in
    apt) sudo apt install -y build-essential git npm;;
    pacman) sudo pacman -S git npm base-devel --needed;;
    *) echo '[!!] How did we even get here??'; exit 1;;
esac

echo [*] Cloning repos
git clone http://github.com/computernewb/collab-vm-server
mv ./collab-vm-server serv
git clone http://github.com/computernewb/collab-vm-web-app
mv ./collab-vm-web-app webapp

echo '[*] Building server (parallel)'
build_serv &

echo '[*] Building webapp (parallel)'
build_webapp &

wait

echo [*] Putting it all together
mkdir final
cd final
cp ../serv/bin/* ./ -r
cp ../webapp/build/* ./http -r

echo [*] Making start script
cat > ~/cvm-start.sh << EOF
cd ~/cvm/final
nohup ./collab-vm-server 8080 &
ssh -R 80:localhost:8080 nokey@localhost.run
EOF
chmod +x ~/cvm-start.sh

echo '[*] Done. Start CVM server with ~/cvm-start.sh'
