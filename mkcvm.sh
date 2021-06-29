#!/bin/sh

install_odb_aur() {
    echo [*] Downloading ODB from AUR
    git clone https://aur.archlinux.org/odb.git
    cd odb
    makepkg -sic
}

build_serv() {
    [ "$packageman" = pacman ] && install_odb_aur
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

# default args
default_tunnel_svc=lhr
# parse args
while [ "$#" -gt 0 ]
do
    case "$1" in
        --help) echo "Usage: $0 <options>"
                echo 'Options:'
                echo '--help                    Print this help'
                echo '-d, --distro <distro-id>  Force set distro'
                echo '    Currently supported distros:'
                echo '      | Distro Name | Distro-id |'
                echo '      | Ubuntu      | ubu       |'
                echo '      | Arch Linux  | arch      |'
                echo '-t, --default-tunnel-service <service>'
                echo '    Set a default tunneling service for the start script.'
                echo '    Currently supported tunneling services:'
                echo '      none - do not run a tunnel'
                echo '      localhost.run (default) - shorthand lhr'
                echo '      localtunnel (not tested yet) - shorthand lt'
                echo '    Keep in mind: you can always override it using the --tunnel-service (-t) option of the start script.'
                exit;;
        -d|--distro)
                distro_forced="yes"
                case "$2" in
                    ubu) distro="ubuntu";;
                    arch) distro="arch";;
                    *) echo "Unknown/unsupported distro $2"; exit 1;;
                esac
                shift 2;;
        -t|--default-tunnel-service)
                case "$2" in
                    none) default_tunnel_svc="none";;
                    localhost.run|lhr) default_tunnel_svc="lhr";;
                    localtunnel|lt) default_tunnel_svc="lt";;
                    *) echo "Unknown tunneling service $2"; exit 1;;
                esac
                shift 2;;
        *) echo "Unknown option $1. Use --help for help."
           exit 1;;
    esac
done

if [ "$distro_forced" = yes ]
then
    echo "[*] Distro forced by user: $distro"
    case "$distro" in
        ubu) packageman=apt;;
        arch) packageman=pacman;;
    esac
else
    echo '[*] Detecting package manager (distro)'
    if which apt > /dev/null 2>&1; then
        packageman=apt
    elif which pacman > /dev/null 2>&1; then
        packageman=pacman
    else
        echo '[!] Unknown package manager (only apt and pacman are supported), failing'
        exit 1
    fi
fi

cd ~
mkdir cvm
cd cvm
mkdir build-log
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
build_serv 2>&1 | tee ./build-log/server.log &

echo '[*] Building webapp (parallel)'
build_webapp 2>&1 | tee ./build-log/webapp.log &

wait

echo [*] Putting it all together
mkdir final
cd final
cp ../serv/bin/* ./ -r
cp ../webapp/build/* ./http -r

echo '[*] Fixing chat sound in webapp'
cd http
mkdir collab-vm
cp notify* collab-vm

echo [*] Making start script
cat > ~/cvm-start.sh << EOF
#!/bin/sh
# defaults
tunnel_svc=$default_tunnel_svc
while [ "\$#" -gt 0 ]
do
    case "\$1" in
        --help) echo "Usage: \$0 <options>"
                echo 'Start script for cvm server, built by mkcvm'
                echo 'Options:'
                echo '--help    Print this help'
                echo '-t, --tunnel-service <service>'
                echo '    Choose a different tunneling service'
                echo '    Currently supported tunneling services:'
                echo '      none - do not run a tunnel'
                echo '      localhost.run - shorthand lhr'
                echo '      localtunnel (not tested yet) - shorthand lt'
                echo "    Default set by mkcvm: $default_tunnel_svc"
                exit;;
        -t|--tunnel-service) 
                case "\$2" in
                    none) tunnel_svc="none";;
                    localhost.run|lhr) tunnel_svc="lhr";;
                    localtunnel|lt) tunnel_svc="lt";;
                    *) echo "Unknown tunneling service \$2"
                       exit 1;;
                esac
                shift 2;;
        *) echo "Unknown option \$1. Use --help for help."
           exit 1;;
    esac
done
cd ~/cvm/final
./collab-vm-server 8080 &
# run tunnel
case "\$tunnel_svc" in
    none) echo 'Running no tunneling service, as requested.';;
    lhr) ssh -R 80:localhost:8080 nokey@localhost.run;;
    lt) npx localtunnel --port 8080;;
esac
EOF
chmod +x ~/cvm-start.sh

echo '[*] Done. Start CVM server with ~/cvm-start.sh'
echo '[i] Server and webapp build logs are available at ~/cvm/build-log'
