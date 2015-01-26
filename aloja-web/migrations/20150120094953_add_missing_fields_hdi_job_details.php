<?php

use Phinx\Migration\AbstractMigration;

class AddMissingFieldsHdiJobDetails extends AbstractMigration
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
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN CHECKSUM VARCHAR(255)");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN NUM_FAILED_MAPS VARCHAR(255)");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN CHECKSUM");
    	$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN NUM_FAILED_MAPS");
    }
}