<?php

use Phinx\Migration\AbstractMigration;

class RackspaceDataUpdates extends AbstractMigration
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
    	$this->execute("update execs SET disk='RR1' where disk='R1';
						update execs SET disk='RR2' where disk='R2';
						update execs SET disk='RR3' where disk='R3';
						update execs SET bench_type='HiBench' where bench_type='b';
						update execs SET bench_type='HiBench' where bench_type='';
						update execs SET bench_type='HiBench-min' where bench_type='-min';
						update execs SET bench_type='HiBench-10' where bench_type='-10';
						update execs SET bench_type='HiBench-1TB' where bench IN ('prep_terasort', 'terasort') and start_time between '2014-12-02' AND '2014-12-17 12:00';");
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
    	$this->execute("update execs SET disk='R1' where disk='RR1';
						update execs SET disk='R2' where disk='RR2';
						update execs SET disk='R3' where disk='RR3';
						update execs SET bench_type='b' where bench_type='HiBench';
						update execs SET bench_type='-min' where bench_type='HiBench-min';
						update execs SET bench_type='-10' where bench_type='HiBench-10';");
    }
}