#CPU
logger "INFO: Updating CPU aggregates for new execs"

$MYSQL "
INSERT INTO aloja2.precal_cpu_metrics(id_exec,
\`avg%user\`,\`max%user\`,\`min%user\`,\`stddev_pop%user\`,\`var_pop%user\`,
\`avg%nice\`,\`max%nice\`,\`min%nice\`,\`stddev_pop%nice\`,\`var_pop%nice\`,
\`avg%system\`,\`max%system\`,\`min%system\`,\`stddev_pop%system\`,\`var_pop%system\`,
\`avg%iowait\`,\`max%iowait\`,\`min%iowait\`,\`stddev_pop%iowait\`,\`var_pop%iowait\`,
\`avg%steal\`,\`max%steal\`,\`min%steal\`,\`stddev_pop%steal\`,\`var_pop%steal\`,
\`avg%idle\`,\`max%idle\`,\`min%idle\`,\`stddev_pop%idle\`,\`var_pop%idle\`)
 SELECT e.id_exec,
 AVG(s.\`%user\`), MAX(s.\`%user\`), MIN(s.\`%user\`), STDDEV_POP(s.\`%user\`), VAR_POP(s.\`%user\`),
 AVG(s.\`%nice\`), MAX(s.\`%nice\`), MIN(s.\`%nice\`), STDDEV_POP(s.\`%nice\`), VAR_POP(s.\`%nice\`),
 AVG(s.\`%system\`), MAX(s.\`%system\`), MIN(s.\`%system\`), STDDEV_POP(s.\`%system\`), VAR_POP(s.\`%system\`),
 AVG(s.\`%iowait\`), MAX(s.\`%iowait\`), MIN(s.\`%iowait\`), STDDEV_POP(s.\`%iowait\`), VAR_POP(s.\`%iowait\`),
 AVG(s.\`%steal\`), MAX(s.\`%steal\`), MIN(s.\`%steal\`), STDDEV_POP(s.\`%steal\`), VAR_POP(s.\`%steal\`),
 AVG(s.\`%idle\`), MAX(s.\`%idle\`), MIN(s.\`%idle\`), STDDEV_POP(s.\`%idle\`), VAR_POP(s.\`%idle\`)
 FROM aloja2.execs e JOIN aloja_logs.SAR_cpu s USING (id_exec)
 WHERE e.id_exec NOT IN (SELECT id_exec FROM precal_cpu_metrics) GROUP BY (e.id_exec);"


#MEM
logger "INFO: Updating MEM aggregates for new execs"

$MYSQL "
INSERT INTO aloja2.precal_memory_metrics (id_exec,
   avgkbmemfree,maxkbmemfree,minkbmemfree,stddev_popkbmemfree,var_popkbmemfree,
   avgkbmemused,maxkbmemused,minkbmemused,stddev_popkbmemused,var_popkbmemused,
   \`avg%memused\`,\`max%memused\`,\`min%memused\`,\`stddev_pop%memused\`,\`var_pop%memused\`,
   avgkbbuffers,maxkbbuffers,minkbbuffers,stddev_popkbbuffers,var_popkbbuffers,
   avgkbcached,maxkbcached,minkbcached,stddev_popkbcached,var_popkbcached,
   avgkbcommit,maxkbcommit,minkbcommit,stddev_popkbcommit,var_popkbcommit,
   \`avg%commit\`,\`max%commit\`,\`min%commit\`,\`stddev_pop%commit\`,\`var_pop%commit\`,
   avgkbactive,maxkbactive,minkbactive,stddev_popkbactive,var_popkbactive,
   avgkbinact,maxkbinact,minkbinact,stddev_popkbinact,var_popkbinact
   )

 SELECT e.id_exec,
     AVG(su.kbmemfree), MAX(su.kbmemfree), MIN(su.kbmemfree), STDDEV_POP(su.kbmemfree), VAR_POP(su.kbmemfree),
     AVG(su.kbmemused), MAX(su.kbmemused), MIN(su.kbmemused), STDDEV_POP(su.kbmemused), VAR_POP(su.kbmemused),
     AVG(su.\`%memused\`), MAX(su.\`%memused\`), MIN(su.\`%memused\`), STDDEV_POP(su.\`%memused\`), VAR_POP(su.\`%memused\`),
     AVG(su.kbbuffers), MAX(su.kbbuffers), MIN(su.kbbuffers), STDDEV_POP(su.kbbuffers), VAR_POP(su.kbbuffers),
     AVG(su.kbcached), MAX(su.kbcached), MIN(su.kbcached), STDDEV_POP(su.kbcached), VAR_POP(su.kbcached),
     AVG(su.kbcommit), MAX(su.kbcommit), MIN(su.kbcommit), STDDEV_POP(su.kbcommit), VAR_POP(su.kbcommit),
     AVG(su.\`%commit\`), MAX(su.\`%commit\`), MIN(su.\`%commit\`), STDDEV_POP(su.\`%commit\`), VAR_POP(su.\`%commit\`),
     AVG(su.kbactive), MAX(su.kbactive), MIN(su.kbactive), STDDEV_POP(su.kbactive), VAR_POP(su.kbactive),
     AVG(su.kbinact), MAX(su.kbinact), MIN(su.kbinact), STDDEV_POP(su.kbinact), VAR_POP(su.kbinact)
FROM aloja_logs.SAR_memory_util su
JOIN aloja2.execs e USING (id_exec) JOIN aloja2.clusters c USING (id_cluster)
WHERE e.id_exec NOT IN (SELECT id_exec FROM aloja2.precal_memory_metrics) AND 1 GROUP BY (e.id_exec);"

#Disk
logger "INFO: Updating Disk aggregates for new execs"

$MYSQL "
INSERT INTO aloja2.precal_disk_metrics (id_exec,
  DEV, avgtps, maxtps, mintps,
  \`avgrd_sec/s\`,\`maxrd_sec/s\`,\`minrd_sec/s\`,\`stddev_poprd_sec/s\`,\`var_poprd_sec/s\`,\`sumrd_sec/s\`,
  \`avgwr_sec/s\`,\`maxwr_sec/s\`,\`minwr_sec/s\`,\`stddev_popwr_sec/s\`,\`var_popwr_sec/s\`,\`sumwr_sec/s\`,
  \`avgrq_sz\`,\`maxrq_sz\`,\`minrq_sz\`,\`stddev_poprq_sz\`,\`var_poprq_sz\`,
  \`avgqu_sz\`,\`maxqu_sz\`,\`minqu_sz\`,\`stddev_popqu_sz\`,\`var_popqu_sz\`,
  \`avgawait\`,\`maxawait\`,\`minawait\`,\`stddev_popawait\`,\`var_popawait\`,
  \`avg%util\`,\`max%util\`,\`min%util\`,\`stddev_pop%util\`,\`var_pop%util\`,
  \`avgsvctm\`,\`maxsvctm\`,\`minsvctm\`,\`stddev_popsvctm\`,\`var_popsvctm\`)
SELECT  e.id_exec, s.DEV,AVG(s.tps), MAX(s.tps), MIN(s.tps),
  AVG(s.\`rd_sec/s\`), MAX(s.\`rd_sec/s\`), MIN(s.\`rd_sec/s\`), STDDEV_POP(s.\`rd_sec/s\`), VAR_POP(s.\`rd_sec/s\`), SUM(s.\`rd_sec/s\`),
  AVG(s.\`wr_sec/s\`), MAX(s.\`wr_sec/s\`), MIN(s.\`wr_sec/s\`), STDDEV_POP(s.\`wr_sec/s\`), VAR_POP(s.\`wr_sec/s\`), SUM(s.\`wr_sec/s\`),
  AVG(s.\`avgrq-sz\`), MAX(s.\`avgrq-sz\`), MIN(s.\`avgrq-sz\`), STDDEV_POP(s.\`avgrq-sz\`), VAR_POP(s.\`avgrq-sz\`),
  AVG(s.\`avgqu-sz\`), MAX(s.\`avgqu-sz\`), MIN(s.\`avgqu-sz\`), STDDEV_POP(s.\`avgqu-sz\`), VAR_POP(s.\`avgqu-sz\`),
  AVG(s.await), MAX(s.\`await\`), MIN(s.\`await\`), STDDEV_POP(s.\`await\`), VAR_POP(s.\`await\`),
  AVG(s.\`%util\`), MAX(s.\`%util\`), MIN(s.\`%util\`), STDDEV_POP(s.\`%util\`), VAR_POP(s.\`%util\`),
  AVG(s.svctm), MAX(s.\`svctm\`), MIN(s.\`svctm\`), STDDEV_POP(s.\`svctm\`), VAR_POP(s.\`svctm\`)
  FROM aloja2.execs e JOIN  aloja_logs.SAR_block_devices s USING (id_exec) JOIN aloja2.clusters c USING (id_cluster)
  WHERE e.id_exec NOT IN (SELECT id_exec FROM precal_disk_metrics) GROUP BY (e.id_exec);"


#Net
logger "INFO: Updating Net aggregates for new execs"

$MYSQL "
INSERT INTO precal_network_metrics(id_exec,
  IFACE,
  \`avgrxpck/s\`,\`maxrxpck/s\`,\`minrxpck/s\`,\`stddev_poprxpck/s\`,\`var_poprxpck/s\`,\`sumrxpck/s\`,
  \`avgtxpck/s\`,\`maxtxpck/s\`,\`mintxpck/s\`,\`stddev_poptxpck/s\`,\`var_poptxpck/s\`,\`sumtxpck/s\`,
  \`avgrxkB/s\`,\`maxrxkB/s\`,\`minrxkB/s\`,\`stddev_poprxkB/s\`,\`var_poprxkB/s\`,\`sumrxkB/s\`,
  \`avgtxkB/s\`,\`maxtxkB/s\`,\`mintxkB/s\`,\`stddev_poptxkB/s\`,\`var_poptxkB/s\`,\`sumtxkB/s\`,
  \`avgrxcmp/s\`,\`maxrxcmp/s\`,\`minrxcmp/s\`,\`stddev_poprxcmp/s\`,\`var_poprxcmp/s\`,\`sumrxcmp/s\`,
  \`avgtxcmp/s\`,\`maxtxcmp/s\`,\`mintxcmp/s\`,\`stddev_poptxcmp/s\`,\`var_poptxcmp/s\`,\`sumtxcmp/s\`,
  \`avgrxmcst/s\`,\`maxrxmcst/s\`,\`minrxmcst/s\`,\`stddev_poprxmcst/s\`,\`var_poprxmcst/s\`,\`sumrxmcst/s\`
)
SELECT e.id_exec,
  s.IFACE,AVG(s.\`rxpck/s\`),MAX(s.\`rxpck/s\`),MIN(s.\`rxpck/s\`),STDDEV_POP(s.\`rxpck/s\`),VAR_POP(s.\`rxpck/s\`),SUM(s.\`rxpck/s\`),
  AVG(s.\`txpck/s\`),MAX(s.\`txpck/s\`),MIN(s.\`txpck/s\`),STDDEV_POP(s.\`txpck/s\`),VAR_POP(s.\`txpck/s\`),SUM(s.\`txpck/s\`),
  AVG(s.\`rxkB/s\`),MAX(s.\`rxkB/s\`),MIN(s.\`rxkB/s\`),STDDEV_POP(s.\`rxkB/s\`),VAR_POP(s.\`rxkB/s\`),SUM(s.\`rxkB/s\`),
  AVG(s.\`txkB/s\`),MAX(s.\`txkB/s\`),MIN(s.\`txkB/s\`),STDDEV_POP(s.\`txkB/s\`),VAR_POP(s.\`txkB/s\`),SUM(s.\`txkB/s\`),
  AVG(s.\`rxcmp/s\`),MAX(s.\`rxcmp/s\`),MIN(s.\`rxcmp/s\`),STDDEV_POP(s.\`rxcmp/s\`),VAR_POP(s.\`rxcmp/s\`),SUM(s.\`rxcmp/s\`),
  AVG(s.\`txcmp/s\`),MAX(s.\`txcmp/s\`),MIN(s.\`txcmp/s\`),STDDEV_POP(s.\`txcmp/s\`),VAR_POP(s.\`txcmp/s\`),SUM(s.\`txcmp/s\`),
  AVG(s.\`rxmcst/s\`),MAX(s.\`rxmcst/s\`),MIN(s.\`rxmcst/s\`),STDDEV_POP(s.\`rxmcst/s\`),VAR_POP(s.\`rxmcst/s\`),SUM(s.\`rxmcst/s\`)
  FROM aloja_logs.SAR_net_devices s
  JOIN aloja2.execs e USING (id_exec)
  WHERE id_exec NOT IN (SELECT id_exec FROM precal_network_metrics) AND 1 GROUP BY (e.id_exec);"

logger "INFO: Done updating performance aggregates"