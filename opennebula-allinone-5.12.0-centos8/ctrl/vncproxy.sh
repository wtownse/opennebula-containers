#!/bin/bash
ps -ef | grep webso2ckify | grep -v grep

if [ $? -ne 0 ]
then
/usr/bin/novnc-server start
fi
