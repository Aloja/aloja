<?php

use Phinx\Migration\AbstractMigration;

class AddHadoopVersionExecsTable extends AbstractMigration
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
    	$this->execute("ALTER TABLE execs ADD COLUMN hadoop_version varchar(128) default NULL");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("ALTER TABLE execs DROP COLUMN hadoop_version");
    }
}