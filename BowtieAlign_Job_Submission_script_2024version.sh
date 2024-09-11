
# This script assumes your csv and scripts are in the current working directory
# | tr -d '\r' -- put at the end before being written to output script object since is removes  the carriage return character (\r) from the output script. This is necessary because the sbatch command expects Unix line breaks (\n) instead of DOS line breaks (\r\n)

csv=$1
template=$2
script_dir=$(pwd)

template_job="_job_name_"
template_fastq="_fastq_gz_file_"

sed 1d $script_dir/$csv | awk '1; END {print ""}' | while read line || [ -n "$line" ]; do
    sample_job=$(echo $line | cut -d ',' -f 1)
    sample_fastq=$(echo $line | cut -d ',' -f 2)
    output_script=$script_dir/modified_bowtie_script_$sample_job.sh
    cat $script_dir/$template | sed "s:$template_job:$sample_job:g" | sed "s:$template_fastq:$sample_fastq:g" | tr -d '\r' > $output_script
    sbatch $output_script
done
