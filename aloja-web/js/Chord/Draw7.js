/*//////////////////////////////////////////////////////////
//Final wrap up
//////////////////////////////////////////////////////////*/
function Draw7(){

	/*First disable click event on clicker button*/
	stopClicker();

	changeTopText(newText = "After this few examples, the final diagram is ready to be understood, good luck!",
		loc = 8/2, delayDisappear = 0, delayAppear = 1, finalText = true);
		
	changeBottomText(newText = "",
		loc = 3/2, delayDisappear = 0, delayAppear = 1);		
	
	/*Only show the chords of NameNode*/
	chords.transition().duration(1000)
		.style("opacity", 0.1);

	/*Hide all the text*/
	d3.selectAll("g.group").selectAll("line")
		.transition().duration(700)
		.style("stroke","#DBDBDB");
	/*Same for the %'s*/
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".tickLabels").style("opacity",0.4);
	/*And the Names of each Arc*/	
	svg.selectAll("g.group")
		.transition().duration(700)
		.selectAll(".titles").style("opacity",0.4);	
		
};/*Draw14*/