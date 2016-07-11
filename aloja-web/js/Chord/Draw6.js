/*//////////////////////////////////////////////////////////
//Show all chords that are connected to Apple
//////////////////////////////////////////////////////////*/
function Draw6(){

	/*First disable click event on clicker button*/
	stopClicker();
		
	changeTopText(newText = "This chord represents the lectures between two nodes",
		loc = 3/2, delayDisappear = 0, delayAppear = 1, finalText = false, xloc=-80, w=200);
	changeTopText(newText = "The area that touches the arc of the node represents how much data it has read from the other node",
		loc = 3/2, delayDisappear = 8, delayAppear = 9, finalText = false, xloc=-80, w=200);
	changeTopText(newText = "A wider area in one of the nodes represents it has read more data than the other one",
		loc = 3/2, delayDisappear = 16, delayAppear = 17, finalText = false, xloc=-80, w=200);
	changeTopText(newText = "Therefore, the chord is the color of the node that has read more data",
		loc = 3/2, delayDisappear = 24, delayAppear = 25, finalText = true, xloc=-80, w=200);

	d3.selectAll(".NokiaLoyalArc")
		.transition().duration(1000)
		.attr("opacity", 0)
		.each("end", function() {d3.selectAll(".NokiaLoyalArc").remove();});
			
	/*Only show the chords of the NameNode*/
	chords.transition().duration(2000)
    .attr("opacity", function(d, i) { 
		if(d.source.index == 0 && d.target.index == 2) {return opacityValueBase;}
		else if (d.source.index == 2 && d.target.index == 0) {return opacityValueBase;}
		else {return 0;}
	});

	/*Highlight arc of NameNode*/
	svg.selectAll("g.group").select("path")
		.transition().duration(2000)
		.style("opacity", function(d) {
			if(d.index != 0) {return opacityValue;}
		});	
		
	/*Show only the ticks and text at Apple*/
	/*Make the other strokes less visible*/
	d3.selectAll("g.group").selectAll("line")
		.transition().duration(700)
		.style("stroke",function(d,i,j) {if (j == 0) {return "#000";} else {return "#DBDBDB";}});
	/*Same for the %'s*/
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".tickLabels").style("opacity",function(d,i,j) {if (j == 0) {return 1;} else {return opacityValue;}});
	/*And the Names of each Arc*/	
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".titles").style("opacity", function(d) { if(d.index == 0) {return 1;} else {return opacityValue;}});

};/*Draw11*/