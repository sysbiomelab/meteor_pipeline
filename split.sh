#!/bin/bash
mkdir -p inifiles
for sample in $(cat $2) ; do
	sed "s|sample=.*|sample=$sample|g" $1 > inifiles/$(basename $sample).ini
done
