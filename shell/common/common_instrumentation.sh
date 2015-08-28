#INSTUMENTATION SPECIFIC FUNCTIONS

instrumentation_set_perms() {
  logger "INFO: Setting permissions for instrumentation's sniffer"
  $DSH "sudo apt-get install -y binutils-dev"
  $DSH "sudo -n setcap cap_net_raw=eip ${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/bin/sniffer"
}

stop_sniffer(){
  $DSH "killall sniffer" 2> /dev/null |tee -a $LOG_PATH
}

instrumentation_post_process() {

  stop_sniffer

  # Emulate vars.sh from instrumentation project setting the required environment variables
  local EXTRAE_DIR="${HDD}/traces"
  local BIN_DIR="${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/bin"
  local LIB_DIR="${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/lib"
  local JAVA="${JAVA_HOME}/bin/java"
  # Has to be an export because Undef2prv has to read it
  export TRACES_OUTPUT="${JOB_PATH}/traces"

  echo "##################################################"
  echo "### POST PROCESS DUMPINGD ########################"
  echo "##################################################"

  #dumping: filtrado del volcado del lsof
  while read node
  do
  ssh $node <<ENDSSH
  cp $EXTRAE_DIR/dumping-host-port-pid $EXTRAE_DIR/dumping-host-port-pid.unfiltered
  cat $EXTRAE_DIR/dumping-host-port-pid.unfiltered | grep -v COMMAND | grep -v LISTEN | grep java | tr -s ' ' | sed -e 's/:/ /g' | sed -e 's/->/ /g' | cut -d ' ' -f 2,9,10 | sed -e 's/ /:/g' >> $EXTRAE_DIR/dumping-host-port-pid.filtered
  cat $EXTRAE_DIR/dumping-host-port-pid.unfiltered | grep -v COMMAND | grep LISTEN | grep java | tr -s ' ' | sed -e 's/:/ /g' | sed -e 's/->/ /g' | cut -d ' ' -f 2,9,10 | sed -e 's/ /:/g'  >> $EXTRAE_DIR/dumping-host-port-pid.filtered
  cp $EXTRAE_DIR/dumping-host-port-pid.filtered $EXTRAE_DIR/dumping-host-port-pid_unsorted
  sort -k1,3 -u  $EXTRAE_DIR/dumping-host-port-pid_unsorted   > $EXTRAE_DIR/dumping-host-port-pid_sorted
  cat $EXTRAE_DIR/dumping-host-port-pid_sorted | eval sed 's/[^:]*/\$(hostname --ip-address)/'2 > $EXTRAE_DIR/dumping-host-port-pid.lsof
ENDSSH
  done <<< "$node_names"

  #get dumping-host-port-pid from hadoop nodes
  mkdir -p $TRACES_OUTPUT/distributed-merge
  while read node
  do
  scp $node:$EXTRAE_DIR/dumping-host-port-pid.lsof $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid_$node.lsof
  done <<< "$node_names"

  #merge all nodes dumping-host-port-pid into a unique
  rm -f $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid
  for f in `ls -d $TRACES_OUTPUT/distributed-merge/* | grep dumping-host-port-pid_`
  do
  cat $f >> $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid
  done



  echo "##################################################"
  echo "### POST PROCESS EXTRAE TRACES ###################"
  echo "##################################################"

  #get extrae traces from hadoop nodes
  rm -f $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  while read node
  do
  rm -rf $TRACES_OUTPUT/distributed-merge/$node
  mkdir -p $TRACES_OUTPUT/distributed-merge/$node
  scp -r $node:$EXTRAE_DIR/set-* $TRACES_OUTPUT/distributed-merge/$node
  scp -r $node:$EXTRAE_DIR/TRACE.mpits $TRACES_OUTPUT/distributed-merge/$node
  for f in $TRACES_OUTPUT/distributed-merge/$node/set-*/*mpit
  do
  echo $f on minerva-$node named>> $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  echo "--" >> $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  done
  done <<< "$node_names"

  #quito el ultimo -- para que mpi2prv no me de error
  cp $TRACES_OUTPUT/distributed-merge/TRACE.mpits $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp
  head -n -1 $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp > $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  rm $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp

  #Generacion de todos los mpits con el TRACE.mpits separados por apps
  ${BIN_DIR}/mpi2prv -no-syn -f $TRACES_OUTPUT/distributed-merge/TRACE.mpits -o $TRACES_OUTPUT/mergeoutput.prv



  echo "##################################################"
  echo "### POST PROCESS SYSSTAT #########################"
  echo "##################################################"

  rm -f $TRACES_OUTPUT/sar*.txt
  rm -f $TRACES_OUTPUT/sysstat*.txt
  while read node
  do

  sadf_version=$(echo `sadf -V` | cut --delimiter=' ' --fields=3)
  sadf_version=( ${sadf_version//./ } )
  # if version is 10.1.1 or newer
  if (( ${sadf_version[0]} >= "10" )) && (( ${sadf_version[1]} >= "1" )) ; then
    sadf -d -h -U $TRACES_OUTPUT/sar-$node.sar -- -u -B -r -q > $TRACES_OUTPUT/sar-$node.txt
  else
    sadf -d -h -T $TRACES_OUTPUT/sar-$node.sar -- -u -B -r -q > $TRACES_OUTPUT/sar-$node.txt
  fi

  sed -i '1d' $TRACES_OUTPUT/sar-$node.txt
  ip=$(ssh -n $node "hostname --ip-address")
  awk -v "IP=$ip" '{$1=IP}1' FS=';' OFS=';' $TRACES_OUTPUT/sar-$node.txt >> $TRACES_OUTPUT/sar.txt
  done <<< "$node_names"



  echo "##################################################"
  echo "### POST PROCESS UNDEF2PRV #######################"
  echo "##################################################"

  #clean log files
  rm -f $TRACES_OUTPUT/undef2prv.log*

  #execute the undef2prv post-processing
  #procesa els ports i els genera al output
  ${JAVA} -Xmx1536m -cp "${LIB_DIR}/*" es.bsc.tools.undef2prv.Undef2prv $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid $TRACES_OUTPUT/mergeoutput.prv $TRACES_OUTPUT/mergeoutput.row $TRACES_OUTPUT/mergeoutput.pcf $TRACES_OUTPUT/sar.txt

}