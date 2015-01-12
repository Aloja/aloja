<?php

use Phinx\Migration\AbstractMigration;

class AddHdiJobDetailsTable extends AbstractMigration
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
    	$hdiJobStatus = $this->table('HDI_JOB_details', array('id' => 'hdi_job_details_id'));
    	$hdiJobStatus->addColumn('id_exec', 'integer')
    		->addColumn('JOB_ID', 'integer')
    		->addColumn('BYTES_READ', 'integer')
    		->addColumn('BYTES_WRITTEN', 'integer')
    		->addColumn('COMMITTED_HEAP_BYTES', 'integer')
    		->addColumn('CPU_MILLISECONDS', 'integer')
    		->addColumn('FAILED_MAPS', 'integer')
    		->addColumn('FAILED_REDUCES', 'integer')
    		->addColumn('FAILED_SHUFFLE', 'integer')
    		->addColumn('FILE_BYTES_READ', 'integer')
    		->addColumn('FILE_BYTES_WRITTEN', 'integer')
    		->addColumn('FILE_LARGE_READ_OPS', 'integer')
    		->addColumn('FILE_READ_OPS', 'integer')
    		->addColumn('FILE_WRITE_OPS', 'integer')
    		->addColumn('FINISHED_MAPS', 'integer')
    		->addColumn('FINISH_TIME', 'integer')
    		->addColumn('GC_TIME_MILLIS', 'integer')
    		->addColumn('JOB_PRIORITY', 'integer')
    		->addColumn('LAUNCH_TIME', 'integer')
    		->addColumn('MAP_INPUT_RECORDS', 'integer')
    		->addColumn('MAP_OUTPUT_RECORDS', 'integer')
    		->addColumn('MB_MILLIS_MAPS', 'integer')
    		->addColumn('MERGED_MAP_OUTPUTS', 'integer')
    		->addColumn('MILLIS_MAPS', 'integer')
    		->addColumn('OTHER_LOCAL_MAPS', 'integer')
    		->addColumn('PHYSICAL_MEMORY_BYTES', 'integer')
    		->addColumn('SLOTS_MILLIS_MAPS', 'integer')
    		->addColumn('SPILLED_RECORDS', 'integer')
    		->addColumn('SPLIT_RAW_BYTES', 'integer')
    		->addColumn('SUBMIT_TIME', 'integer')
    		->addColumn('TOTAL_LAUNCHED_MAPS', 'integer')
    		->addColumn('TOTAL_MAPS', 'integer')
    		->addColumn('TOTAL_REDUCES', 'integer')
    		->addColumn('USER', 'integer')
    		->addColumn('VCORES_MILLIS_MAPS', 'integer')
    		->addColumn('VIRTUAL_MEMORY_BYTES', 'integer')
    		->addColumn('WASB_BYTES_READ', 'integer')
    		->addColumn('WASB_BYTES_WRITTEN', 'integer')
    		->addColumn('WASB_LARGE_READ_OPS', 'integer')
    		->addColumn('WASB_READ_OPS', 'integer')
    		->addColumn('WASB_WRITE_OPS', 'integer')
    		->addForeignKey('id_exec','execs','id_exec', array('delete' => 'CASCADE'))
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