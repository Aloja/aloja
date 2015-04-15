<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLCacheController extends AbstractController
{
	public function mlclearcacheAction()
	{
		$cache_allow = 'localhost';
		$jsonLearners = '';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			if (isset($_GET['ccache']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM summaries";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing summaries from DB');

				$query = "DELETE FROM minconfigs_centers";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing centers from DB');

				$query = "DELETE FROM minconfigs_props";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing props from DB');

				$query = "DELETE FROM minconfigs";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing minconfigs from DB');

				$query = "DELETE FROM resolutions";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing resolutions from DB');

				$query = "DELETE FROM trees";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing trees from DB');

				$query = "DELETE FROM learners";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing learners from DB');

				$command = 'rm '.getcwd().'/cache/query/*.{rds,lock,fin,dat}';
				$output[] = shell_exec($command);
			}

			if (isset($_GET['rml']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM learners WHERE id_learner='".$_GET['rml']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a learner from DB');

				$command = 'rm '.getcwd().'/cache/query/'.$_GET['rml'].'-*';
				$output[] = shell_exec($command);
 			}

			if (isset($_GET['rmm']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM minconfigs WHERE id_minconfigs='".$_GET['rmm']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a minconfig from DB');

				$command = 'rm '.getcwd().'/cache/query/'.$_GET['rmm'].'-*';
				$output[] = shell_exec($command);
 			}

			// Compilation of Learners on Cache
			$query="SELECT v.*, COUNT(t.id_findattrs) as num_trees
				FROM (	SELECT s.*, COUNT(r.id_resolution) AS num_resolutions
					FROM (	SELECT j.*, COUNT(m.id_minconfigs) AS num_minconfigs
						FROM (	SELECT DISTINCT l.id_learner AS id_learner, l.algorithm AS algorithm,
								l.creation_time AS creation_time, l.model AS model,
								COUNT(p.id_prediction) AS num_preds
							FROM learners AS l LEFT JOIN predictions AS p ON l.id_learner = p.id_learner
							GROUP BY l.id_learner
						) AS j LEFT JOIN minconfigs AS m ON j.id_learner = m.id_learner
						GROUP BY j.id_learner
					) AS s LEFT JOIN resolutions AS r ON s.id_learner = r.id_learner
					GROUP BY s.id_learner
				) AS v LEFT JOIN trees AS t ON v.id_learner = t.id_learner
				GROUP BY v.id_learner
				";
			$rows = $dbml->query($query);
			$jsonLearners = '[';
		    	foreach($rows as $row)
			{
				$jsonLearners = $jsonLearners.(($jsonLearners=='[')?'':',')."['".$row['id_learner']."','".$row['algorithm']."','".$row['model']."','".$row['creation_time']."','".$row['num_preds']."','".$row['num_minconfigs']."','".$row['num_resolutions']."','".$row['num_trees']."','<a href=\'/mlclearcache?rml=".$row['id_learner']."\'>Remove</a>']";
			}
			$jsonLearners = $jsonLearners.']';
			$jsonLearningHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Model'},{'title':'Creation'},{'title':'Predictions'},{'title':'MinConfigs'},{'title':'Resolutions'},{'title':'Trees'},{'title':'Actions'}]";

			// Compilation of Minconfs on Cache
			$query="SELECT mj.*, COUNT(mc.sid_minconfigs_centers) AS num_centers
				FROM (	SELECT DISTINCT m.id_minconfigs AS id_minconfigs, m.model AS model, m.is_new as is_new,
						m.creation_time AS creation_time, COUNT(mp.sid_minconfigs_props) AS num_props, l.algorithm
					FROM minconfigs AS m LEFT JOIN minconfigs_props AS mp ON m.id_minconfigs = mp.id_minconfigs, learners AS l
					WHERE l.id_learner = m.id_learner
					GROUP BY m.id_minconfigs
				) AS mj LEFT JOIN minconfigs_centers AS mc ON mj.id_minconfigs = mc.id_minconfigs
				GROUP BY mj.id_minconfigs
				";
			$rows = $dbml->query($query);
			$jsonMinconfs = '[';
		    	foreach($rows as $row)
			{
				$jsonMinconfs = $jsonMinconfs.(($jsonMinconfs=='[')?'':',')."['".$row['id_minconfigs']."','".$row['algorithm']."','".$row['model']."','".$row['creation_time']."','".$row['is_new']."','".$row['num_props']."','".$row['num_centers']."','<a href=\'/mlclearcache?rmm=".$row['id_minconfigs']."\'>Remove</a>']";
			}
			$jsonMinconfs = $jsonMinconfs.']';
			$jsonMinconfsHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Model'},{'title':'Creation'},{'title':'Is_New'},{'title':'Properties'},{'title':'Centers'},{'title':'Actions'}]";

			$dbml = null;
		}
		catch(Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$output = array();
		}
		echo $this->container->getTwig()->render('mltemplate/mlclearcache.html.twig',
			array(
				'selected' => 'mlclearcache',
				'learners' => $jsonLearners,
				'header_learners' => $jsonLearningHeader,
				'minconfs' => $jsonMinconfs,
				'header_minconfs' => $jsonMinconfsHeader
			)
		);
	}
}
?>
