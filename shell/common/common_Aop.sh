
aop_post_process() {


#    echo "##################################################"
#    echo "### merging logs #################################"
#    echo "##################################################"
#
#    cd $JOB_PATH
#    ls $JOB_PATH/*tar.bz2 | xargs -n1 tar -xjf
#    mkdir -p $JOB_PATH/merged_logs
#    local BENCHS=$( ls -I "*conf*" | grep tar.bz2 )
#    for tmp_bench in $BENCHS ; do
#        FOLDER=$( basename $tmp_bench .tar.bz2 )
#        cd $JOB_PATH/$FOLDER
#        echo `pwd`
#        cat $JOB_PATH/$FOLDER/aloja/hadoop.log >> $JOB_PATH/merged_logs/merged.log
#    done

    echo "##################################################"
    echo "### post-processing log ##########################"
    echo "##################################################"

    #python $ALOJA_REPO_PATH/aloja-web/Chord/data/changeLog.py $JOB_PATH

}
