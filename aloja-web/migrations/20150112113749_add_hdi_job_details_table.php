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
    		->addColumn('JOB_ID', 'string', array('limit' => 255))
    		->addColumn('BYTES_READ', 'biginteger')
    		->addColumn('BYTES_WRITTEN', 'biginteger')
    		->addColumn('COMMITTED_HEAP_BYTES', 'biginteger')
    		->addColumn('CPU_MILLISECONDS', 'biginteger')
    		->addColumn('FAILED_MAPS', 'biginteger')
    		->addColumn('FAILED_REDUCES', 'biginteger')
    		->addColumn('FAILED_SHUFFLE', 'biginteger')
    		->addColumn('FILE_BYTES_READ', 'biginteger')
    		->addColumn('FILE_BYTES_WRITTEN', 'biginteger')
    		->addColumn('FILE_LARGE_READ_OPS', 'biginteger')
    		->addColumn('FILE_READ_OPS', 'biginteger')
    		->addColumn('FILE_WRITE_OPS', 'biginteger')
    		->addColumn('FINISHED_MAPS', 'biginteger')
    		->addColumn('FINISH_TIME', 'biginteger')
    		->addColumn('GC_TIME_MILLIS', 'biginteger')
    		->addColumn('JOB_PRIORITY', 'string', array('limit' => 255))
    		->addColumn('LAUNCH_TIME', 'biginteger')
    		->addColumn('MAP_INPUT_RECORDS', 'biginteger')
    		->addColumn('MAP_OUTPUT_RECORDS', 'biginteger')
    		->addColumn('MB_MILLIS_MAPS', 'biginteger')
    		->addColumn('MERGED_MAP_OUTPUTS', 'biginteger')
    		->addColumn('MILLIS_MAPS', 'biginteger')
    		->addColumn('OTHER_LOCAL_MAPS', 'biginteger')
    		->addColumn('PHYSICAL_MEMORY_BYTES', 'biginteger')
    		->addColumn('SLOTS_MILLIS_MAPS', 'biginteger')
    		->addColumn('SPILLED_RECORDS', 'biginteger')
    		->addColumn('SPLIT_RAW_BYTES', 'biginteger')
    		->addColumn('SUBMIT_TIME', 'biginteger')
    		->addColumn('TOTAL_LAUNCHED_MAPS', 'biginteger')
    		->addColumn('TOTAL_MAPS', 'biginteger')
    		->addColumn('TOTAL_REDUCES', 'biginteger')
    		->addColumn('USER', 'string', array('limit' => 255))
    		->addColumn('VCORES_MILLIS_MAPS', 'biginteger')
    		->addColumn('VIRTUAL_MEMORY_BYTES', 'biginteger')
    		->addColumn('WASB_BYTES_READ', 'biginteger')
    		->addColumn('WASB_BYTES_WRITTEN', 'biginteger')
    		->addColumn('WASB_LARGE_READ_OPS', 'biginteger')
    		->addColumn('WASB_READ_OPS', 'biginteger')
    		->addColumn('WASB_WRITE_OPS', 'biginteger')
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