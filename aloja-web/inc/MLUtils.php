<?php

namespace alojaweb\inc;

use alojaweb\inc\Utils;

class MLUtils
{
	public function generateModelInfo($param_names, $params, $condition, $db)
	{
		//$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$model_info = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
			if ($condition) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
			else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');
		}
		return $model_info;
	}

	public function generateSimpleInstance($param_names, $params, $condition, $db)
	{
		//$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$instance = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));

			$tokens[$p] = '';
			if ($condition && empty($params[$p])) { $tokens[$p] = '*'; }
			elseif (!$condition && empty($params[$p])) { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			$instance = $instance.(($instance=='')?'':',').$tokens[$p];
		}
		return $instance;
	}

	public function generateInstances($param_names, $params, $generalize, $db)
	{
		//$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = $instances = array();

		// Get info from clusters (Part of header_names!)
		$cluster_header_names = array(
			'id_cluster' => 'Cluster','name' => 'Cl.Name','datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores',
			'vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type'
		);
		$cluster_descriptor = array();
		$query = "select ".implode(",",array_keys($cluster_header_names))." from clusters;";
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
		if (empty($params['id_clusters']))
		{
			$params['id_clusters'] = array();
			$paramAllOptions['id_clusters'] = array_column($filter_options['id_cluster'],'id_cluster');
			foreach ($paramAllOptions['id_clusters'] as $par) $params['id_clusters'][] = $par;
		}

		// For each cluster selected, launch an instance...
		foreach ($params['id_clusters'] as $cl) 
		{
			$cl_characteristics = "Cl".implode(",",$cluster_descriptor[$cl]);
			
			$instance = '';
			foreach ($param_names as $p) 
			{
				if ($p != "id_clusters")
				{
					if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));

					$tokens[$p] = '';
					if ($generalize && empty($params[$p])) { $tokens[$p] = '*'; }
					elseif (!$generalize && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
					else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
					$instance = $instance.(($instance=='')?'':',').$tokens[$p];
				}
				else
				{
					$instance = $instance.(($instance=='')?'':',').$cl_characteristics;
				}
			}
			$instances[] = $instance;

		}
		return $instances;
	}

	public function findMatchingModels ($model_info, &$possible_models, &$possible_models_id)
	{
		if (($fh = fopen(getcwd().'/cache/query/record.data', 'r')) !== FALSE)
		{
			while (!feof($fh))
			{
				$line = fgets($fh, 4096);
				if (preg_match("(((bench|net|disk|blk_size) (\(.+\)))( )?)", $line) && !preg_match('/SUMMARY/',$line))
				{
					$fts = explode(" : ",$line);
					$parts = explode(" ",$fts[1]);
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
						$possible_models[] = $line;
						$possible_models_id[] = $fts[0];
					}
				}
			}
			fclose($fh);
		}
	}
}
?>
