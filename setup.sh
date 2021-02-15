#!/bin/bash
apt update && apt-get install -y device-tree-compiler lz4c
git clone https://github.com/Laulan56/anykernel.git /drone/src/anykernel3 --branch b1c1 --depth 1
