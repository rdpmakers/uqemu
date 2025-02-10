#!/bin/bash

echo "Installing uDocker..."
wget https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz
tar zxvf udocker-1.3.17.tar.gz
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
sed -i '1s|#!/usr/bin/env python|#!/usr/bin/env python3|' `pwd`/udocker-1.3.17/udocker/udocker
udocker install
# Setting execmode to runc
export UDOCKER_DEFAULT_EXECUTION_MODE=F4
# Fix runc execution issue
export XDG_RUNTIME_DIR=$HOME
echo "Installing the container"
cat qemu_part_* > qemu.tar
udocker import --clone --tocontainer --name=qemu qemu.tar
udocker setup --execmode=F4 qemu

# Setup
cat > ~/.udocker/container*/qemu/ROOT/boot.sh << EOF

#!/bin/bash
cd /qemu
max_retries=50
timeout=50
if [ ! -e /qemu/ubuntu-22.qcow2 ]; then
  wget --no-check-certificate --tries=$max_retries --timeout=$timeout --no-hsts -O ubuntu-22.qcow2 https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img
  qemu-img resize ubuntu-22.qcow2 +30G #The container will have 32GB storage in total
  mkdir /qemu-share
fi
/opt/start.sh

EOF


cat > start_container.sh << EOF

#!/bin/sh
export XDG_RUNTIME_DIR=$HOME
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
udocker setup --execmode=F4 qemu
udocker run qemu /bin/bash /boot.sh
EOF
chmod +x start_container.sh
echo "wait for 15 second, udocker may still extracting it"
sleep 15 #udocker still extracting it



echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will auto destroy."
rm qemu*
rm "$0"
