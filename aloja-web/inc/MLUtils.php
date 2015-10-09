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

		if ($slice_info !== false)
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

		if ($input[0] == " ") $input = substr($input, 1);
		$data_array = explode(" ",$input);
		for($i = 1; $i < count($data_array); $i = $i + 2)
		{
			$param1 = $data_array[$i-1];
			$param2 = $data_array[$i];
			if ($param2 != '("*")') $data_display = $data_display.' '.$param1.' '.$param2;
		}
		if ($data_display == '') $data_display = 'No Filters';

		return $data_display;
	}

	public static function getIndexModels (&$jsonLearners, &$jsonLearningHeader, $dbml)
	{
		$query="SELECT DISTINCT l.id_learner AS id_learner, l.algorithm AS algorithm,
				l.creation_time AS creation_time, l.model AS model, l.dataslice AS advanced,
				COUNT(p.id_prediction) AS num_preds
			FROM aloja_ml.learners AS l LEFT JOIN aloja_ml.predictions AS p ON l.id_learner = p.id_learner
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
}
?>
