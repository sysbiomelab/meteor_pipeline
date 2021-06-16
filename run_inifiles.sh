for file in $1/*.ini ; do
	sleep 1
	sbatch meteor_wrapper.sh $file
done
