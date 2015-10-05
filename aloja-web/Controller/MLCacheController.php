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
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);


			if (isset($_GET['ccache']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.summaries";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing summaries from DB');

				$query = "DELETE FROM aloja_ml.minconfigs_centers";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing centers from DB');

				$query = "DELETE FROM aloja_ml.minconfigs_props";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing props from DB');

				$query = "DELETE FROM aloja_ml.minconfigs";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing aloja_ml.minconfigs from DB');

				$query = "DELETE FROM aloja_ml.resolutions";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing resolutions from DB');

				$query = "DELETE FROM aloja_ml.trees";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing trees from DB');

				$query = "DELETE FROM aloja_ml.learners";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing learners from DB');

				$query = "DELETE FROM aloja_ml.model_storage";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing file models from DB');

				$query = "DELETE FROM aloja_ml.precisions";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing precisions from DB');

				$command = 'rm -f '.getcwd().'/cache/query/*.{rds,lock,fin,dat,csv}';
				$output[] = shell_exec($command);
			}

			if (isset($_GET['rml']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.learners WHERE id_learner='".$_GET['rml']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a learner from DB');

				$query = "DELETE FROM aloja_ml.model_storage WHERE id_hash='".$_GET['rml']."' AND type='learner'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a model from DB');

				$command = 'rm -f '.getcwd().'/cache/query/'.$_GET['rml'].'*';
				$output[] = shell_exec($command);
 			}

			if (isset($_GET['rmm']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.minconfigs WHERE id_minconfigs='".$_GET['rmm']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a minconfig from DB');

				$query = "DELETE FROM aloja_ml.model_storage WHERE id_hash='".$_GET['rmm']."' AND type='minconf'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a model from DB');

				$command = 'rm -f '.getcwd().'/cache/query/'.$_GET['rmm'].'*';
				$output[] = shell_exec($command);
 			}

			if (isset($_GET['rmr']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.resolutions WHERE id_resolution='".$_GET['rmr']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a resolution from DB');

				$command = 'rm -f '.getcwd().'/cache/query/'.$_GET['rmr'].'*';
				$output[] = shell_exec($command);
 			}

			if (isset($_GET['rms']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.summaries WHERE id_summaries='".$_GET['rms']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a summary from DB');

				$command = 'rm -f '.getcwd().'/cache/query/'.$_GET['rms'].'*';
				$output[] = shell_exec($command);
 			}

			if (isset($_GET['rmp']))// && isset($_SERVER['HTTP_REFERER']) && $_SERVER['HTTP_REFERER'] != $cache_allow)
 			{
				$query = "DELETE FROM aloja_ml.precisions WHERE id_precision='".$_GET['rmp']."'";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when removing a precision from DB');

				$command = 'rm -f '.getcwd().'/cache/query/'.$_GET['rmp'].'*';
				$output[] = shell_exec($command);
 			}

			// Compilation of Learners on Cache
			$query="SELECT v.*, COUNT(t.id_findattrs) as num_trees
				FROM (	SELECT s.*, COUNT(r.id_resolution) AS num_resolutions
					FROM (	SELECT j.*, COUNT(m.id_minconfigs) AS num_minconfigs
						FROM (	SELECT DISTINCT l.id_learner AS id_learner, l.algorithm AS algorithm,
								l.creation_time AS creation_time, l.model AS model, l.dataslice AS advanced,
								COUNT(p.id_prediction) AS num_preds
							FROM aloja_ml.learners AS l LEFT JOIN aloja_ml.predictions AS p ON l.id_learner = p.id_learner
							GROUP BY l.id_learner
						) AS j LEFT JOIN aloja_ml.minconfigs AS m ON j.id_learner = m.id_learner
						GROUP BY j.id_learner
					) AS s LEFT JOIN aloja_ml.resolutions AS r ON s.id_learner = r.id_learner
					GROUP BY s.id_learner
				) AS v LEFT JOIN aloja_ml.trees AS t ON v.id_learner = t.id_learner
				GROUP BY v.id_learner
				";
			$rows = $dbml->query($query);
			$jsonLearners = '[';
		    	foreach($rows as $row)
			{
				if (strpos($row['model'],'*') !== false) $umodel = 'umodel=umodel&'; else $umodel = '';
				$url = MLUtils::revertModelToURL($row['model'], $row['advanced'], 'presets=none&submit=&learner[]='.$row['algorithm'].'&'.$umodel);

				$jsonLearners = $jsonLearners.(($jsonLearners=='[')?'':',')."['".$row['id_learner']."','".$row['algorithm']."','".$row['model']."','".$row['advanced']."','".$row['creation_time']."','".$row['num_preds']."','".$row['num_minconfigs']."','".$row['num_resolutions']."','".$row['num_trees']."','<a href=\'/mlprediction?".$url."\'>View</a> <a href=\'/mlclearcache?rml=".$row['id_learner']."\'>Remove</a>']";
			}
			$jsonLearners = $jsonLearners.']';
			$jsonLearningHeader = "[{'title':'ID'},{'title':'Algorithm'},{'title':'Model'},{'title':'Advanced'},{'title':'Creation'},{'title':'Predictions'},{'title':'MinConfigs'},{'title':'Resolutions'},{'title':'Trees'},{'title':'Actions'}]";

			// Compilation of Minconfs on Cache
			$query="SELECT mj.*, COUNT(mc.sid_minconfigs_centers) AS num_centers
				FROM (	SELECT DISTINCT m.id_minconfigs AS id_minconfigs, m.model AS model, m.is_new as is_new,
						m.creation_time AS creation_time, COUNT(mp.sid_minconfigs_props) AS num_props, l.algorithm
					FROM aloja_ml.minconfigs AS m LEFT JOIN aloja_ml.minconfigs_props AS mp ON m.id_minconfigs = mp.id_minconfigs, aloja_ml.learners AS l
					WHERE l.id_learner = m.id_learner
					GROUP BY m.id_minconfigs
				) AS mj LEFT JOIN aloja_ml.minconfigs_centers AS mc ON mj.id_minconfigs = mc.id_minconfigs
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

			// Compilation of Resolutions on Cache
			$query="SELECT DISTINCT id_resolution, id_learner, model, creation_time, sigma, count(*) AS instances
				FROM aloja_ml.resolutions
				GROUP BY id_resolution
				";
			$rows = $dbml->query($query);
			$jsonResolutions = '[';
		    	foreach($rows as $row)
			{
				$jsonResolutions = $jsonResolutions.(($jsonResolutions=='[')?'':',')."['".$row['id_resolution']."','".$row['id_learner']."','".$row['model']."','".$row['creation_time']."','".$row['sigma']."','".$row['instances']."','<a href=\'/mlclearcache?rmr=".$row['id_resolution']."\'>Remove</a>']";
			}
			$jsonResolutions = $jsonResolutions.']';
			$jsonResolutionsHeader = "[{'title':'ID'},{'title':'Learner'},{'title':'Model'},{'title':'Creation'},{'title':'Sigma'},{'title':'Instances'},{'title':'Actions'}]";

			// Compilation of Summaries on Cache
			$query="SELECT DISTINCT id_summaries, model, dataslice, creation_time
				FROM aloja_ml.summaries
				";
			$rows = $dbml->query($query);
			$jsonSummaries = '[';
		    	foreach($rows as $row)
			{
				$jsonSummaries = $jsonSummaries.(($jsonSummaries=='[')?'':',')."['".$row['id_summaries']."','".$row['model']."','".$row['dataslice']."','".$row['creation_time']."','<a href=\'/mlclearcache?rms=".$row['id_summaries']."\'>Remove</a>']";
			}
			$jsonSummaries = $jsonSummaries.']';
			$jsonSummariesHeader = "[{'title':'ID'},{'title':'Model'},{'title':'Advanced'},{'title':'Creation'},{'title':'Actions'}]";

			// Compilation of Precisions on Cache
			$query="SELECT id_precision, model, dataslice, creation_time
				FROM aloja_ml.precisions
				GROUP BY id_precision
				";
			$rows = $dbml->query($query);
			$jsonPrecisions = '[';
		    	foreach($rows as $row)
			{
				$jsonPrecisions = $jsonPrecisions.(($jsonPrecisions=='[')?'':',')."['".$row['id_precision']."','".$row['model']."','".$row['dataslice']."','".$row['creation_time']."','<a href=\'/mlclearcache?rmp=".$row['id_precision']."\'>Remove</a>']";
			}
			$jsonPrecisions = $jsonPrecisions.']';
			$jsonPrecisionsHeader = "[{'title':'ID'},{'title':'Model'},{'title':'Advanced'},{'title':'Creation'},{'title':'Actions'}]";

			$dbml = null;
		}
		catch(Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$output = array();
		}

		return $this->render('mltemplate/mlclearcache.html.twig',
			array(
				'learners' => $jsonLearners,
				'header_learners' => $jsonLearningHeader,
				'minconfs' => $jsonMinconfs,
				'header_minconfs' => $jsonMinconfsHeader,
				'resolutions' => $jsonResolutions,
				'header_resolutions' => $jsonResolutionsHeader,
				'summaries' => $jsonSummaries,
				'header_summaries' => $jsonSummariesHeader,
				'precisions' => $jsonPrecisions,
				'header_precisions' => $jsonPrecisionsHeader
			)
		);
	}
}
?>
