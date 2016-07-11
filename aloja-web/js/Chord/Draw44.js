/*///////////////////////////////////////////////////////////	
//Show Loyalty hills
//////////////////////////////////////////////////////////*/
function Draw4(){

	/*First disable click event on clicker button*/
	stopClicker();
	/*Show and run the progressBar*/
	
	/*Samsung Loyal text*/
	changeTopText(newText = "The hills shows the local reads performed inside each node",
		loc = 4/2, delayDisappear = 0, delayAppear = 1, finalText = false, xloc=-50, w=300);
	changeTopText(newText = "You can also envision this as a chord beginning and ending on itself",
		loc = 2/2, delayDisappear = 9, delayAppear = 10, finalText = true, xloc=-50, w=300);
	changeBottomText(newText = "",
		loc = 0/2, delayDisappear = 0, delayAppear = 1)	;
	/*Remove the arcs*/
	d3.selectAll(".NokiaToSamsungArc")
		.transition().duration(2000)
		.attr("opacity", 0)
		.each("end", function() {d3.selectAll(".NokiaToSamsungArc").remove();});

	d3.selectAll(".SamsungToNokiaArc")
		.transition().duration(2000)
		.attr("opacity", 0)
		.each("end", function() {d3.selectAll(".SamsungToNokiaArc").remove();});
		
	/*Show only the loyal chords*/
	chords.transition().duration(2000)
		.attr("opacity", function(d, i) { 
			if(d.source.index == 4) {return opacityValueBase;}
			else {return 0;}
		});
	
		
	/*Show all ticks and texts again*/
	/*Ticks*/
	d3.selectAll("g.group").selectAll("line")
		.transition().duration(700)
		.style("stroke", "#000");
	/*Same for the %'s*/
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".tickLabels").style("opacity", 1);
	/*And the Names of each Arc*/	
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".titles").style("opacity", 1);
				
};/*Draw9*/