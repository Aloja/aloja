#!/bin/bash

start_location=/users/scratch/pristine/share
ES_host=aloja.bsc.es:9200

if [ ! "$1" ] ; then
        bench="BigBench"
else
        bench="$1"
fi

if [ ! "$2" ] ; then
	cluster=""
else
	cluster="$2"
fi

get_successful_jobs(){
        for folder in ${start_location}/jobs_$cluster*; do
                if [ -d "$folder" ] ; then
			    echo "Checking cluster ${folder##*_}" >> /dev/tty
                        for job in ${folder}/*; do
                                 if [ -f "$job/config.sh" ] && \
                                   awk -F "=" -v bench=$bench '/^BENCH_SUITE/ && $2 == bench {++found;exit} END {exit !found}' "$job/config.sh" ; then
                                        failed="false"
                                        benches=("$(awk -F "=" '/^BENCH_LIST/  {gsub("[\47]","",$2); print $2}' "$job/config.sh")")
                                        for sub_bench in ${benches[@]}; do
                                                if find "$job" -type f -name "*$sub_bench.tar.bz2" | grep -q . ; then
                                                #       find "$job" -type f -name "*$sub_bench.tar.bz2"
                                                        :
                                                else
                                                        failed="true"
                                                fi
                                        done
                                        if [ "$failed" = "false" ]; then
                                                successful_jobs+=("$job")
                                        fi
                                fi
                        done
                fi
        done
	echo "${successful_jobs[@]}"

}

#MAIN CODE
jobs="$(get_successful_jobs)"
for job in ${jobs[@]} ; do
    curl -sS -X POST "$ES_host/_bulk?pretty" -H '^Cntent-Type: application/njson' --data-binary @"$(python "$(pwd)/../parsers/ES_parser.py" "$job")"
done
