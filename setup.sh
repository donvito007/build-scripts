#!/bin/bash

if [ $DRONE_COMMIT_BRANCH -eq raphael-q ];
  then
    git clone https://github.com/Laulan56/anykernel.git /drone/src/anykernel3 --branch raphael-q --depth 1
else
    git clone https://github.com/Laulan56/anykernel.git /drone/src/anykernel3 --branch miui-q --depth 1
fi
