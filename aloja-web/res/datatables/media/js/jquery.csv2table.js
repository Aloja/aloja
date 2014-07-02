//@utf-8

(function($) {

	$.csv2table={
		version  : '0.02-b-1.2',
		charset  : 'utf-8',
		doc      : 'http://jsgt.org/mt/01/',
		demo     : 'http://jsgt.org/lib/jquery/plugin/csv2table/v001/test.htm',
		author   : 'Toshiro Takahashi',
		lisence  : 'Public Domain',
		loadImg  : (new Image()).src='./img/icon-loadinfo.gif',
		sortDImg : (new Image()).src='./img/icon-d.gif',
		sortAImg : (new Image()).src='./img/icon-a.gif',
		setting  : [],
		data     : [],
		_rowsAry : [],
		err      : []
	}

	$.fn.csv2table=function (url,setting){

		if(!setting)var setting={};
		var contents=$.fn.csv2table.el=this,id=this[0].id,
		op = $.csv2table.setting[id] = $.extend({
			url                : url,
			nowloadingImg      : $.csv2table.loadImg,              //Image of now loading...
			nowloadingMsg      : 'now loading...',                 //Massege of  now loading...
			removeDoubleQuote  : true,                             // remove " of "hogehoge"
			col_midasi         : '0',                              //
			row_sep            : '\n',                             //Separator of rows. default '\n'
			col_sep            : ',',                              //Separator(,|\t|;) of cols. default ','
			sortable           : true,                             //col sort
			col0color          : true,                             //col[0] color sync jQchart line_strokeStyle
			onload             : null,                             //collback function (id,op,data,ary) {}
			use                : null,                             // 'jqchart:line#canvasID'
			className_div      : 'csv2table-div',                  //className 
			className_table    : 'csv2table-table',                //className 
			className_table_th : 'csv2table-table-th',             //className 
			className_table_td : 'csv2table-table-td',             //className 
			className_sortMark : 'csv2table-sortMark'              //className
		},setting);

		if(op.row_sep=='\n')op.row_sep_reg='\r\n'
		if(op.use){
			op.use_api      = op.use.split(':')[0]
			op.use_api_type = op.use.split('#')[0]
			op.use_api_box  = op.use.split(':')[1].split('#')[1]
		}

		$(contents).before('<div class="csv2table-loading"><img src="'+op.nowloadingImg+'"> '+op.nowloadingMsg+' </div>' )

		$.get(url+"?"+(new Date()).getTime(),"",function(data,textStatus){
			$.csv2table.data[id]=data;
			$(".csv2table-loading").fadeOut();
			$(contents).css("display","none").html(mkTable(id,data));
			setCSS(id);
			$(contents).fadeIn();
			if(op.use_api_type=='jqchart:line')useChart(id,op,data,$.csv2table._rowsAry[id]);
			if($.csv2table.setting[id].onload)
				$.csv2table.setting[id].onload(id,op,data,$.csv2table._rowsAry[id]);
		});

		$.fn.csv2table.wrtTable=function(sortType,colIndex,id){
			$("#"+id).html(mkTable(id,$.csv2table._rowsAry[id],sortType,colIndex));
			setCSS(id);
			if(op.use_api_type=='jqchart:line')useChart(id,op,$.csv2table.data[id],$.csv2table._rowsAry[id]);
			if($.csv2table.setting[id].onload)
				$.csv2table.setting[id].onload(id,op,$.csv2table.data[id],$.csv2table._rowsAry[id]);
		}
		

		function mkTable(id,data,sortType,colIndex){

			var rowsAry=null;
			
			if(sortType){
				$.csv2table._rowsAry[id].head=$.csv2table._rowsAry[id].slice(0,op.col_midasi+1) 
				rowsAry=$.csv2table._rowsAry[id].slice(op.col_midasi+1,$.csv2table._rowsAry[id].length) 
				rowsAry=sortwk(rowsAry,sortType,colIndex);
				rowsAry=$.csv2table._rowsAry[id]=$.csv2table._rowsAry[id].head.concat(rowsAry)
			} else {
				if(op.col_sep==','){
					rowsAry=$.csv2table._rowsAry[id]=escapeStrComma(op.col_sep,op.row_sep,data,op.removeDoubleQuote);
					
				} else {
					rowsAry=$.csv2table._rowsAry[id]=mkArray(data,op.col_sep,op.row_sep);
				}
			}

			if(!rowsAry)return 
			var rowlen=rowsAry.length
			
			var tdClass                             ; 
			var row = rowsAry.length                ; 
			var col = rowsAry[0].length             ;  
			
			htm="";

			//見出し行の処理
			htm+= "<tr>";
			for (k=0; k<col; k++) {
				htm+= "<th>"
				   + rowsAry[op.col_midasi][k];
				if(op.sortable){
					htm+="<br><a href='javascript:$.fn.csv2table.wrtTable(\"sortD\","+k+",\""+id+"\")'>"
					   + "<img src='"+$.csv2table.sortDImg+"' border='0'>"
					   + "</a><a href='javascript:$.fn.csv2table.wrtTable(\"sortA\","+k+",\""+id+"\")'>"
					   + "<img src='"+$.csv2table.sortAImg+"' border='0'></a>"
				}
				htm+= "</th>";
			}
			htm+= "</tr>";
				
			//data行の処理
			for (i=eval(op.col_midasi+1); i<row; i++) {
				htm+= "<tr>";
				//列の処理
				for (j=0; j<col; j++) {
					htm+= "<td>"
					   + rowsAry[i][j]
					   + "</td>";
				}
				htm+= "</tr>";
			}

			var tableHtm=document.getElementById(id)
				.innerHTML="<table id='csv'>"+htm+"</table>";
	 
				
			
			if(op.sortable)
			$("th",tableHtm)
						.css('font-size','7px')
						.css('font-size','9px')
						.css('font-family','Arial')
						.css('text-decoration','none')
						.css('color','#888')
						.addClass(op.className_sortMark)

			return tableHtm;
		}
		
		////
		// 並べ替え
		// @parame dataAry    並べ替え対象配列
		// @parame sortType   昇順sortA|降順sortD
		// @parame colIndex   ソート列
		//
		function sortwk(dataAry,sortType,colIndex){
			var i=colIndex;
			if(!dataAry)return ;
			if(isNaN(dataAry[0][i])){
				dataAry.sort(
					function(a,b){
	
						if(!a[i]) { 
							if(!b[i])return 0;
							else     return 1;
						} else if(!b[i]) {
							return -1;
						}
						
						if(""+a[i] === ""+b[i])return 0;
						return (sortType=="sortD")?
							((""+a[i] > ""+b[i])?-1:1):
							((""+a[i] > ""+b[i])?1:-1);
					}
				)

			} else {
				(sortType=="sortD")?
				dataAry.sort(function (a,b){ 
						return (b[i] - a[i]) ;//降順 
				}):
				dataAry.sort(function (a,b){ 
						return (a[i] - b[i]);// 昇順
				})
			}
			return dataAry;
		}
		
		function escapeStrComma(col_sep,row_sep,oj,removeDoubleQuote){
			var rdq=(removeDoubleQuote)?'':'"';

			//mk dmy for comma in "
			var dmy =['-###','###-'],cnt=0,r;
			cnt=(function mkdmy(cnt){
				if(!(
					oj.indexOf((dmy[0]+'comma'+cnt+dmy[1]))==-1 ||
					oj.indexOf((dmy[0]+'rn'+cnt+dmy[1]))==-1 ||
					oj.indexOf((dmy[0]+'wDquote'+cnt+dmy[1]))==-1 
				))mkdmy( ++cnt )
				else void(0)
				return cnt;
			})(cnt)

			var reg='(["](.|(\r\n))*?(["]$|["][,('+op.row_sep_reg+')]))',
				dmystr_comma=''+(dmy[0]+'comma'+cnt+dmy[1]) ,
				dmystr_rn=''+(dmy[0]+'rn'+cnt+dmy[1]) ,
				dmystr_wDquote=''+(dmy[0]+'wDquote'+cnt+dmy[1]) ;

			escape= oj.replace('""',dmystr_wDquote);
			escape= escape.replace(
				new RegExp(reg,"g"),
				function (after,before,index) {
					after= after
							.replace(/(\r\n)(?!$)/g,dmystr_rn)
							.replace(/,(?!$)/g,dmystr_comma)
					return after
					
				}
			)

			r=$.csv2table._rowsAry[id]=mkArray(escape,op.col_sep,op.row_sep);

			var b=[],rowlen=r.length,collen=r[0].length;
			for(var i=0;i<rowlen;i++){
				if(r[i]=='')continue; 
				b[i]=r[i];
				for(var j=0;j<collen;j++){
					try{
						b[i][j]=$.trim(r[i][j])
							.replace(/^"|"$/g,rdq)
							.replace(new RegExp(dmystr_comma,"g"),",")
							.replace(new RegExp(dmystr_rn,"g"),"\r\n")
							.replace(new RegExp(dmystr_wDquote,'g'),'""');
					} catch(e){}
				}
			}
			
			return b
		}
		
		function mkArray(data,col_sep,row_sep){
				var rows=data.split(row_sep),rc=[]
				    rowlen=rows.length ;
				for(var i=0;i<rowlen;i++){
					if($.trim(rows[i])=='') continue; 
					try{
						rc[i]=rows[i].split(col_sep);
					} catch(e){ }
				}
				return rc
		}

		function setDefault(settingName,val){
			var prop = (setting[settingName]=='undefined'||
				 setting[settingName]==null)?val:setting[settingName]
			return prop
		}

		function setCSS(id){
			$('#'+id+'').css({
				/*backgroundColor  : '#eee',
				border           : '1px solid #555',*/
				padding          : '0px', 
				margin           : '1px'
			}).addClass(op.className_div)
			
			$('#'+id+' table').css({
				borderCollapse   : 'collapse',
				borderSpacing    : '0px',
				marginBottom     : '10px'
			}).addClass(op.className_table)
			
			$('#'+id+' table th').css({
				borderColor      : '#eee #999 #777 #bbb',
				borderStyle      : 'solid',
				borderWidth      : '1px',
				backgroundColor  : '#ccc', 
				fontSize         : '12px',
				padding          : '4px',
				textAlign       : 'center'

			}).addClass(op.className_table_th)
			
			$('#'+id+' table td').css({
				borderColor      : '#eee #aaa #999 #ccc',
				borderStyle      : 'solid',
				borderWidth      : '1px',
				padding          : '8px',
				fontSize         : '12px'
			}).addClass(op.className_table_td)
			
			
		}
		
		function useChart (id,op,data,ary){
			var head= ary[0],dataBody=ary.slice(1) ;
			$("#"+op.use_api_box).jQchart({
				config : $.extend(op,{ 
					width    : $('#'+id+' table').width()+10,
					paddingL : $('#'+id+' table th:nth-child(1)').width()+14,
					onload   :null
				}),
				data : (function(){
					var d = [];
					for(var i=0,len=dataBody.length;i<len;i++){
						d.push(dataBody[i].slice(1))
					}
					return d;
				})()
			})

			var dl= dataBody.length,lc=$("#"+op.use_api_box).jQchart.op.line_strokeStyle;
			$('tr:even','#'+id).css('background','#eee');
			if(op.col0color)
			$.each(dataBody,function(i){
				$('tr:nth-child('+dl+'n'+(dl+i+2)%dl+') td:first','#'+id)
					.css('color',lc[i]) 
			})
		}
	}


})(jQuery);