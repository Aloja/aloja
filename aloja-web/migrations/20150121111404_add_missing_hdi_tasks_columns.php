<?php

use Phinx\Migration\AbstractMigration;

class AddMissingHdiTasksColumns extends AbstractMigration
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
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN REDUCE_INPUT_GROUPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN REDUCE_OUTPUT_GROUPS BIGINT");
    	$this->execute("CREATE UNIQUE INDEX UQ_TASKID ON HDI_JOB_tasks(TASK_ID)");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN REDUCE_SHUFFLE_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN REDUCE_INPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN REDUCE_OUTPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN SHUFFLED_MAPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN BAD_ID BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN IO_ERROR BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN WRONG_LENGTH BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN CONNECTION BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN WRONG_MAP BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN WRONG_REDUCE BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN CHECKSUM VARCHAR(255)");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN NUM_FAILED_MAPS VARCHAR(255)");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN REDUCE_INPUT_GROUPS");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN REDUCE_OUTPUT_GROUPS");
    	$this->execute("DROP INDEX UQ_TASKID ON HDI_JOB_tasks");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN REDUCE_SHUFFLE_BYTES");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN REDUCE_INPUT_RECORDS");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN REDUCE_OUTPUT_RECORDS");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN SHUFFLED_MAPS");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN BAD_ID");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN IO_ERROR");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN WRONG_LENGTH");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN CONNECTION");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN WRONG_MAP");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN WRONG_REDUCE");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN CHECKSUM");
    	$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN NUM_FAILED_MAPS");
    }
}