<?php
function delete_none($array) {
	if (($key = array_search('None', $array)) !== false) {
		unset ($array[$key]);
	}
	return $array;
}


function read_params($item_name, &$where_configs, &$configurations, &$concat_config) {
	$single_item_name = substr($item_name, 0, -1);

	if (isset($_GET[$item_name])) {
		$items = $_GET[$item_name];
		$items = delete_none($items);
	} else {
		if ($item_name == 'benchs') {
			$items = array('pagerank', 'terasort', 'wordcount');
		} elseif ($item_name == 'nets') {
			$items = array('IB', 'ETH');
		} elseif ($item_name == 'disks') {
			$items = array('SSD', 'HDD');
		} else {
			$items = array();
		}

	}
	
	if ($items) {
		if ($item_name != 'benchs') {
			$configurations[] = $single_item_name;
			if ($concat_config) $concat_config .= ",'_',";

			if ($item_name == 'id_clusters') {
				$conf_prefix = 'CL';
			} elseif ($item_name == 'iofilebufs') {
				$conf_prefix = 'I';
			} else {
				$conf_prefix = substr($single_item_name, 0, 1);
			}

			//avoid alphanumeric fields
			if (!in_array($item_name, array('nets', 'disks'))) {
				$concat_config .= "'".$conf_prefix."', $single_item_name";
			} else {
				$concat_config .= " $single_item_name";
			}
		}
		$where_configs .=
		' AND '.
		$single_item_name. //remove trailing 's'
		' IN ("'.join('","', $items).'")';
	}

	return $items;
}