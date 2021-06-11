#for file in inifiles/*.ini ; do
for file in todo/*.ini ; do
	sleep 1
	sbatch meteor_wrapper.sh $file
done
