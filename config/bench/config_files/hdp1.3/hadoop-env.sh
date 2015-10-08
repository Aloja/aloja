# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# The java implementation to use.  Required.
export JAVA_HOME=/usr/java/default
export HADOOP_HOME_WARN_SUPPRESS=1

# For LZO
export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/usr/lib/hadoop/lib/native/Linux-amd64-64

# Hadoop Configuration Directory
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop/conf}

# The maximum amount of heap to use, in MB. Default is 1000.
#export HADOOP_HEAPSIZE=

HADOOP_NAMENODE_OPTS=-Xmx1024m
HADOOP_DATANODE_OPTS=-Xmx1024m
HADOOP_JOBTRACKER_OPTS=-Xmx1024m
HADOOP_TASKTRACKER_OPTS=-Xmx1024m

# Extra Java runtime options.  Empty by default.
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true ${HADOOP_OPTS}"

# Command specific options appended to HADOOP_OPTS when specified
 export HADOOP_NAMENODE_OPTS="-server -XX:ErrorFile=/var/log/hadoop/$USER/hs_err_pid%p.log -Dhadoop.security.logger=INFO,DRFAS -Dhdfs.audit.logger=INFO,DRFAAUDIT ${HADOOP_NAMENODE_OPTS}"
 HADOOP_JOBTRACKER_OPTS="-server -XX:ErrorFile=/var/log/hadoop/$USER/hs_err_pid%p.log -Dhadoop.security.logger=INFO,DRFAS -Dmapred.audit.logger=INFO,MRAUDIT -Dhadoop.mapreduce.jobsummary.logger=INFO,JSA ${HADOOP_JOBTRACKER_OPTS}"

 HADOOP_TASKTRACKER_OPTS="-server -Dhadoop.security.logger=ERROR,console -Dmapred.audit.logger=ERROR,console ${HADOOP_TASKTRACKER_OPTS}"
 HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,DRFAS ${HADOOP_DATANODE_OPTS}"
 HADOOP_BALANCER_OPTS="-server -Xmx1024m ${HADOOP_BALANCER_OPTS}"

export HADOOP_SECONDARYNAMENODE_OPTS="-server -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:ErrorFile=/var/log/hadoop/$USER/hs_err_pid%p.log -XX:NewSize=640m -XX:MaxNewSize=640m -Xloggc:/var/log/hadoop/$USER/gc.log-`date +'%Y%m%d%H%M'` -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps ${HADOOP_NAMENODE_INIT_HEAPSIZE} -Xmx1G -Dhadoop.security.logger=INFO,DRFAS -Dhdfs.audit.logger=INFO,DRFAAUDIT ${HADOOP_SECONDARYNAMENODE_OPTS}"

# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
export HADOOP_CLIENT_OPTS="$hadoop_heapsize ${HADOOP_CLIENT_OPTS}"
#HADOOP_JAVA_PLATFORM_OPTS="-XX:-UsePerfData ${HADOOP_JAVA_PLATFORM_OPTS}"

# On secure datanodes, user to run the datanode as after dropping privileges
#export HADOOP_SECURE_DN_USER=hdfs

# Extra ssh options.  Empty by default.
export HADOOP_SSH_OPTS="-o ConnectTimeout=5 -o SendEnv=HADOOP_CONF_DIR"

# Where log files are stored.  $HADOOP_HOME/logs by default.
export HADOOP_LOG_DIR=/var/log/hadoop/$USER


# Where log files are stored in the secure data environment.
export HADOOP_SECURE_DN_LOG_DIR=/var/log/hadoop/$HADOOP_SECURE_DN_USER

# File naming remote slave hosts.  $HADOOP_HOME/conf/slaves by default.
# export HADOOP_SLAVES=${HADOOP_HOME}/conf/slaves

# host:path where hadoop code should be rsync'd from.  Unset by default.
# export HADOOP_MASTER=master:/home/$USER/src/hadoop

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
# export HADOOP_SLAVE_SLEEP=0.1

# The directory where pid files are stored. /tmp by default.
export HADOOP_PID_DIR=/var/run/hadoop/$USER
export HADOOP_SECURE_DN_PID_DIR=/var/run/hadoop/$HADOOP_SECURE_DN_USER

# A string representing this instance of hadoop. $USER by default.
export HADOOP_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.

# export HADOOP_NICENESS=10
