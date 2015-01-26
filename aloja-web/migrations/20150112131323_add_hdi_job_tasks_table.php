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
    	->addColumn('BYTES_READ', 'biginteger')
    	->addColumn('BYTES_WRITTEN', 'biginteger')
    	->addColumn('COMMITTED_HEAP_BYTES', 'biginteger')
    	->addColumn('CPU_MILLISECONDS', 'biginteger')
    	->addColumn('FAILED_SHUFFLE', 'biginteger')
    	->addColumn('FILE_BYTES_READ', 'biginteger')
    	->addColumn('FILE_BYTES_WRITTEN', 'biginteger')
    	->addColumn('FILE_READ_OPS', 'biginteger')
    	->addColumn('FILE_WRITE_OPS', 'biginteger')
    	->addColumn('GC_TIME_MILLIS', 'biginteger')
    	->addColumn('MAP_INPUT_RECORDS', 'biginteger')
    	->addColumn('MAP_OUTPUT_RECORDS', 'biginteger')
    	->addColumn('MERGED_MAP_OUTPUTS', 'biginteger')
    	->addColumn('PHYSICAL_MEMORY_BYTES', 'biginteger')
    	->addColumn('SPILLED_RECORDS', 'biginteger')
    	->addColumn('SPLIT_RAW_BYTES', 'biginteger')
    	->addColumn('TASK_ERROR', 'string', array('limit' => 255))
    	->addColumn('TASK_FINISH_TIME', 'biginteger')
    	->addColumn('TASK_START_TIME', 'biginteger')
    	->addColumn('TASK_STATUS', 'string', array('limit' => 255))
    	->addColumn('TASK_TYPE', 'string', array('limit' => 255))
    	->addColumn('VIRTUAL_MEMORY_BYTES', 'biginteger')
    	->addColumn('WASB_BYTES_READ', 'biginteger')
    	->addColumn('WASB_BYTES_WRITTEN', 'biginteger')
    	->addColumn('WASB_LARGE_READ_OPS', 'biginteger')
    	->addColumn('WASB_READ_OPS', 'biginteger')
    	->addColumn('WASB_WRITE_OPS', 'biginteger')
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