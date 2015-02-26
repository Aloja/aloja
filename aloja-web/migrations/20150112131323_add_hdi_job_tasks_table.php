<?php

use Phinx\Migration\AbstractMigration;

class AddHdiJobTasksTable extends AbstractMigration
{
    /**
     * Change Method.
     *
     * More information on this method is available here:
     * http://docs.phinx.org/en/latest/migrations.html#the-change-method
     *
     * Uncomment this method if you would like to use it.
     */
    public function change()
    {
    	$hdiJobTasks = $this->table('HDI_JOB_tasks', array('id' => 'hdi_job_task_id'));
    	$hdiJobTasks->addColumn("JOB_ID", 'string', array('limit' => 255))
    	->addColumn('TASK_ID', 'string', array('limit' => 255))
    	->addColumn('BYTES_READ', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('BYTES_WRITTEN', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('COMMITTED_HEAP_BYTES', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('CPU_MILLISECONDS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('FAILED_SHUFFLE', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('FILE_BYTES_READ', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('FILE_BYTES_WRITTEN', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('FILE_READ_OPS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('FILE_WRITE_OPS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('GC_TIME_MILLIS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('MAP_INPUT_RECORDS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('MAP_OUTPUT_RECORDS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('MERGED_MAP_OUTPUTS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('PHYSICAL_MEMORY_BYTES', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('SPILLED_RECORDS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('SPLIT_RAW_BYTES', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('TASK_ERROR', 'string', array('limit' => 255))
    	->addColumn('TASK_FINISH_TIME', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('TASK_START_TIME', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('TASK_STATUS', 'string', array('limit' => 255))
    	->addColumn('TASK_TYPE', 'string', array('limit' => 255))
    	->addColumn('VIRTUAL_MEMORY_BYTES', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('WASB_BYTES_READ', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('WASB_BYTES_WRITTEN', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('WASB_LARGE_READ_OPS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('WASB_READ_OPS', 'biginteger', array('default' => 0, 'null' => true))
    	->addColumn('WASB_WRITE_OPS', 'biginteger', array('default' => 0, 'null' => true))
    	->create();
    }
    
    
    /**
     * Migrate Up.
     */
    public function up()
    {
    
    }

    /**
     * Migrate Down.
     */
    public function down()
    {

    }
}