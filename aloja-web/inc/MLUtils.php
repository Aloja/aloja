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
			if (array_key_exists($p,$filter_options)) $paramAllOptions[$p] = $filter_options[$p];
			if ($condition) $model_info = $model_info.((empty($params[$p]))?' '.$p.' ("*")':' '.$p.' ("'.implode('","',$params[$p]).'")');
			else $model_info = $model_info.((empty($params[$p]))?' '.$p.' ("'.implode('","',$paramAllOptions[$p]).'")':' '.$p.' ("'.implode('","',$params[$p]).'")');
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
			elseif (!$condition && empty($params[$p])) { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			$instance = $instance.(($instance=='')?'':',').$tokens[$p];
		}
		return $instance;
	}

	public static function generateInstances(\alojaweb\Filter\Filter $filters, $param_names, $params, $generalize)
	{
		$filter_options = $filters->getFilterChoices();

		$paramAllOptions = $tokens = $instances = array();

		// Get info from clusters (Part of header_names!)
		$cluster_header_names = array(
			'id_cluster' => 'Cluster','name' => 'Cl.Name','datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores',
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
		if (empty($params['id_clusters']))
		{
			$params['id_clusters'] = array();
			$paramAllOptions['id_clusters'] = $filter_options['id_cluster'];
			foreach ($paramAllOptions['id_clusters'] as $par) $params['id_clusters'][] = $par;
		}

		// For each cluster selected, launch an instance...
		foreach ($params['id_clusters'] as $cl) 
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
			$cl_characteristics = "Cl".implode(",",$cluster_descriptor[$cl]);

			$instance = '';
			foreach ($param_names as $p) 
			{
				// Ignore for now. Will be used at each cluster characteristics
				if (array_key_exists($p,$cluster_header_names) && $p != "id_clusters") continue;

				if ($p != "id_clusters")
				{
					if (array_key_exists($p,$filter_options)) $paramAllOptions[$p] = $filter_options[$p];

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
}
?>
