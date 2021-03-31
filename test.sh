#source <( awk '/\[/{prefix=$0; next} $1{print prefix $0}' gut_msp_pipeline.ini )
cat gut_msp_pipeline.ini
source gut_msp_pipeline.ini
echo $project
