<?php

use Phinx\Migration\AbstractMigration;

class CreateTableJobDbscan extends AbstractMigration
{
    /**
     * Change Method.
     *
     * More information on this method is available here:
     * http://docs.phinx.org/en/latest/migrations.html#the-change-method
     *
     * Uncomment this method if you would like to use it.
     *
    */
    public function change()
    {
        $table = $this->table('JOB_dbscan');
        $table
            ->addColumn('bench', 'string', array('limit' => 255))
            ->addColumn('job_offset', 'string', array('limit' => 255))
            ->addColumn('metric_x', 'integer', array('limit' => 11))
            ->addColumn('metric_y', 'integer', array('limit' => 11))
            ->addColumn('id_exec', 'integer', array('limit' => 11))
            ->addColumn('centroid_x', 'decimal', array('precision' => 20, 'scale' => 3))
            ->addColumn('centroid_y', 'decimal', array('precision' => 20, 'scale' => 3))
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