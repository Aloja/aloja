<?php

use Phinx\Migration\AbstractMigration;

class AddIdExecHdiJobTasks extends AbstractMigration
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
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN id_exec INT(11)");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN id_exec");
    }
}