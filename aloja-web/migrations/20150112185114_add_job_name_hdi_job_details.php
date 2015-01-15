<?php

use Phinx\Migration\AbstractMigration;

class AddJobNameHdiJobDetails extends AbstractMigration
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
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN job_name VARCHAR(255)");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD UNIQUE job_id_uq (JOB_ID)");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN job_name");
    	$this->execute("ALTER TABLE HDI_JOB_details DROP INDEX job_id_uq");
    }
}