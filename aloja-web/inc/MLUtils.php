<?php

namespace alojaweb\inc;

use alojaweb\inc\Utils;
use alojaweb\Filters\Filters;

class MLUtils
{
	public static function generateModelInfo(\alojaweb\Filters\Filters $filters, $param_names, $params, $condition)
	{
		$filter_options = $filters->getFilterChoices();

		$paramAllOptions = array();
		$model_info = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists($p,$filter_options))
				$paramAllOptions[$p] = $filter_options[$p];
			if ($condition)
			{
				if (!empty($params[$p]) && is_array($params[$p]))
					$model_info .= ' '.$p.' ("'.implode('","',$params[$p]).'")';
				else if (!empty($params[$p]))
					$model_info .= ' '.$p.' ("'.$params[$p].'")';
				else
					$model_info .= ' '.$p.' ("*")';
			} else
				$model_info = $model_info.((empty($params[$p]))?' '.$p.' ("'.Utils::multi_implode($paramAllOptions[$p],'","').'")':' '.$p.' ("'.Utils::multi_implode($params[$p],'","').'")');
		}
		return $model_info;
	}

	public static function generateDatasliceInfo(\alojaweb\Filters\Filters $filters, $param_names_additional, $params_additional)
	{
		$slice_info = '';
		foreach ($param_names_additional as $p)
		{
			if (empty($params_additional[$p])) $slice_info = $slice_info.' '.$p.' ("*")';
			else
			{
				if (is_array($params_additional[$p])) $slice_info = $slice_info.' '.$p.' ("'.implode('","',$params_additional[$p]).'")';
				else $slice_info = $slice_info.' '.$p.' ("'.strval($params_additional[$p]).'")';
			}
		}
		return $slice_info;
	}

	public static function generateSimpleInstance(\alojaweb\Filters\Filters $filters, $param_names, $params, $condition)
	{
		$filter_options = $filters->getFilterChoices();

		$paramAllOptions = $tokens = array();
		$instance = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists($p,$filter_options)) $paramAllOptions[$p] = $filter_options[$p];

			$tokens[$p] = '';
			if ($condition && empty($params[$p])) { $tokens[$p] = '*'; }
			elseif (!$condition && empty($params[$p]))
			{
				foreach ($paramAllOptions[$p] as $par)
					$tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comp')?'Cmp':'').(($p=='id_cluster')?'Cl':'').$par;
			}
			else
			{
				if (is_array($params[$p]))
					foreach ($params[$p] as $par)
						$tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comp')?'Cmp':'').(($p=='id_cluster')?'Cl':'').$par;
				else $tokens[$p] = $params[$p];
			}
			$instance = $instance.(($instance=='')?'':',').$tokens[$p];
		}
		return $instance;
	}

	public static function generateInstances(\alojaweb\Filters\Filters $filters, $param_names, $params, $generalize, $db = null)
	{
		$filter_options = $filters->getFilterChoices();

		$paramAllOptions = $tokens = $instances = array();

		// Get info from clusters (Part of header_names!)
		$cluster_header_names = array(
			'id_cluster' => 'Cluster','datanodes' => 'Datanodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores',
			'vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type'
		);
		$cluster_descriptor = array();
		$query = "select ".implode(",",array_keys($cluster_header_names))." from aloja2.clusters;";
	    	$rows = $db->get_rows($query);
	    	foreach($rows as $row)
		{
			$cid = $row['id_cluster'];
			foreach(array_keys($cluster_header_names) as $cname)
			{
				$cluster_descriptor[$cid][$cname] = $row[$cname];
			}
		}

		// If "No Clusters" -> All clusters
		if (empty($params['id_cluster']))
		{
			$params['id_cluster'] = array();
			$paramAllOptions['id_cluster'] = $filter_options['id_cluster'];
			foreach ($paramAllOptions['id_cluster'] as $par) $params['id_cluster'][] = $par;
		}

		// For each cluster selected, launch an instance...
		foreach ($params['id_cluster'] as $cl) 
		{
			// Reduce the instance to the HW filter override, or even remove instance if no HW coincides
			$remove_if_no_props = FALSE;
			foreach(array_keys($cluster_header_names) as $cname)
			{
				if (!empty($params[$cname]))
				{
					// FIXME - When clusters have more than 1 characteristic, change this
					// Get only the current_props in params[cname]
					$current_props = $cluster_descriptor[$cl][$cname];
					$current_props = array($current_props);
					$coincidences = array_intersect($current_props,$params[$cname]);
					if (empty($coincidences)) $remove_if_no_props = TRUE;
					else $cluster_descriptor[$cl][$cname] = $coincidences;
				}
			}
			if ($remove_if_no_props) continue;

			$cl_characteristics = "Cl".Utils::multi_implode($cluster_descriptor[$cl],',');

			$instance = '';
			foreach ($param_names as $p) 
			{
				// Ignore for now. Will be used at each cluster characteristics
				if (array_key_exists($p,$cluster_header_names) && $p != "id_cluster") continue;

				if ($p != "id_cluster")
				{
					if (array_key_exists($p,$filter_options)) $paramAllOptions[$p] = $filter_options[$p];

					$tokens[$p] = '';
					if ($generalize && empty($params[$p]))
						$tokens[$p] = '*';
					elseif (!$generalize && empty($params[$p])) 
						foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comp')?'Cmp':'').(($p=='id_cluster')?'Cl':'').$par;
					else
					{
						if (is_array($params[$p]))
							foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comp')?'Cmp':'').(($p=='id_cluster')?'Cl':'').$par;
						else $tokens[$p] = $params[$p];
					}
					$instance = $instance.(($instance=='')?'':',').$tokens[$p];
				}
				else
				{
					$instance = $instance.(($instance=='')?'':',').$cl_characteristics;
				}
			}
			$instances[] = $instance;

		}

		return MLUtils::completeInstances($filters,$instances,$param_names,$params,$db);
	}

	public static function completeInstances(\alojaweb\Filters\Filters $filters, $instances, $param_names, $params, $db = null)
	{
		$filter_options = $filters->getFilterChoices();

		// Fetch Network values
		$query = "SELECT MAX(n1.`maxtxkB/s`) AS maxtxkbs, MAX(n1.`maxrxkB/s`) AS maxrxkbs,
			  	 MAX(n1.`maxtxpck/s`) AS maxtxpcks, MAX(n1.`maxrxpck/s`) AS maxrxpcks,
				 MAX(n1.`maxtxcmp/s`) AS maxtxcmps, MAX(n1.`maxrxcmp/s`) AS maxrxcmps,
				 MAX(n1.`maxrxmcst/s`) AS maxrxmscts,
				 e1.net AS net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			  FROM aloja2.precal_network_metrics AS n1,
			  	 aloja2.execs AS e1 LEFT JOIN aloja2.clusters AS c1 ON e1.id_cluster = c1.id_cluster
			  WHERE e1.id_exec = n1.id_exec
			  GROUP BY e1.net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider";
	    	$rows = $db->get_rows($query);
		if (empty($rows)) throw new \Exception('Error retrieving precalculated data from Network. Metrics must be generated (enter into "Performance Metrics" page)');

		$netinfo = array();
		foreach ($rows as $row)
		{
			$id = $row['net'].'-'.$row['vm_cores'].'-'.$row['vm_RAM'].'-'.$row['vm_size'].'-'.$row['vm_OS'].'-'.$row['provider'];
			$netinfo[$id] = $row['maxtxkbs'].','.$row['maxrxkbs'].','.$row['maxtxpcks'].','.$row['maxrxpcks'].','.$row['maxtxcmps'].','.$row['maxrxcmps'].','.$row['maxrxmscts'];
		}

		// Fetch Disk values
		$query = "SELECT MAX(d1.maxtps) AS maxtps, MAX(d1.maxsvctm) as maxsvctm,
				 MAX(d1.`maxrd_sec/s`) as maxrds, MAX(d1.`maxwr_sec/s`) as maxwrs,
				 MAX(d1.maxrq_sz) as maxrqsz, MAX(d1.maxqu_sz) as maxqusz,
				 MAX(d1.maxawait) as maxawait, MAX(d1.`max%util`) as maxutil,
				 e2.disk AS disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			  FROM aloja2.precal_disk_metrics AS d1,
				 aloja2.execs AS e2 LEFT JOIN aloja2.clusters AS c1 ON e2.id_cluster = c1.id_cluster
			  WHERE e2.id_exec = d1.id_exec
			  GROUP BY e2.disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider";
	    	$rows = $db->get_rows($query);
		if (empty($rows)) throw new \Exception('Error retrieving precalculated data from Disks. Metrics must be generated (enter into "Performance Metrics" page)');

		$diskinfo = array();
		foreach ($rows as $row)
		{
			$id = $row['disk'].'-'.$row['vm_cores'].'-'.$row['vm_RAM'].'-'.$row['vm_size'].'-'.$row['vm_OS'].'-'.$row['provider'];
			$diskinfo[$id] = $row['maxtps'].','.$row['maxsvctm'].','.$row['maxrds'].','.$row['maxwrs'].','.$row['maxrqsz'].','.$row['maxqusz'].','.$row['maxawait'].','.$row['maxutil'];
		}

		// Fetch Benchmark values
		$reference_cluster = 21; #FIXME - Reference Cluster should come from parameter, or fixed when selected for 1st time
		$bench_query = array(
			'pc.`avg%user`' => 'pcavguser','pc.`max%user`' => 'pcmaxuser','pc.`min%user`' => 'pcminuser','pc.`stddev_pop%user`' => 'pcstddevpopuser','pc.`var_pop%user`' => 'pcvarpopuser','pc.`avg%nice`' => 'pcavgnice','pc.`max%nice`' => 'pcmaxnice','pc.`min%nice`' => 'pcminnice','pc.`stddev_pop%nice`' => 'pcstddevpopnice','pc.`var_pop%nice`' => 'pcvarpopnice','pc.`avg%system`' => 'pcavgsystem','pc.`max%system`' => 'pcmaxsystem','pc.`min%system`' => 'pcminsystem','pc.`stddev_pop%system`' => 'pcstddevpopsystem','pc.`var_pop%system`' => 'pcvarpopsystem','pc.`avg%iowait`' => 'pcavgiowait','pc.`max%iowait`' => 'pcmaxiowait','pc.`min%iowait`' => 'pcminiowait','pc.`stddev_pop%iowait`' => 'pcstddevpopiowait','pc.`var_pop%iowait`' => 'pcvarpopiowait','pc.`avg%steal`' => 'pcavgsteal','pc.`max%steal`' => 'pcmaxsteal','pc.`min%steal`' => 'pcminsteal','pc.`stddev_pop%steal`' => 'pcstddevpopsteal','pc.`var_pop%steal`' => 'pcvarpopsteal','pc.`avg%idle`' => 'pcavgidle','pc.`max%idle`' => 'pcmaxidle','pc.`min%idle`' => 'pcminidle','pc.`stddev_pop%idle`' => 'pcstddevpopidle','pc.`var_pop%idle`' => 'pcvarpopidle',
			'pm.`avgkbmemfree`' => 'pmavgkbmemfree','pm.`maxkbmemfree`' => 'pmmaxkbmemfree','pm.`minkbmemfree`' => 'pmminkbmemfree','pm.`stddev_popkbmemfree`' => 'pmstddevpopkbmemfree','pm.`var_popkbmemfree`' => 'pmvarpopkbmemfree','pm.`avgkbmemused`' => 'pmavgkbmemused','pm.`maxkbmemused`' => 'pmmaxkbmemused','pm.`minkbmemused`' => 'pmminkbmemused','pm.`stddev_popkbmemused`' => 'pmstddevpopkbmemused','pm.`var_popkbmemused`' => 'pmvarpopkbmemused','pm.`avg%memused`' => 'pmavgmemused','pm.`max%memused`' => 'pmmaxmemused','pm.`min%memused`' => 'pmminmemused','pm.`stddev_pop%memused`' => 'pmstddevpopmemused','pm.`var_pop%memused`' => 'pmvarpopmemused','pm.`avgkbbuffers`' => 'pmavgkbbuffers','pm.`maxkbbuffers`' => 'pmmaxkbbuffers','pm.`minkbbuffers`' => 'pmminkbbuffers','pm.`stddev_popkbbuffers`' => 'pmstddevpopkbbuffers','pm.`var_popkbbuffers`' => 'pmvarpopkbbuffers','pm.`avgkbcached`' => 'pmavgkbcached','pm.`maxkbcached`' => 'pmmaxkbcached','pm.`minkbcached`' => 'pmminkbcached','pm.`stddev_popkbcached`' => 'pmstddevpopkbcached','pm.`var_popkbcached`' => 'pmvarpopkbcached','pm.`avgkbcommit`' => 'pmavgkbcommit','pm.`maxkbcommit`' => 'pmmaxkbcommit','pm.`minkbcommit`' => 'pmminkbcommit','pm.`stddev_popkbcommit`' => 'pmstddevpopkbcommit','pm.`var_popkbcommit`' => 'pmvarpopkbcommit','pm.`avg%commit`' => 'pmavgcommit','pm.`max%commit`' => 'pmmaxcommit','pm.`min%commit`' => 'pmmincommit','pm.`stddev_pop%commit`' => 'pmstddevpopcommit','pm.`var_pop%commit`' => 'pmvarpopcommit','pm.`avgkbactive`' => 'pmavgkbactive','pm.`maxkbactive`' => 'pmmaxkbactive','pm.`minkbactive`' => 'pmminkbactive','pm.`stddev_popkbactive`' => 'pmstddevpopkbactive','pm.`var_popkbactive`' => 'pmvarpopkbactive','pm.`avgkbinact`' => 'pmavgkbinact','pm.`maxkbinact`' => 'pmmaxkbinact','pm.`minkbinact`' => 'pmminkbinact','pm.`stddev_popkbinact`' => 'pmstddevpopkbinact','pm.`var_popkbinact`' => 'pmvarpopkbinact',
			'pn.`avgrxpck/s`' => 'pnavgrxpcks','pn.`maxrxpck/s`' => 'pnmaxrxpcks','pn.`minrxpck/s`' => 'pnminrxpcks','pn.`stddev_poprxpck/s`' => 'pnstddevpoprxpcks','pn.`var_poprxpck/s`' => 'pnvarpoprxpcks','pn.`sumrxpck/s`' => 'pnsumrxpcks','pn.`avgtxpck/s`' => 'pnavgtxpcks','pn.`maxtxpck/s`' => 'pnmaxtxpcks','pn.`mintxpck/s`' => 'pnmintxpcks','pn.`stddev_poptxpck/s`' => 'pnstddevpoptxpcks','pn.`var_poptxpck/s`' => 'pnvarpoptxpcks','pn.`sumtxpck/s`' => 'pnsumtxpcks','pn.`avgrxkB/s`' => 'pnavgrxkBs','pn.`maxrxkB/s`' => 'pnmaxrxkBs','pn.`minrxkB/s`' => 'pnminrxkBs','pn.`stddev_poprxkB/s`' => 'pnstddevpoprxkBs','pn.`var_poprxkB/s`' => 'pnvarpoprxkBs','pn.`sumrxkB/s`' => 'pnsumrxkBs','pn.`avgtxkB/s`' => 'pnavgtxkBs','pn.`maxtxkB/s`' => 'pnmaxtxkBs','pn.`mintxkB/s`' => 'pnmintxkBs','pn.`stddev_poptxkB/s`' => 'pnstddevpoptxkBs','pn.`var_poptxkB/s`' => 'pnvarpoptxkBs','pn.`sumtxkB/s`' => 'pnsumtxkBs','pn.`avgrxcmp/s`' => 'pnavgrxcmps','pn.`maxrxcmp/s`' => 'pnmaxrxcmps','pn.`minrxcmp/s`' => 'pnminrxcmps','pn.`stddev_poprxcmp/s`' => 'pnstddevpoprxcmps','pn.`var_poprxcmp/s`' => 'pnvarpoprxcmps','pn.`sumrxcmp/s`' => 'pnsumrxcmps','pn.`avgtxcmp/s`' => 'pnavgtxcmps','pn.`maxtxcmp/s`' => 'pnmaxtxcmps','pn.`mintxcmp/s`' => 'pnmintxcmps','pn.`stddev_poptxcmp/s`' => 'pnstddevpoptxcmps','pn.`var_poptxcmp/s`' => 'pnvarpoptxcmps','pn.`sumtxcmp/s`' => 'pnsumtxcmps','pn.`avgrxmcst/s`' => 'pnavgrxmcsts','pn.`maxrxmcst/s`' => 'pnmaxrxmcsts','pn.`minrxmcst/s`' => 'pnminrxmcsts','pn.`stddev_poprxmcst/s`' => 'pnstddevpoprxmcsts','pn.`var_poprxmcst/s`' => 'pnvarpoprxmcsts','pn.`sumrxmcst/s`' => 'pnsumrxmcsts',
			'pd.`avgtps`' => 'pdavgtps','pd.`maxtps`' => 'pdmaxtps','pd.`mintps`' => 'pdmintps','pd.`avgrd_sec/s`' => 'pdavgrdsecs','pd.`maxrd_sec/s`' => 'pdmaxrdsecs','pd.`minrd_sec/s`' => 'pdminrdsecs','pd.`stddev_poprd_sec/s`' => 'pdstddevpoprdsecs','pd.`var_poprd_sec/s`' => 'pdvarpoprdsecs','pd.`sumrd_sec/s`' => 'pdsumrdsecs','pd.`avgwr_sec/s`' => 'pdavgwrsecs','pd.`maxwr_sec/s`' => 'pdmaxwrsecs','pd.`minwr_sec/s`' => 'pdminwrsecs','pd.`stddev_popwr_sec/s`' => 'pdstddevpopwrsecs','pd.`var_popwr_sec/s`' => 'pdvarpopwrsecs','pd.`sumwr_sec/s`' => 'pdsumwrsecs','pd.`avgrq_sz`' => 'pdavgrqsz','pd.`maxrq_sz`' => 'pdmaxrqsz','pd.`minrq_sz`' => 'pdminrqsz','pd.`stddev_poprq_sz`' => 'pdstddevpoprqsz','pd.`var_poprq_sz`' => 'pdvarpoprqsz','pd.`avgqu_sz`' => 'pdavgqusz','pd.`maxqu_sz`' => 'pdmaxqusz','pd.`minqu_sz`' => 'pdminqusz','pd.`stddev_popqu_sz`' => 'pdstddevpopqusz','pd.`var_popqu_sz`' => 'pdvarpopqusz','pd.`avgawait`' => 'pdavgawait','pd.`maxawait`' => 'pdmaxawait','pd.`minawait`' => 'pdminawait','pd.`stddev_popawait`' => 'pdstddevpopawait','pd.`var_popawait`' => 'pdvarpopawait','pd.`avg%util`' => 'pdavgutil','pd.`max%util`' => 'pdmaxutil','pd.`min%util`' => 'pdminutil','pd.`stddev_pop%util`' => 'pdstddevpoputil','pd.`var_pop%util`' => 'pdvarpoputil','pd.`avgsvctm`' => 'pdavgsvctm','pd.`maxsvctm`' => 'pdmaxsvctm','pd.`minsvctm`' => 'pdminsvctm','pd.`stddev_popsvctm`' => 'pdstddevpopsvctm','pd.`var_popsvctm`' => 'pdvarpopsvctm'
		);
		$query = "SELECT ae.bench AS aebench,
			 ".implode(',', array_map(function ($k, $v) { return sprintf("AVG(%s) AS '%s'", $k, $v); }, array_keys($bench_query), array_values($bench_query)))."
			  FROM aloja2.precal_cpu_metrics AS pc, aloja2.precal_memory_metrics AS pm, aloja2.precal_network_metrics AS pn, aloja2.precal_disk_metrics AS pd, aloja2.execs AS ae
			  WHERE pc.id_exec = pm.id_exec AND pc.id_exec = pn.id_exec AND pc.id_exec = pd.id_exec AND pc.id_exec = ae.id_exec AND ae.id_cluster = '".$reference_cluster."'
			  GROUP BY ae.bench";
	    	$rows = $db->get_rows($query);
		if (empty($rows)) throw new \Exception('Error retrieving precalculated data from Benchmarks. Metrics must be generated (enter into "Performance Metrics" page)');

		$benchinfo = array();
		foreach ($rows as $row)
		{
			$id = $row['aebench'];
			$aux = '';
			foreach (array_values($bench_query) as $item) $aux = $aux.(($aux != '')?',':'').$row[$item];
			$benchinfo[$id] = $aux;
		}

		// Generate Completed Instances
		if (empty($params['net']))
		{
			$params['net'] = array();
			$paramAllOptions['net'] = $filter_options['net'];
			foreach ($paramAllOptions['net'] as $par) $params['net'][] = $par;
		}

		if (empty($params['disk']))
		{
			$params['disk'] = array();
			$paramAllOptions['disk'] = $filter_options['disk'];
			foreach ($paramAllOptions['disk'] as $par) $params['disk'][] = $par;
		}

		if (empty($params['bench']))
		{
			$params['bench'] = array();
			$paramAllOptions['bench'] = $filter_options['bench'];
			foreach ($paramAllOptions['bench'] as $par) $params['bench'][] = $par;
		}

		$netpos = array_search('net', $param_names);		// Multiple values -> decompose
		$diskpos = array_search('disk', $param_names);		// Multiple values -> decompose
		$benchpos = array_search('bench', $param_names);	// Multiple values -> decompose
		$corepos = array_search('vm_cores', $param_names);	// Unique value, due to decomposition by id_cluster
		$rampos = array_search('vm_RAM', $param_names);		// Unique value, due to decomposition by id_cluster
		$sizepos = array_search('vm_size', $param_names);	// Unique value, due to decomposition by id_cluster
		$ospos = array_search('vm_OS', $param_names);		// Unique value, due to decomposition by id_cluster
		$providerpos = array_search('provider', $param_names);	// Unique value, due to decomposition by id_cluster

		//For each instance, check NET & DISK & BENCH and expand/multiplicate (Combinatory effort...)
		$instances_expanded = array();
		foreach ($instances as $inst_n)
		{
			$instances_l1 = array();
			foreach ($params['net'] as $pnet)
			{
				$aux = explode(",", $inst_n);
				$aux[$netpos] = $pnet;
				$id = $pnet.'-'.$aux[$corepos].'-'.$aux[$rampos].'-'.$aux[$sizepos].'-'.$aux[$ospos].'-'.$aux[$providerpos];
				if (array_key_exists($id, $netinfo)) $aux[] = $netinfo[$id];
				else $aux[] = "0,0,0,0,0,0,0";
				$instances_l1[] = implode(",",$aux);
			}

			foreach ($instances_l1 as $inst_d)
			{
				$instances_l2 = array();
				foreach ($params['disk'] as $pdisk)
				{
					$aux = explode(",", $inst_d);
					$aux[$diskpos] = $pdisk;
					$id = $pdisk.'-'.$aux[$corepos].'-'.$aux[$rampos].'-'.$aux[$sizepos].'-'.$aux[$ospos].'-'.$aux[$providerpos];
					if (array_key_exists($id, $diskinfo)) $aux[] = $diskinfo[$id];
					else $aux[] = "0,0,0,0,0,0,0,0";
					$instances_l2[] = implode(",",$aux);
				}

				foreach ($instances_l2 as $inst_b)
				{
					foreach ($params['bench'] as $pbench)
					{
						$aux = explode(",", $inst_b);
						$aux[$benchpos] = $pbench;
						$id = $aux[$benchpos];
						if (array_key_exists($id, $benchinfo)) $aux[] = $benchinfo[$id];
						else { $aux1 = '0'; for ($i = 0; $i < 156; $i++) $aux1 = $aux1.',0'; $aux[] = $aux1; }
						$instances_expanded[] = implode(",",$aux);
					}
				}
			}
		}
		return $instances_expanded;
	}

	public static function findMatchingModels ($model_info, &$possible_models, &$possible_models_id, $dbml)
	{
		$query = "SELECT id_learner, model FROM aloja_ml.learners";
		$result = $dbml->query($query);
		foreach ($result as $row)
		{
			$parts = explode(" ",$row['model']);
			$buffer = array();
			$last_part = "";
			foreach ($parts as $p)
			{
				if (preg_match("(\(.+\))", $p)) $buffer[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
				else $last_part = $p;
			}

			if ($model_info[0]==' ') $model_info = substr($model_info, 1);
			$parts_2 = explode(" ",$model_info);
			$buffer_2 = array();
			$last_part = "";
			foreach ($parts_2 as $p)
			{
				if (preg_match("(\(.+\))", $p)) $buffer_2[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
				else $last_part = $p;
			}

			$match = TRUE;
			foreach ($buffer_2 as $bk => $ba)
			{
				if (!array_key_exists($bk,$buffer)) { $match = FALSE; break; }
				if ($buffer[$bk][0] != "*" && array_intersect($ba, $buffer[$bk]) != $ba) { $match = FALSE; break; }
			}

			if ($match)
			{
				$possible_models[] = $row['model'];
				$possible_models_id[] = $row['id_learner'];
			}
		}
	}

	public static function revertModelToURL($model_info, $slice_info, $pre_info)
	{
		$url = '';

		if ($model_info[0] == " ") $model_info = substr($model_info, 1);
		$model_array = explode(" ",$model_info);
		for($i = 1; $i < count($model_array); $i = $i + 2)
		{
			$param1 = $model_array[$i-1];
			$param2 = $model_array[$i];

			if ($param2 != '("*")')
			{
				$param2 = str_replace('(','',$param2);
				$param2 = str_replace(')','',$param2);
				$param2 = str_replace('"','',$param2);

				$param2_array = explode(",",$param2);
				for($j = 0; $j < count($param2_array); $j = $j + 1)
				{
					if ($url != '') $url = $url.'&';
					$url = $url.$param1.'[]='.$param2_array[$j];
				}
			}
		}

		if ($slice_info !== false && $slice_info != '')
		{
			if ($slice_info[0] == " ") $slice_info = substr($slice_info, 1);
			$slice_array = explode(" ",$slice_info);
			for($i = 1; $i < count($slice_array); $i = $i + 2)
			{
				$param1 = $slice_array[$i-1];
				$param2 = $slice_array[$i];

				if ($param2 != '("*")')
				{
					$param2 = str_replace('(','',$param2);
					$param2 = str_replace(')','',$param2);
					$param2 = str_replace('"','',$param2);

					$param2_array = explode(",",$param2);
					for($j = 0; $j < count($param2_array); $j = $j + 1)
					{
						if ($url != '') $url = $url.'&';
						$url = $url.$param1.'='.$param2_array[$j];
					}
				}
			}
		}

		$url = $pre_info.$url;

		return $url;
	}

	public static function display_models_noasts ($input)
	{
		$data_display = '';

		if ($input != '')
		{
			if ($input[0] == " ") $input = substr($input, 1);
			$data_array = explode(" ",$input);
			for($i = 1; $i < count($data_array); $i = $i + 2)
			{
				$param1 = $data_array[$i-1];
				$param2 = $data_array[$i];
				if ($param2 != '("*")') $data_display = $data_display.' '.$param1.' '.$param2;
			}
		}
		if ($data_display == '') $data_display = 'No Filters';

		return $data_display;
	}

	public static function getIndexModels (&$jsonLearners, &$jsonLearningHeader, $dbml, $includeconfigs = FALSE)
	{
		$query="SELECT DISTINCT l.id_learner AS id_learner, l.algorithm AS algorithm,
				l.creation_time AS creation_time, l.model AS model, l.dataslice AS advanced,
				COUNT(p.id_prediction) AS num_preds
			FROM aloja_ml.learners AS l LEFT JOIN aloja_ml.predictions AS p ON l.id_learner = p.id_learner".
			(($includeconfigs)?" ":" WHERE l.id_learner NOT IN (SELECT DISTINCT id_learner FROM aloja_ml.minconfigs) ")."
			GROUP BY l.id_learner
			";

		$rows = $dbml->query($query);
		$jsonLearners = '[';
	    	foreach($rows as $row)
		{
			if (strpos($row['model'],'*') !== false) $umodel = 'umodel=umodel&'; else $umodel = '';
			$url = MLUtils::revertModelToURL($row['model'], $row['advanced'], 'presets=none&submit=&learner[]='.$row['algorithm'].'&'.$umodel);

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['advanced']);

			$jsonLearners = $jsonLearners.(($jsonLearners=='[')?'':',')."['".$row['id_learner']."','".$row['algorithm']."','".$model_display."','".$slice_display."','".$row['creation_time']."','".$row['num_preds']."',
			'<a href=\'/mlprediction?".$url."\'>View</a> <a href=\'/mlclearcache?rml=".$row['id_learner']."\'>Remove</a>']";
		}
		$jsonLearners = $jsonLearners.']';
		$jsonLearningHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Predictions'},{'title':'Actions'}]";
	}

	public static function getIndexFAttrs (&$jsonFAttrs, &$jsonFAttrsHeader, $dbml)
	{
		$query="SELECT DISTINCT f.id_findattrs AS id_findattrs, f.id_learner as id_learner, f.creation_time AS creation_time, f.model AS model FROM aloja_ml.trees AS f";
		$rows = $dbml->query($query);

		$jsonFAttrs = '[';
		foreach ($rows as $row)
		{
			if (strpos($row['model'],'*') !== false) $unseen = 'unseen=unseen&'; else $unseen = '';
			$url = MLUtils::revertModelToURL($row['model'], null, 'presets=none&submit=&current_model[]='.$row['id_learner'].'&'.$unseen);

			$model_display = MLUtils::display_models_noasts ($row['model']);

			$jsonFAttrs = $jsonFAttrs.(($jsonFAttrs=='[')?'':',')."['".$row['id_findattrs']."','".$row['id_learner']."','".$model_display."','".$row['creation_time']."','<a href=\'/mlfindattributes?".$url."\'>View</a>']";
		}
		$jsonFAttrs = $jsonFAttrs.']';
		$jsonFAttrsHeader = "[{'title':'ID'},{'title':'Model ID Used'},{'title':'Attribute Selection'},{'title':'Creation'},{'title':'Actions'}]";
	}

	public static function getIndexOutExps (&$jsonResolutions, &$jsonResolutionsHeader, $dbml)
	{
		$query="SELECT DISTINCT id_resolution, id_learner, model, dataslice, creation_time, sigma, count(*) AS instances FROM aloja_ml.resolutions GROUP BY id_resolution";
		$rows = $dbml->query($query);

		$jsonResolutions = '[';
	    	foreach($rows as $row)
		{
			$url = MLUtils::revertModelToURL($row['model'], $row['dataslice'], 'presets=none&submit=&current_model[]='.$row['id_learner'].'&sigma='.$row['sigma'].'&');

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['dataslice']);

			$jsonResolutions = $jsonResolutions.(($jsonResolutions=='[')?'':',')."['".$row['id_resolution']."','".$row['id_learner']."','".$model_display."','".$slice_display."','".$row['sigma']."','".$row['creation_time']."','".$row['instances']."','<a href=\'/mloutliers?".$url."\'>View</a> <a href=\'/mlclearcache?rmr=".$row['id_resolution']."\'>Remove</a>']";
		}
		$jsonResolutions = $jsonResolutions.']';
		$jsonResolutionsHeader = "[{'title':'ID'},{'title':'Model ID Used'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Sigma'},{'title':'Creation'},{'title':'Instances'},{'title':'Actions'}]";
	}

	public static function getIndexObsTrees (&$jsonObstrees, &$jsonObstreesHeader, $dbml)
	{
		$query="SELECT id_obstrees, model, dataslice, creation_time FROM aloja_ml.observed_trees";
		$rows = $dbml->query($query);
		$jsonObstrees = '[';
	    	foreach($rows as $row)
		{
			$url = MLUtils::revertModelToURL($row['model'], $row['dataslice'], 'presets=none&submit=&');

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['dataslice']);

			$jsonObstrees = $jsonObstrees.(($jsonObstrees=='[')?'':',')."['".$row['id_obstrees']."','".$model_display."','".$slice_display."','".$row['creation_time']."','<a href=\'/mlobstrees?".$url."\'>View</a> <a href=\'/mlclearcache?rmo=".$row['id_obstrees']."\'>Remove</a>']";
		}
		$jsonObstrees = $jsonObstrees.']';
		$jsonObstreesHeader = "[{'title':'ID'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Actions'}]";
	}

	public static function getIndexPrecExps (&$jsonPrecexps, &$jsonPrecexpsHeader, $dbml)
	{
		$query="SELECT id_precision, model, dataslice, creation_time FROM aloja_ml.precisions GROUP BY id_precision";
		$rows = $dbml->query($query);
		$jsonPrecexps = '[';
	    	foreach($rows as $row)
		{
			$url = MLUtils::revertModelToURL($row['model'], $row['dataslice'], 'presets=none&submit=&');

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['dataslice']);

			$jsonPrecexps = $jsonPrecexps.(($jsonPrecexps=='[')?'':',')."['".$row['id_precision']."','".$model_display."','".$slice_display."','".$row['creation_time']."','<a href=\'/mlprecision?".$url."\'>View</a> <a href=\'/mlclearcache?rmp=".$row['id_precision']."\'>Remove</a>']";
		}
		$jsonPrecexps = $jsonPrecexps.']';
		$jsonPrecexpsHeader = "[{'title':'ID'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Actions'}]";
	}

	public static function getIndexMinconfs (&$jsonMinconfs, &$jsonMinconfsHeader, $dbml)
	{
		$query="SELECT mj.*, COUNT(mc.sid_minconfigs_centers) AS num_centers
			FROM (	SELECT DISTINCT m.id_minconfigs AS id_minconfigs, m.model AS model, m.is_new as is_new, m.dataslice AS advanced,
					m.creation_time AS creation_time, COUNT(mp.sid_minconfigs_props) AS num_props, l.algorithm
				FROM aloja_ml.minconfigs AS m LEFT JOIN aloja_ml.minconfigs_props AS mp ON m.id_minconfigs = mp.id_minconfigs, aloja_ml.learners AS l
				WHERE l.id_learner = m.id_learner
				GROUP BY m.id_minconfigs
			) AS mj LEFT JOIN aloja_ml.minconfigs_centers AS mc ON mj.id_minconfigs = mc.id_minconfigs
			WHERE mj.is_new = 0
			GROUP BY mj.id_minconfigs
			";
		$rows = $dbml->query($query);
		$jsonMinconfs = '[';
	    	foreach($rows as $row)
		{
			if (strpos($row['model'],'*') !== false) $umodel = 'umodel=umodel&'; else $umodel = '';
			$url = MLUtils::revertModelToURL($row['model'], $row['advanced'], 'presets=none&submit=&learner[]='.$row['algorithm'].'&'.$umodel);

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['advanced']);

			$jsonMinconfs = $jsonMinconfs.(($jsonMinconfs=='[')?'':',')."['".$row['id_minconfigs']."','".$row['algorithm']."','".$model_display."','".$slice_display."','".$row['creation_time']."','".$row['num_props']."','".$row['num_centers']."',
			'<a href=\'/mlminconfigs?".$url."\'>View</a> <a href=\'/mlclearcache?rmm=".$row['id_minconfigs']."\'>Remove</a>']";
		}
		$jsonMinconfs = $jsonMinconfs.']';
		$jsonMinconfsHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Properties'},{'title':'Centers'},{'title':'Actions'}]";
	}

	public static function getIndexNewconfs (&$jsonNewconfs, &$jsonNewconfsHeader, $dbml)
	{
		$query="SELECT mj.*, COUNT(mc.sid_minconfigs_centers) AS num_centers
			FROM (	SELECT DISTINCT m.id_minconfigs AS id_minconfigs, m.model AS model, m.is_new as is_new, m.dataslice AS advanced,
					m.creation_time AS creation_time, COUNT(mp.sid_minconfigs_props) AS num_props, l.algorithm
				FROM aloja_ml.minconfigs AS m LEFT JOIN aloja_ml.minconfigs_props AS mp ON m.id_minconfigs = mp.id_minconfigs, aloja_ml.learners AS l
				WHERE l.id_learner = m.id_learner
				GROUP BY m.id_minconfigs
			) AS mj LEFT JOIN aloja_ml.minconfigs_centers AS mc ON mj.id_minconfigs = mc.id_minconfigs
			WHERE mj.is_new = 1
			GROUP BY mj.id_minconfigs
			";
		$rows = $dbml->query($query);
		$jsonNewconfs = '[';
	    	foreach($rows as $row)
		{
			$url = MLUtils::revertModelToURL($row['model'], $row['advanced'], 'presets=none&submit=&learner[]='.$row['algorithm']);

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['advanced']);

			$jsonNewconfs = $jsonNewconfs.(($jsonNewconfs=='[')?'':',')."['".$row['id_minconfigs']."','".$row['algorithm']."','".$model_display."','".$slice_display."','".$row['creation_time']."','".$row['num_props']."','".$row['num_centers']."',
			'<a href=\'/mlnewconfigs?".$url."\'>View</a> <a href=\'/mlclearcache?rmm=".$row['id_minconfigs']."\'>Remove</a>']";
		}
		$jsonNewconfs = $jsonNewconfs.']';
		$jsonNewconfsHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Properties'},{'title':'Centers'},{'title':'Actions'}]";
	}

	public static function getLegacyQuery (&$names,$where_configs)
	{
		$header_names = array(
			'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
			'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster',
			'datanodes' => 'Datanodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size',
			'type' => 'Type','bench_type' => 'Bench.Type','hadoop_version'=>'Hadoop.Version','IFNULL(datasize,0)' =>'Datasize','scale_factor' => 'Scale.Factor'
		);
		$headers = array_keys($header_names);
		$names = array_values($header_names);

		$query = "SELECT ".implode(",",$headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";

		return $query;
	}

	public static function getQuery (&$names,$reference_cluster,$where_configs)
	{
		$exec_names = array(
			'idexec' => 'ID','benchmark' => 'Benchmark','exetime' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosfac' => 'IO.SFac',
			'rep' => 'Rep','iofbuf' => 'IO.FBuf','comp' => 'Comp','blksize' => 'Blk.size','idcluster' => 'ID.Cluster', 'clname' => 'Cl.Name',
			'datanodes' => 'Datanodes','vmos' => 'VM.OS','vmcores' => 'VM.Cores','vmram' => 'VM.RAM','provider' => 'Provider','vmsize' => 'VM.Size',
			'type' => 'Service.Type','benchtype' => 'Bench.Type','hadoopversion'=>'Hadoop.Version','datasize' =>'Datasize','scalefactor' => 'Scale.Factor'
		);
		$exec_query = array(
			'e.id_exec' => 'idexec','e.bench' => 'benchmark','e.exe_time' => 'exetime','e.net' => 'net','e.disk' => 'disk','e.maps' => 'maps','e.iosf' => 'iosfac',
			'e.replication' => 'rep','e.iofilebuf' => 'iofbuf','CONCAT("Cmp",e.comp)' => 'comp','e.blk_size' => 'blksize','CONCAT("Cl",e.id_cluster)' => 'idcluster', 'c.name' => 'clname',
			'c.datanodes' => 'datanodes','c.vm_OS' => 'vmos','c.vm_cores' => 'vmcores','c.vm_RAM' => 'vmram','c.provider' => 'provider','c.vm_size' => 'vmsize',
			'c.type' => 'type','e.bench_type' => 'benchtype','CONCAT("V",LEFT(REPLACE(e.hadoop_version,"-",""),1))'=>'hadoopversion','IFNULL(e.datasize,0)' =>'datasize','e.scale_factor' => 'scalefactor'
		); #FIXME - Make hadoop.version standard
		$net_names = array(
			'maxtxkbs' => 'Net.maxtxKB.s','maxrxkbs' => 'Net.maxrxKB.s','maxtxpcks' => 'Net.maxtxPck.s','maxrxpcks' => 'Net.maxrxPck.s',
			'maxtxcmps' => 'Net.maxtxCmp.s','maxrxcmps' => 'Net.maxrxCmp.s','maxrxmscts' => 'Net.maxrxmsct.s'
		);
		$net_query = array(
			'n1.`maxtxkB/s`' => 'maxtxkbs','n1.`maxrxkB/s`' => 'maxrxkbs','n1.`maxtxpck/s`' => 'maxtxpcks','n1.`maxrxpck/s`' => 'maxrxpcks',
			'n1.`maxtxcmp/s`' => 'maxtxcmps', 'n1.`maxrxcmp/s`' => 'maxrxcmps', 'n1.`maxrxmcst/s`' => 'maxrxmscts',
		);
		$disk_names = array(
			'maxtps' => 'Disk.maxtps','maxsvctm' => 'Disk.maxsvctm','maxrds' => 'Disk.maxrd.s','maxwrs' => 'Disk.maxwr.s',
			'maxrqsz' => 'Disk.maxrqsz','maxqusz' => 'Disk.maxqusz','maxawait' => 'Disk.maxawait','maxutil' => 'Disk.maxutil'
		);
		$disk_query = array(
			'd1.maxtps' => 'maxtps', 'd1.maxsvctm' => 'maxsvctm','d1.`maxrd_sec/s`' => 'maxrds', 'd1.`maxwr_sec/s`' => 'maxwrs',
			'd1.maxrq_sz' => 'maxrqsz', 'd1.maxqu_sz' => 'maxqusz','d1.maxawait' => 'maxawait', 'd1.`max%util`' => 'maxutil',
		);
		$bench_names = array(
			'pcavguser' => 'BMK.CPU.avguser','pcmaxuser' => 'BMK.CPU.maxuser','pcminuser' => 'BMK.CPU.minuser','pcstddevpopuser' => 'BMK.CPU.sdpopuser','pcvarpopuser' => 'BMK.CPU.varpopuser','pcavgnice' => 'BMK.CPU.avgnice','pcmaxnice' => 'BMK.CPU.maxnice','pcminnice' => 'BMK.CPU.minnice','pcstddevpopnice' => 'BMK.CPU.sdpopnice','pcvarpopnice' => 'BMK.CPU.varpopnice','pcavgsystem' => 'BMK.CPU.avgsystem','pcmaxsystem' => 'BMK.CPU.maxsystem','pcminsystem' => 'BMK.CPU.minsystem','pcstddevpopsystem' => 'BMK.CPU.sdpopsystem','pcvarpopsystem' => 'BMK.CPU.varpopsystem','pcavgiowait' => 'BMK.CPU.avgiowait','pcmaxiowait' => 'BMK.CPU.maxiowait','pcminiowait' => 'BMK.CPU.miniowait','pcstddevpopiowait' => 'BMK.CPU.sdpopiowait','pcvarpopiowait' => 'BMK.CPU.varpopiowait','pcavgsteal' => 'BMK.CPU.avgsteal','pcmaxsteal' => 'BMK.CPU.maxsteal','pcminsteal' => 'BMK.CPU.minsteal','pcstddevpopsteal' => 'BMK.CPU.sdpopsteal','pcvarpopsteal' => 'BMK.CPU.varpopsteal','pcavgidle' => 'BMK.CPU.avgidle','pcmaxidle' => 'BMK.CPU.maxidle','pcminidle' => 'BMK.CPU.minidle','pcstddevpopidle' => 'BMK.CPU.sdpopidle','pcvarpopidle' => 'BMK.CPU.varpopidle',
			'pmavgkbmemfree' => 'BMK.MEM.avgKBmemfree','pmmaxkbmemfree' => 'BMK.MEM.maxKBmemfree','pmminkbmemfree' => 'BMK.MEM.minKBmemfree','pmstddevpopkbmemfree' => 'BMK.MEM.sdpopKBmemfree','pmvarpopkbmemfree' => 'BMK.MEM.varpopKBmemfree','pmavgkbmemused' => 'BMK.MEM.avgKBmemused','pmmaxkbmemused' => 'BMK.MEM.maxKBmemused','pmminkbmemused' => 'BMK.MEM.minKBmemused','pmstddevpopkbmemused' => 'BMK.MEM.sdpopKBmemused','pmvarpopkbmemused' => 'BMK.MEM.varpopKBmemused','pmavgmemused' => 'BMK.MEM.avgmemused','pmmaxmemused' => 'BMK.MEM.maxmemused','pmminmemused' => 'BMK.MEM.minmemused','pmstddevpopmemused' => 'BMK.MEM.sdpopmemused','pmvarpopmemused' => 'BMK.MEM.varpopmemused','pmavgkbbuffers' => 'BMK.MEM.avgKBbuffers','pmmaxkbbuffers' => 'BMK.MEM.maxKBbuffers','pmminkbbuffers' => 'BMK.MEM.minKBbuffers','pmstddevpopkbbuffers' => 'BMK.MEM.sdpopKBbuffers','pmvarpopkbbuffers' => 'BMK.MEM.varpopKBbuffers','pmavgkbcached' => 'BMK.MEM.avgKBcached','pmmaxkbcached' => 'BMK.MEM.maxKBcached','pmminkbcached' => 'BMK.MEM.minKBcached','pmstddevpopkbcached' => 'BMK.MEM.sdpopKBcached','pmvarpopkbcached' => 'BMK.MEM.varpopKBcached','pmavgkbcommit' => 'BMK.MEM.avgKBcommit','pmmaxkbcommit' => 'BMK.MEM.maxKBcommit','pmminkbcommit' => 'BMK.MEM.minKBcommit','pmstddevpopkbcommit' => 'BMK.MEM.sdpopKBcommit','pmvarpopkbcommit' => 'BMK.MEM.varpopKBcommit','pmavgcommit' => 'BMK.MEM.avgcommit','pmmaxcommit' => 'BMK.MEM.maxcommit','pmmincommit' => 'BMK.MEM.mincommit','pmstddevpopcommit' => 'BMK.MEM.sdpopcommit','pmvarpopcommit' => 'BMK.MEM.varpopcommit','pmavgkbactive' => 'BMK.MEM.avgKBactive','pmmaxkbactive' => 'BMK.MEM.maxKBactive','pmminkbactive' => 'BMK.MEM.minKBactive','pmstddevpopkbactive' => 'BMK.MEM.sdpopKBactive','pmvarpopkbactive' => 'BMK.MEM.varpopKBactive','pmavgkbinact' => 'BMK.MEM.avgKBinact','pmmaxkbinact' => 'BMK.MEM.maxKBinact','pmminkbinact' => 'BMK.MEM.minKBinact','pmstddevpopkbinact' => 'BMK.MEM.sdpopKBinact','pmvarpopkbinact' => 'BMK.MEM.varpopKBinact',
			'pnavgrxpcks' => 'BMK.NET.avgRXpcks','pnmaxrxpcks' => 'BMK.NET.maxRXpcks','pnminrxpcks' => 'BMK.NET.minRXpcks','pnstddevpoprxpcks' => 'BMK.NET.sdpopRXpcks','pnvarpoprxpcks' => 'BMK.NET.varpopRXpcks','pnsumrxpcks' => 'BMK.NET.sumRXpcks','pnavgtxpcks' => 'BMK.NET.avgTXpcks','pnmaxtxpcks' => 'BMK.NET.maxTXpcks','pnmintxpcks' => 'BMK.NET.minTXpcks','pnstddevpoptxpcks' => 'BMK.NET.sdpopTXpcks','pnvarpoptxpcks' => 'BMK.NET.varpopTXpcks','pnsumtxpcks' => 'BMK.NET.sumTXpcks','pnavgrxkBs' => 'BMK.NET.avgRXKBs','pnmaxrxkBs' => 'BMK.NET.maxRXKBs','pnminrxkBs' => 'BMK.NET.minRXKBs','pnstddevpoprxkBs' => 'BMK.NET.sdpopRXKBs','pnvarpoprxkBs' => 'BMK.NET.varpopRXKBs','pnsumrxkBs' => 'BMK.NET.sumRXKBs','pnavgtxkBs' => 'BMK.NET.avgTXKBs','pnmaxtxkBs' => 'BMK.NET.maxTXKBs','pnmintxkBs' => 'BMK.NET.minTXKBs','pnstddevpoptxkBs' => 'BMK.NET.sdpopTXKBs','pnvarpoptxkBs' => 'BMK.NET.varpopTXKBs','pnsumtxkBs' => 'BMK.NET.sumTXKBs','pnavgrxcmps' => 'BMK.NET.avgRXcmps','pnmaxrxcmps' => 'BMK.NET.maxRXcmps','pnminrxcmps' => 'BMK.NET.minRXcmps','pnstddevpoprxcmps' => 'BMK.NET.sdpopRXcmps','pnvarpoprxcmps' => 'BMK.NET.varpopRXcmps','pnsumrxcmps' => 'BMK.NET.sumRXcmps','pnavgtxcmps' => 'BMK.NET.avgTXcmps','pnmaxtxcmps' => 'BMK.NET.maxTXcmps','pnmintxcmps' => 'BMK.NET.minTXcmps','pnstddevpoptxcmps' => 'BMK.NET.sdpopTXcmps','pnvarpoptxcmps' => 'BMK.NET.varpopTXcmps','pnsumtxcmps' => 'BMK.NET.sumTXcmps','pnavgrxmcsts' => 'BMK.NET.avgRXcsts','pnmaxrxmcsts' => 'BMK.NET.maxRXcsts','pnminrxmcsts' => 'BMK.NET.minRXcsts','pnstddevpoprxmcsts' => 'BMK.NET.sdpopRXcsts','pnvarpoprxmcsts' => 'BMK.NET.varpopRXcsts','pnsumrxmcsts' => 'BMK.NET.sumRXcsts',
			'pdavgtps' => 'BMK.DSK.avgtps','pdmaxtps' => 'BMK.DSK.maxtps','pdmintps' => 'BMK.DSK.mintps','pdavgrdsecs' => 'BMK.DSK.avgRDs','pdmaxrdsecs' => 'BMK.DSK.maxRDs','pdminrdsecs' => 'BMK.DSK.minRDs','pdstddevpoprdsecs' => 'BMK.DSK.sdpopRDs','pdvarpoprdsecs' => 'BMK.DSK.varpopRDs','pdsumrdsecs' => 'BMK.DSK.sumRDs','pdavgwrsecs' => 'BMK.DSK.avgWRs','pdmaxwrsecs' => 'BMK.DSK.maxWRs','pdminwrsecs' => 'BMK.DSK.minWRs','pdstddevpopwrsecs' => 'BMK.DSK.sdpopWRs','pdvarpopwrsecs' => 'BMK.DSK.varpopWRs','pdsumwrsecs' => 'BMK.DSK.sumWRs','pdavgrqsz' => 'BMK.DSK.avgReqs','pdmaxrqsz' => 'BMK.DSK.maxReqs','pdminrqsz' => 'BMK.DSK.minReqs','pdstddevpoprqsz' => 'BMK.DSK.sdpopReqs','pdvarpoprqsz' => 'BMK.DSK.varpopReqs','pdavgqusz' => 'BMK.DSK.avgQus','pdmaxqusz' => 'BMK.DSK.maxQus','pdminqusz' => 'BMK.DSK.minQus','pdstddevpopqusz' => 'BMK.DSK.sdpopQus','pdvarpopqusz' => 'BMK.DSK.varpopQus','pdavgawait' => 'BMK.DSK.avgwait','pdmaxawait' => 'BMK.DSK.maxwait','pdminawait' => 'BMK.DSK.minwait','pdstddevpopawait' => 'BMK.DSK.sdpopwait','pdvarpopawait' => 'BMK.DSK.varpopwait','pdavgutil' => 'BMK.DSK.avgutil','pdmaxutil' => 'BMK.DSK.maxutil','pdminutil' => 'BMK.DSK.minutil','pdstddevpoputil' => 'BMK.DSK.sdpoputil','pdvarpoputil' => 'BMK.DSK.varpoputil','pdavgsvctm' => 'BMK.DSK.avgsvctm','pdmaxsvctm' => 'BMK.DSK.maxsvctm','pdminsvctm' => 'BMK.DSK.minsvctm','pdstddevpopsvctm' => 'BMK.DSK.sdpopsvctm','pdvarpopsvctm' => 'BMK.DSK.varpopsvctm'
		);
		$bench_query = array(
			'pc.`avg%user`' => 'pcavguser','pc.`max%user`' => 'pcmaxuser','pc.`min%user`' => 'pcminuser','pc.`stddev_pop%user`' => 'pcstddevpopuser','pc.`var_pop%user`' => 'pcvarpopuser','pc.`avg%nice`' => 'pcavgnice','pc.`max%nice`' => 'pcmaxnice','pc.`min%nice`' => 'pcminnice','pc.`stddev_pop%nice`' => 'pcstddevpopnice','pc.`var_pop%nice`' => 'pcvarpopnice','pc.`avg%system`' => 'pcavgsystem','pc.`max%system`' => 'pcmaxsystem','pc.`min%system`' => 'pcminsystem','pc.`stddev_pop%system`' => 'pcstddevpopsystem','pc.`var_pop%system`' => 'pcvarpopsystem','pc.`avg%iowait`' => 'pcavgiowait','pc.`max%iowait`' => 'pcmaxiowait','pc.`min%iowait`' => 'pcminiowait','pc.`stddev_pop%iowait`' => 'pcstddevpopiowait','pc.`var_pop%iowait`' => 'pcvarpopiowait','pc.`avg%steal`' => 'pcavgsteal','pc.`max%steal`' => 'pcmaxsteal','pc.`min%steal`' => 'pcminsteal','pc.`stddev_pop%steal`' => 'pcstddevpopsteal','pc.`var_pop%steal`' => 'pcvarpopsteal','pc.`avg%idle`' => 'pcavgidle','pc.`max%idle`' => 'pcmaxidle','pc.`min%idle`' => 'pcminidle','pc.`stddev_pop%idle`' => 'pcstddevpopidle','pc.`var_pop%idle`' => 'pcvarpopidle',
			'pm.`avgkbmemfree`' => 'pmavgkbmemfree','pm.`maxkbmemfree`' => 'pmmaxkbmemfree','pm.`minkbmemfree`' => 'pmminkbmemfree','pm.`stddev_popkbmemfree`' => 'pmstddevpopkbmemfree','pm.`var_popkbmemfree`' => 'pmvarpopkbmemfree','pm.`avgkbmemused`' => 'pmavgkbmemused','pm.`maxkbmemused`' => 'pmmaxkbmemused','pm.`minkbmemused`' => 'pmminkbmemused','pm.`stddev_popkbmemused`' => 'pmstddevpopkbmemused','pm.`var_popkbmemused`' => 'pmvarpopkbmemused','pm.`avg%memused`' => 'pmavgmemused','pm.`max%memused`' => 'pmmaxmemused','pm.`min%memused`' => 'pmminmemused','pm.`stddev_pop%memused`' => 'pmstddevpopmemused','pm.`var_pop%memused`' => 'pmvarpopmemused','pm.`avgkbbuffers`' => 'pmavgkbbuffers','pm.`maxkbbuffers`' => 'pmmaxkbbuffers','pm.`minkbbuffers`' => 'pmminkbbuffers','pm.`stddev_popkbbuffers`' => 'pmstddevpopkbbuffers','pm.`var_popkbbuffers`' => 'pmvarpopkbbuffers','pm.`avgkbcached`' => 'pmavgkbcached','pm.`maxkbcached`' => 'pmmaxkbcached','pm.`minkbcached`' => 'pmminkbcached','pm.`stddev_popkbcached`' => 'pmstddevpopkbcached','pm.`var_popkbcached`' => 'pmvarpopkbcached','pm.`avgkbcommit`' => 'pmavgkbcommit','pm.`maxkbcommit`' => 'pmmaxkbcommit','pm.`minkbcommit`' => 'pmminkbcommit','pm.`stddev_popkbcommit`' => 'pmstddevpopkbcommit','pm.`var_popkbcommit`' => 'pmvarpopkbcommit','pm.`avg%commit`' => 'pmavgcommit','pm.`max%commit`' => 'pmmaxcommit','pm.`min%commit`' => 'pmmincommit','pm.`stddev_pop%commit`' => 'pmstddevpopcommit','pm.`var_pop%commit`' => 'pmvarpopcommit','pm.`avgkbactive`' => 'pmavgkbactive','pm.`maxkbactive`' => 'pmmaxkbactive','pm.`minkbactive`' => 'pmminkbactive','pm.`stddev_popkbactive`' => 'pmstddevpopkbactive','pm.`var_popkbactive`' => 'pmvarpopkbactive','pm.`avgkbinact`' => 'pmavgkbinact','pm.`maxkbinact`' => 'pmmaxkbinact','pm.`minkbinact`' => 'pmminkbinact','pm.`stddev_popkbinact`' => 'pmstddevpopkbinact','pm.`var_popkbinact`' => 'pmvarpopkbinact',
			'pn.`avgrxpck/s`' => 'pnavgrxpcks','pn.`maxrxpck/s`' => 'pnmaxrxpcks','pn.`minrxpck/s`' => 'pnminrxpcks','pn.`stddev_poprxpck/s`' => 'pnstddevpoprxpcks','pn.`var_poprxpck/s`' => 'pnvarpoprxpcks','pn.`sumrxpck/s`' => 'pnsumrxpcks','pn.`avgtxpck/s`' => 'pnavgtxpcks','pn.`maxtxpck/s`' => 'pnmaxtxpcks','pn.`mintxpck/s`' => 'pnmintxpcks','pn.`stddev_poptxpck/s`' => 'pnstddevpoptxpcks','pn.`var_poptxpck/s`' => 'pnvarpoptxpcks','pn.`sumtxpck/s`' => 'pnsumtxpcks','pn.`avgrxkB/s`' => 'pnavgrxkBs','pn.`maxrxkB/s`' => 'pnmaxrxkBs','pn.`minrxkB/s`' => 'pnminrxkBs','pn.`stddev_poprxkB/s`' => 'pnstddevpoprxkBs','pn.`var_poprxkB/s`' => 'pnvarpoprxkBs','pn.`sumrxkB/s`' => 'pnsumrxkBs','pn.`avgtxkB/s`' => 'pnavgtxkBs','pn.`maxtxkB/s`' => 'pnmaxtxkBs','pn.`mintxkB/s`' => 'pnmintxkBs','pn.`stddev_poptxkB/s`' => 'pnstddevpoptxkBs','pn.`var_poptxkB/s`' => 'pnvarpoptxkBs','pn.`sumtxkB/s`' => 'pnsumtxkBs','pn.`avgrxcmp/s`' => 'pnavgrxcmps','pn.`maxrxcmp/s`' => 'pnmaxrxcmps','pn.`minrxcmp/s`' => 'pnminrxcmps','pn.`stddev_poprxcmp/s`' => 'pnstddevpoprxcmps','pn.`var_poprxcmp/s`' => 'pnvarpoprxcmps','pn.`sumrxcmp/s`' => 'pnsumrxcmps','pn.`avgtxcmp/s`' => 'pnavgtxcmps','pn.`maxtxcmp/s`' => 'pnmaxtxcmps','pn.`mintxcmp/s`' => 'pnmintxcmps','pn.`stddev_poptxcmp/s`' => 'pnstddevpoptxcmps','pn.`var_poptxcmp/s`' => 'pnvarpoptxcmps','pn.`sumtxcmp/s`' => 'pnsumtxcmps','pn.`avgrxmcst/s`' => 'pnavgrxmcsts','pn.`maxrxmcst/s`' => 'pnmaxrxmcsts','pn.`minrxmcst/s`' => 'pnminrxmcsts','pn.`stddev_poprxmcst/s`' => 'pnstddevpoprxmcsts','pn.`var_poprxmcst/s`' => 'pnvarpoprxmcsts','pn.`sumrxmcst/s`' => 'pnsumrxmcsts',
			'pd.`avgtps`' => 'pdavgtps','pd.`maxtps`' => 'pdmaxtps','pd.`mintps`' => 'pdmintps','pd.`avgrd_sec/s`' => 'pdavgrdsecs','pd.`maxrd_sec/s`' => 'pdmaxrdsecs','pd.`minrd_sec/s`' => 'pdminrdsecs','pd.`stddev_poprd_sec/s`' => 'pdstddevpoprdsecs','pd.`var_poprd_sec/s`' => 'pdvarpoprdsecs','pd.`sumrd_sec/s`' => 'pdsumrdsecs','pd.`avgwr_sec/s`' => 'pdavgwrsecs','pd.`maxwr_sec/s`' => 'pdmaxwrsecs','pd.`minwr_sec/s`' => 'pdminwrsecs','pd.`stddev_popwr_sec/s`' => 'pdstddevpopwrsecs','pd.`var_popwr_sec/s`' => 'pdvarpopwrsecs','pd.`sumwr_sec/s`' => 'pdsumwrsecs','pd.`avgrq_sz`' => 'pdavgrqsz','pd.`maxrq_sz`' => 'pdmaxrqsz','pd.`minrq_sz`' => 'pdminrqsz','pd.`stddev_poprq_sz`' => 'pdstddevpoprqsz','pd.`var_poprq_sz`' => 'pdvarpoprqsz','pd.`avgqu_sz`' => 'pdavgqusz','pd.`maxqu_sz`' => 'pdmaxqusz','pd.`minqu_sz`' => 'pdminqusz','pd.`stddev_popqu_sz`' => 'pdstddevpopqusz','pd.`var_popqu_sz`' => 'pdvarpopqusz','pd.`avgawait`' => 'pdavgawait','pd.`maxawait`' => 'pdmaxawait','pd.`minawait`' => 'pdminawait','pd.`stddev_popawait`' => 'pdstddevpopawait','pd.`var_popawait`' => 'pdvarpopawait','pd.`avg%util`' => 'pdavgutil','pd.`max%util`' => 'pdmaxutil','pd.`min%util`' => 'pdminutil','pd.`stddev_pop%util`' => 'pdstddevpoputil','pd.`var_pop%util`' => 'pdvarpoputil','pd.`avgsvctm`' => 'pdavgsvctm','pd.`maxsvctm`' => 'pdmaxsvctm','pd.`minsvctm`' => 'pdminsvctm','pd.`stddev_popsvctm`' => 'pdstddevpopsvctm','pd.`var_popsvctm`' => 'pdvarpopsvctm'
		);

		$names = array_values(array_merge($exec_names,$net_names,$disk_names,$bench_names));

	    	$query = "SELECT
			".implode(',', array_map(function ($k, $v) { return sprintf("%s AS '%s'", $k, $v); }, array_keys($exec_query), array_values($exec_query))).",
			n.".implode(",n.",array_values($net_query)).",
			d.".implode(",d.",array_values($disk_query)).",
			b.".implode(",b.",array_values($bench_query))."
			FROM aloja2.execs AS e LEFT JOIN aloja2.clusters AS c ON e.id_cluster = c.id_cluster,
			(
			    SELECT ae.bench AS aebench,
			    ".implode(',', array_map(function ($k, $v) { return sprintf("AVG(%s) AS '%s'", $k, $v); }, array_keys($bench_query), array_values($bench_query)))."
			    FROM aloja2.precal_cpu_metrics AS pc, aloja2.precal_memory_metrics AS pm, aloja2.precal_network_metrics AS pn, aloja2.precal_disk_metrics AS pd, aloja2.execs AS ae
			    WHERE pc.id_exec = pm.id_exec AND pc.id_exec = pn.id_exec AND pc.id_exec = pd.id_exec AND pc.id_exec = ae.id_exec AND ae.id_cluster = '".$reference_cluster."'
			    GROUP BY ae.bench
			) AS b,
			(
			    SELECT
			    ".implode(',', array_map(function ($k, $v) { return sprintf("MAX(%s) AS '%s'", $k, $v); }, array_keys($net_query), array_values($net_query))).",
			    e1.net AS net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			    FROM aloja2.precal_network_metrics AS n1,
			    aloja2.execs AS e1 LEFT JOIN aloja2.clusters AS c1 ON e1.id_cluster = c1.id_cluster
			    WHERE e1.id_exec = n1.id_exec
			    GROUP BY e1.net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			) AS n,
			(
			    SELECT
			    ".implode(',', array_map(function ($k, $v) { return sprintf("MAX(%s) AS '%s'", $k, $v); }, array_keys($disk_query), array_values($disk_query))).",
			    e2.disk AS disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			    FROM aloja2.precal_disk_metrics AS d1,
			    aloja2.execs AS e2 LEFT JOIN aloja2.clusters AS c1 ON e2.id_cluster = c1.id_cluster
			    WHERE e2.id_exec = d1.id_exec
			    GROUP BY e2.disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
			) AS d
			WHERE e.bench = b.aebench AND e.net = n.net AND c.vm_cores = n.vm_cores AND c.vm_RAM = n.vm_RAM
			AND c.vm_size = n.vm_size AND c.vm_OS = n.vm_OS AND c.provider = n.provider AND e.disk = d.disk
			AND c.vm_cores = d.vm_cores AND c.vm_RAM = d.vm_RAM AND c.vm_size = d.vm_size AND c.vm_OS = d.vm_OS
			AND c.provider = d.provider
			AND hadoop_version IS NOT NULL".$where_configs.";";

		return $query;
	}

	public static function getIndexVarweightsExps (&$jsonVarweights, &$jsonVarweightsHeader, $dbml)
	{
		$query="SELECT id_varweights, model, dataslice, creation_time FROM aloja_ml.variable_weights";
		$rows = $dbml->query($query);
		$jsonVarweights = '[';
	    	foreach($rows as $row)
		{
			$url = MLUtils::revertModelToURL($row['model'], $row['dataslice'], 'presets=none&submit=&');

			$model_display = MLUtils::display_models_noasts ($row['model']);
			$slice_display = MLUtils::display_models_noasts ($row['dataslice']);

			$jsonVarweights = $jsonVarweights.(($jsonVarweights=='[')?'':',')."['".$row['id_varweights']."','".$model_display."','".$slice_display."','".$row['creation_time']."','<a href=\'/mlvariableweight?".$url."\'>View</a> <a href=\'/mlclearcache?rmv=".$row['id_varweights']."\'>Remove</a>']";
		}
		$jsonVarweights = $jsonVarweights.']';
		$jsonVarweightsHeader = "[{'title':'ID'},{'title':'Attribute Selection'},{'title':'Advanced Filters'},{'title':'Creation'},{'title':'Actions'}]";
	}
}
?>
