<?php

require_once('inc/common.php');

try {
    $table_fields = null;
    $exec_rows = get_execs();

    if (count($exec_rows) > 0) {
        $table_fields = generate_table($exec_rows, $show_in_result);
    } else {
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
                "aaSorting": [[ <?=count($show_in_result)?>, "desc" ]],
                "iDisplayLength": 10,
                "sDom": 'C<"clear">lfrtip<"clear"><"clear">T', //"sDom": 'C<"clear">lfrtip',
                "oLanguage": {
                    "sSearch": "Filter all columns:",
                    "sProcessing": "Loading..."
                },
                //"bStateSave": true,
                "aoColumnDefs": [{
                        "bVisible": false, "aTargets": [ 4, <?=count($show_in_result)?> ]
                    }
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

            
            function getCookie(cname) {
      		  var name = cname + "=";
      		  var ca = document.cookie.split(';');
      		  for(var i=0; i<ca.length; i++) {
      		     var c = ca[i].trim();
      		     if (c.indexOf(name) == 0) return c.substring(name.length,c.length);
      		  }
      		  return "";
      		}

            if(getCookie('rememberme') != "true") {
    			document.cookie="rememberme=true";
    		  	$("#welcomeModal").modal({
    				show: true,
    		  		backdrop: 'static'
    			});
    		}
        } );

    </script>

    <?=make_header('HiBench Executions on Hadoop', $message)?>
    <div class="modal fade" id="welcomeModal">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
        <h4 class="modal-title">Welcome to ALOJA</h4>
      </div>
      <div class="modal-body">
        <p>Welcome to ALOJA, a project to explore Hadoop's performance under different Software parameters, Hardware, Cloud or On-Premise, and Job types. This site is a DEMO, and it is under constant development and it is in the process of being documented.
		  For inquiries, feature requests or bug reports please contact us at: <a href="mailto:aloja@bsc.es" target="_top">aloja@bsc.es</a></p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
    <?=make_navigation('HiBench Runs Details')?>
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
                <td><input type="text" id="min" name="min" value="20131211092633"></td>
            </tr>
            <tr>
                <td>Maximum execution date:</td>
                <td><input type="text" id="max" name="max"></td>
            </tr>
            </tbody>
        </table>
    </div>
<!--
    <h1>Legend:</h1>
    <h2>Clusters</h2>
    <table cellspacing="10" cellpadding="2" style="text-align: left; border-collapse: collapse; border: 1px solid #4E6CA3; width: 400px;">
        <tbody>
        <tr>
            <th>Cluster</th>
            <th>Type</th>
            <th>Cost/hr</th>
            <th>Spec</th>
        </tr>
        <tr>
            <td>Local 1</td>
            <td>Colocated</td>
            <td>12 USD</td>
            <td><a href="http://hadoop.bsc.es/?page_id=51">link</a></td>
        </tr>
        <tr>
            <td>Azure Linux</td>
            <td>IaaS Cloud</td>
            <td>7 USD</td>
            <td><a href="http://www.windowsazure.com/en-us/pricing/calculator/">link</a></td>
        </tr>
        <tr>
            <td>Azure HDInsights</td>
            <td>PaaS Cloud</td>
            <td>5 USD</td>
            <td><a href="http://www.windowsazure.com/en-us/pricing/calculator/">link</a></td>
        </tr>
        </tbody>
    </table>
-->

    </br></br>

    <div id="chart"></div>

</div>
<?=$footer?>
