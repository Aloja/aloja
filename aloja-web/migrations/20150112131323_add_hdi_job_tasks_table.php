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
    	$hdiJobTasks->addColumn("JOB_ID", 'integer')
    	->addColumn('TASK_ID', 'integer')
    	->addColumn('BYTES_READ', 'integer')
    	->addColumn('BYTES_WRITTEN', 'integer')
    	->addColumn('COMMITTED_HEAP_BYTES', 'integer')
    	->addColumn('CPU_MILLISECONDS', 'integer')
    	->addColumn('FAILED_SHUFFLE', 'integer')
    	->addColumn('FILE_BYTES_READ', 'integer')
    	->addColumn('FILE_BYTES_WRITTEN', 'integer')
    	->addColumn('FILE_READ_OPS', 'integer')
    	->addColumn('FILE_WRITE_OPS', 'integer')
    	->addColumn('GC_TIME_MILLIS', 'integer')
    	->addColumn('MAP_INPUT_RECORDS', 'integer')
    	->addColumn('MAP_OUTPUT_RECORDS', 'integer')
    	->addColumn('MERGED_MAP_OUTPUTS', 'integer')
    	->addColumn('PHYSICAL_MEMORY_BYTES', 'integer')
    	->addColumn('SPILLED_RECORDS', 'integer')
    	->addColumn('SPLIT_RAW_BYTES', 'integer')
    	->addColumn('TASK_ERROR', 'integer')
    	->addColumn('TASK_FINISH_TIME', 'integer')
    	->addColumn('TASK_START_TIME', 'integer')
    	->addColumn('TASK_STATUS', 'integer')
    	->addColumn('TASK_TYPE', 'integer')
    	->addColumn('VIRTUAL_MEMORY_BYTES', 'integer')
    	->addColumn('WASB_BYTES_READ', 'integer')
    	->addColumn('WASB_BYTES_WRITTEN', 'integer')
    	->addColumn('WASB_LARGE_READ_OPS', 'integer')
    	->addColumn('WASB_READ_OPS', 'integer')
    	->addColumn('WASB_WRITE_OPS', 'integer')
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