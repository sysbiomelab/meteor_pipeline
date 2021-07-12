for file in x*.ini ; do
	sleep 1
	sbatch meteor_wrapper.sh $file
done
