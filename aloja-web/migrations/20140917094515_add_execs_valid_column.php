<?php

use Phinx\Migration\AbstractMigration;

class AddExecsValidColumn extends AbstractMigration
{
    
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
    	$execsTable = $this->table('execs');
    	$execsTable->addColumn('valid','boolean',array('default' => true))
    		->update();
    	$this->execute("UPDATE execs SET valid = 0 WHERE exe_time < 200;");
    }
}