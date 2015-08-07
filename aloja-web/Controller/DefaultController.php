<?php

namespace alojaweb\Controller;

use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class DefaultController extends AbstractController
{

    public function indexAction()
    {
        return $this->render('welcome.html.twig', array());
    }

    public function histogramAction()
    {
        $idExec = '';
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec)
                throw new \Exception("No execution selected!");
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        echo $this->container->getTwig()->render('histogram/histogram.html.twig',
            array('selected' => 'Histogram',
                'idExec' => $idExec
            ));
    }

    public function histogramHDIAction()
    {
        $idExec = '';
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec)
                throw new \Exception("No execution selected!");
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        echo $this->container->getTwig()->render('histogram/histogramhdi.html.twig',
            array('selected' => 'Histogram',
                'idExec' => $idExec
            ));
    }

    public function publicationsAction()
    {
        echo $this->container->getTwig()->render('publications/publications.html.twig', array(
            'selected' => 'Publications',
            'title' => 'ALOJA Publications and Slides'));
    }

    public function teamAction()
    {
        echo $this->container->getTwig()->render('team/team.html.twig', array(
            'selected' => 'Team',
            'title' => 'ALOJA Team & Collaborators'));
    }

    public function clustersAction()
    {
        $clusterNameSelected = null;

        if(isset($_GET['cluster_name'])) {
            $clusterNameSelected = $_GET['cluster_name'];
        }

        $filter_execs = DBUtils::getFilterExecs();

        $db = $this->container->getDBUtils();
        $clusters = $db->get_rows("SELECT * FROM clusters c WHERE id_cluster IN (SELECT distinct(id_cluster) FROM execs e WHERE 1 $filter_execs);");

        echo $this->container->getTwig()->render('clusters/clusters.html.twig', array(
            'selected' => 'Clusters',
            'clusters' => $clusters,
            'clusterNameSelected' => $clusterNameSelected,
            'title' => 'ALOJA Clusters'));
    }

    public function clusterCostsAction()
    {
        echo $this->container->getTwig()->render('clusters/clustercosts.html.twig', array(
            'selected' => 'Clusters Costs',
            'title' => 'ALOJA Clusters Costs'));
    }
}
