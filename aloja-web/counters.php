<?php

require_once('inc/common.php');

try {

    $message = null;

    //check the URL
    $execs = get_GET_execs();

    if (get_GET_string('type')) {
        $type = get_GET_string('type');
    } else {
        $type = 'SUMMARY';
    }

    $join = "JOIN execs e using (id_exec) WHERE JOBNAME NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links')".
        ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':''). " LIMIT 10000";

    if ($type == 'SUMMARY') {
        $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                  c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES
                  FROM JOB_details c $join";
    } elseif  ($type == 'MAP') {
        $query = "SELECT e.bench, exe_time, c.id_exec, JOBID, JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                  c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, `Launched map tasks`,
                    `Data-local map tasks`,
                    `Rack-local map tasks`,
                    `Spilled Records`,
                    `Map input records`,
                    `Map output records`,
                    `Map input bytes`,
                    `Map output bytes`,
                    `Map output materialized bytes`
                  FROM JOB_details c $join";
    } elseif  ($type == 'REDUCE') {
        $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                  c.FINISH_TIME, c.TOTAL_REDUCES, c.FAILED_REDUCES,
                    `Launched reduce tasks`,
                    `Reduce input groups`,
                    `Reduce input records`,
                    `Reduce output records`,
                    `Reduce shuffle bytes`,
                    `Combine input records`,
                    `Combine output records`
                  FROM JOB_details c $join";
    } elseif  ($type == 'FILE-IO') {
        $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                  c.FINISH_TIME,
                    `SLOTS_MILLIS_MAPS`,
                    `SLOTS_MILLIS_REDUCES`,
                    `SPLIT_RAW_BYTES`,
                    `FILE_BYTES_WRITTEN`,
                    `FILE_BYTES_READ`,
                    `HDFS_BYTES_WRITTEN`,
                    `HDFS_BYTES_READ`,
                    `Bytes Read`,
                    `Bytes Written`
                  FROM JOB_details c $join";
    } elseif  ($type == 'DETAIL') {
        $query = "SELECT e.bench, exe_time, c.* FROM JOB_details c $join";
    } elseif  ($type == 'TASKS') {
        $query = "SELECT e.bench, exe_time, j.JOBNAME, c.* FROM JOB_tasks c
                  JOIN JOB_details j USING(id_exec, JOBID) $join ";
    } else {
        throw new Exception('Unknown type!');
    }

    $exec_rows = get_rows($query);

    if (count($exec_rows) > 0) {

        $show_in_result_counters = array(
            'id_exec'   => 'ID',
            //'job_name'  => 'Job Name',
            //'exe_time' => 'Total Time',

            'JOBID'     => 'JOBID',
            'bench'     => 'Bench',
            'JOBNAME'   => 'JOBNAME',
        );

        $show_in_result_counters = generate_show($show_in_result_counters, $exec_rows, 4);
        $table_fields = generate_table($exec_rows, $show_in_result_counters, 0, 'COUNTER');

        if (count($exec_rows) > 10000) {
            $message .= 'WARNING, large resulset, please limit the query! Rows: '.count($exec_rows);
        }

    } else {
        $table_fields = '<tr><td>NO DATA</td></tr>';
        throw new Exception("No results for query!");
    }

} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
}

?>

