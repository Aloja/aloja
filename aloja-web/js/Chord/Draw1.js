/*//////////////////////////////////////////////////////////	
//Introduction
///////////////////////////////////////////////////////////*/
function Draw1(){

	/*First disable click event on clicker button*/
	stopClicker();
		
	/*Show and run the progressBar*/

	changeTopText(newText = "In the next few steps I would like to introduce you the flows of read between every node of the cluster",
	loc = 4/2, delayDisappear = 0, delayAppear = 1,finalText = true);

	changeBottomText(newText = "",
	loc = 0, delayDisappear = 0, delayAppear = 1);	
	
	
	//Remove arcs again
	d3.selectAll(".arc")
		.transition().delay(1500).duration(2100)
		.style("opacity", 0)
		.each("end", function() {d3.selectAll(".arc").remove();});
		
};/*Draw1*/