<?php

use Phinx\Migration\AbstractMigration;

class HdinsightData extends AbstractMigration
{
    /**
     * Change Method.
     *
     * More information on this method is available here:
     * http://docs.phinx.org/en/latest/migrations.html#the-change-method
     *
     * Uncomment this method if you would like to use it.
     *
    public function change()
    {
    }
    */
    
    /**
     * Migrate Up.
     */
    public function up()
    {
    	$this->execute("INSERT INTO clusters(id_cluster,name,cost_hour,type,link) values(3,'HDInsight','0.32','PaaS','http://azure.microsoft.com/en-gb/pricing/details/hdinsight/')");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
		$this->execute("DELETE FROM clusters WHERE id_cluster=3");
    }
}