<?=make_HTML_header()?>
<?=include_datatables()?>

    <script type="text/javascript" charset="utf-8">
        //parse querystring
        $.urlParam = function(name){
            var results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
            if (!results) {
                return "";
            }
            return decodeURIComponent(results[1]) || "";
        }

        /* Custom filtering function which will filter data in column four between two values */
        $.fn.dataTableExt.afnFiltering.push(
            function( oSettings, aData, iDataIndex ) {
                var iMin = document.getElementById('min').value * 1;
                var iMax = document.getElementById('max').value * 1;
                var iVersion = aData[<?=(count($show_in_result))?>] == "-" ? 0 : aData[<?=(count($show_in_result))?>]*1;
                if ( iMin == "" && iMax == "" )
                {
                    return true;
                }
                else if ( iMin == "" && iVersion < iMax )
                {
                    return true;
                }
                else if ( iMin < iVersion && "" == iMax )
                {
                    return true;
                }
                else if ( iMin < iVersion && iVersion < iMax )
                {
                    return true;
                }
                return false;
            }
        );

        function fnResetAllFilters() {
            var oSettings = oTable.fnSettings();
            for(iCol = 0; iCol < oSettings.aoPreSearchCols.length; iCol++) {
                oSettings.aoPreSearchCols[ iCol ].sSearch = '';
            }
            oTable.fnDraw();
        }

        //create the table after loading
        $(document).ready(function() {

            var asInitVals = new Array();
            var oTable;

            /* Add the events etc before DataTables hides a column */
            $("thead input").keyup( function () {
                /* Filter on the column (the index) of this element */
                oTable.fnFilter( this.value, oTable.oApi._fnVisibleToColumnIndex(
                    oTable.fnSettings(), $("thead input").index(this) ) );
            } );

            /*
             * Support functions to provide a little bit of 'user friendlyness' to the textboxes
             */
            $("thead input").each( function (i) {
                this.initVal = this.value;
            } );

            $("thead input").focus( function () {
                if ( this.className == "search_init" )
                {
                    this.className = "";
                    this.value = "";
                }
            } );

            $("thead input").blur( function (i) {
                if ( this.value == "" )
                {
                    this.className = "search_init";
                    this.value = this.initVal;
                }
            } );

            //$('#dynamic').html( '<table cellpadding="0" cellspacing="0" border="0" class="display" id="hibench"></table>' );
            oTable = $('#benchmarks').dataTable( {
                "oSearch": {"sSearch": $.urlParam('search')},
                "bDeferRender": true,
                "aaSorting": [[ 1, "desc" ]],
                "iDisplayLength": 25,
                "sDom": 'C<"clear">lfrtip<"clear"><"clear">T', //"sDom": 'C<"clear">lfrtip',
                "oLanguage": {
                    "sSearch": "Filter all columns:",
                    "sProcessing": "Loading..."
                },
                //"bStateSave": true,
                "aoColumnDefs": [
                    //{"bVisible": false, "aTargets": [ 3 ] }
                ],
                "bSortCellsTop": true,
                "oColVis": {
                    "aiExclude": [0],
                    "bRestore": true
                },
                "sPaginationType": "full_numbers",
                "oTableTools": {
                    "sSwfPath": "../datatables/datatables/media/swf/copy_csv_xls_pdf.swf"
                },
                "aLengthMenu": [
                    [10, 25, 50, 100, 200, -1],
                    [10, 25, 50, 100, 200, "All"]
                ],
                "fnInitComplete": function(oSettings, json) {
                    $('#benchmarks').show();
                    $('#loading').hide();
                }

            } );

            /* Add event listeners to the two range filtering inputs */
            $('#min').keyup( function() { oTable.fnDraw(); } );
            $('#max').keyup( function() { oTable.fnDraw(); } );

        } );

    </script>

    <?=make_header('HiBench Executions on Hadoop', $message)?>
    <?=make_navigation('Hadoop Job Counters')?>

    <div id="navigation" style="text-align: center;">
        <h2>
            <strong>JOB COUNTER TYPES:</strong>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'SUMMARY'))?>"><?=($type == 'SUMMARY' ? '<strong>SUMMARY</strong>':'SUMMARY')?></a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'MAP'))?>"><?=($type == 'MAP' ? '<strong>MAP</strong>':'MAP')?></a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'REDUCE'))?>"><?=($type == 'REDUCE' ? '<strong>REDUCE</strong>':'REDUCE')?></a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'FILE-IO'))?>"><?=($type == 'FILE-IO' ? '<strong>FILE/IO</strong>':'FILE/IO')?></a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'DETAIL'))?>"><?=($type == 'DETAIL' ? '<strong>DETAIL</strong>':'DETAIL')?></a>
            <?php if ($execs) {?>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<?=modify_url(array('type'=>'TASKS'))?>"><?=($type == 'TASKS' ? '<strong>JOB/S TASKS</strong>':'JOB/S TASKS')?></a>
            <?php } ?>
        </h2>
    </div>
    Click on a <strong>Job Name</strong> to see it's tasks and history </br>
    <?=make_datatables_help()?>
    <form action="charts1.php" target="_blank">
        <?php
        $style_table = '';
        if (!$message) {
            echo make_loading();
            $style_table = 'style="display: none;"';
        }
        ?>
        <table id="benchmarks" cellpadding="0" cellspacing="0" border="0" class="display" width="100%" <?=$style_table?>>
            <?=$table_fields?>
        </table>

        <h1>Compare executions:</h1>
        <h2>Select rows by clicking on checkboxes and click: <input type="submit" value="Compare Executions"></h2>

    </form>


    <div style="display: none;">
        <h1>Advanced filtering:</h1>
        <h2>Remove old executions by default, clear to enable all:</h2>
        <table border="0" cellspacing="0" cellpadding="1" style="">
            <tbody>
            <tr>
                <td>Minimum execution date:</td>
                <td><input type="text" id="min" name="min"></td>
            </tr>
            <tr>
                <td>Maximum execution date:</td>
                <td><input type="text" id="max" name="max"></td>
            </tr>
            </tbody>
        </table>
    </div>

    </br></br>

    <div id="chart"></div>

</div>
<?=$footer?>
