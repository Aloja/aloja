<?php

use Phinx\Migration\AbstractMigration;

class AddColumnTaskTypeToTableJobDbscan extends AbstractMigration
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
            ->addColumn('TASK_TYPE', 'string', array('limit' => 128, 'null' => true, 'after' => 'metric_y'))
            ->update();
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