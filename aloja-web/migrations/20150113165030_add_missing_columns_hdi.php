<?php

use Phinx\Migration\AbstractMigration;

class AddMissingColumnsHdi extends AbstractMigration
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
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN BAD_ID VARCHAR(255)");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN FILE_LARGE_READ_OPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN RECORDS_WRITTEN BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN COMBINE_INPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN COMBINE_OUTPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN MAP_OUTPUT_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN CONNECTION BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN IO_ERROR VARCHAR(255)");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN MAP_OUTPUT_MATERIALIZED_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN MAP_OUTPUT_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN MAP_OUTPUT_MATERIALIZED_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN MB_MILLIS_REDUCES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN MILLIS_REDUCES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN RACK_LOCAL_MAPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN REDUCE_INPUT_GROUPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN REDUCE_INPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN REDUCE_OUTPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN REDUCE_SHUFFLE_BYTES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN WRONG_LENGTH BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN WRONG_MAP BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN WRONG_REDUCE BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN TOTAL_LAUNCHED_REDUCES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN SHUFFLED_MAPS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN SLOTS_MILLIS_REDUCES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_details ADD COLUMN VCORES_MILLIS_REDUCES BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN COMBINE_INPUT_RECORDS BIGINT");
    	$this->execute("ALTER TABLE HDI_JOB_tasks ADD COLUMN COMBINE_OUTPUT_RECORDS BIGINT");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN BAD_ID");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN FILE_LARGE_READ_OPS");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN RECORDS_WRITTEN");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN COMBINE_INPUT_RECORDS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN COMBINE_OUTPUT_RECORDS");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN MAP_OUTPUT_BYTES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN CONNECTION");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN IO_ERROR");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN MAP_OUTPUT_MATERIALIZED_BYTES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN MAP_OUTPUT_BYTES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN MAP_OUTPUT_MATERIALIZED_BYTES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN MB_MILLIS_REDUCES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN MILLIS_REDUCES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN RACK_LOCAL_MAPS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN REDUCE_INPUT_GROUPS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN REDUCE_INPUT_RECORDS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN REDUCE_OUTPUT_RECORDS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN REDUCE_SHUFFLE_BYTES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN WRONG_LENGTH");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN WRONG_MAP");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN WRONG_REDUCE");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN SHUFFLED_MAPS");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN TOTAL_LAUNCHED_REDUCES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN SLOTS_MILLIS_REDUCES");
		$this->execute("ALTER TABLE HDI_JOB_details DROP COLUMN VCORES_MILLIS_REDUCES");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN COMBINE_INPUT_RECORDS");
		$this->execute("ALTER TABLE HDI_JOB_tasks DROP COLUMN COMBINE_OUTPUT_RECORDS");
    }
}