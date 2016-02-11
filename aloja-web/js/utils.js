function strpos(haystack, needle, offset) {
	//  discuss at: http://phpjs.org/functions/strpos/
	// original by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
	// improved by: Onno Marsman
	// improved by: Brett Zamir (http://brett-zamir.me)
	// bugfixed by: Daniel Esteban
	//   example 1: strpos('Kevin van Zonneveld', 'e', 5);
	//   returns 1: 14

	var i = (haystack + '').indexOf(needle, (offset || 0));
	return i === -1 ? false : i;
}

function isNumber(n) {
	return !isNaN(parseFloat(n)) && isFinite(n);
}

if (typeof String.prototype.startsWith != 'function') {
	// see below for better implementation!
	String.prototype.startsWith = function (str){
		return this.indexOf(str) === 0;
	};
}

/**
 * Modifies the current url changing the query parameters to the ones present
 * in the passed map
 */
function setUrlQuery(query, extra_parameters_string) {
	var uri = new URI();
	uri.setQuery(query);
	if (typeof extra_parameters_string !== "undefined") {
		uri.setQuery(URI.parseQuery(extra_parameters_string));
	}
	history.replaceState({}, '', uri.toString());
}

function getSelectedBenchsuites() {
	var selBenchSuites = null;
	if($("select[name='bench_type[]']").length > 0)
		selBenchSuites = new Array($("select[name='bench_type[]']").val());
	else {
		selBenchSuites = new Array();
		$("input[name='bench_type[]']").each(function() {
			if($(this).prop('checked'))
				selBenchSuites.push($(this).val());
		});
	}

	return selBenchSuites;
}
function showCorrectBenchDatasizes(benchSizes) {
	var selDatasizes = new Array();
	var selBenchSuites = getSelectedBenchsuites();

	var selBenchs = new Array();
	if($("input[name='bench[]']").length > 0) {
		$("input[name='bench[]']").each(function() {
			if($(this).prop('checked'))
				selBenchs.push($(this).val());
		});

		if(selBenchs.length == 0) {
			$("input[name='bench[]']").each(function() {
				var isVisible = $(this).parent().css('display');
				var value = $(this).val();
				if(isVisible != "none") {
					selBenchs.push(value);
				}
			});
		}
	} else {
		selBenchs.push($("select[name='bench[]']").find(":selected").text());
	}

	$("input[name='datasize[]'").each(function() {
		if($(this).prop('checked'))
			selDatasizes.push($(this).val());
	});

	$("input[name='datasize[]']").each(function() {
		$(this).parent().hide();
		$(this).prop('checked',false);
	});

	$.each(selBenchSuites, function(index, suite) {
		if(benchSizes[suite] != undefined) {
			$.each(selBenchs, function (index2, bench) {
				if(benchSizes[suite][bench] != undefined) {
					$.each(benchSizes[suite][bench], function (index3, datasize) {
						$("input[name='datasize[]'][value='" + datasize + "']").parent().show();
						if(selDatasizes.indexOf(datasize) > -1)
							$("input[name='datasize[]'][value='" + datasize + "']").prop('checked',true);
					});
				}
			});
		}
	});
}

function showCorrectBenchScaleFactors(scaleFactors) {
	var selScaleFactors = new Array();
	var selBenchSuites = getSelectedBenchsuites();
	var selBenchs = new Array();
	if($("input[name='bench[]']").length > 0) {
		$("input[name='bench[]']").each(function() {
			if($(this).prop('checked'))
				selBenchs.push($(this).val());
		});

		if(selBenchs.length == 0) {
			$("input[name='bench[]']").each(function() {
				var isVisible = $(this).parent().css('display');
				var value = $(this).val();
				if(isVisible != "none") {
					selBenchs.push(value);
				}
			});
		}
	} else {
		selBenchs.push($("select[name='bench[]']").find(":selected").text());
	}

	$("input[name='scale_factor[]'").each(function() {
		if($(this).prop('checked'))
			selScaleFactors.push($(this).val());
	});

	$("input[name='scale_factor[]']").each(function() {
		$(this).parent().hide();
		$(this).prop('checked',false);
	});

	$.each(selBenchSuites, function(index, suite) {
		if(scaleFactors[suite] != undefined) {
			$.each(selBenchs, function (index2, bench) {
				if(scaleFactors[suite][bench] != undefined) {
					$.each(scaleFactors[suite][bench], function (index3, scaleFactor) {
						$("input[name='scale_factor[]'][value='" + scaleFactor + "']").parent().show();
						if(selScaleFactors.indexOf(scaleFactor) > -1)
							$("input[name='scale_factor[]'][value='" + scaleFactor + "']").prop('checked',true);
					});
				}
			});
		}
	});
}

function showCorrectBenchs(benchSizes) {
	var availBenchs = new Array();
	var reselect = false;
	var includePrepares = $("input[type='checkbox'][name='prepares']:checked").length > 0;
	var selBenchSuites = getSelectedBenchsuites();
	$.each(selBenchSuites, function(indexSuite, suite) {
		$.each(benchSizes[suite],function(bench, datasizes) {
			if((bench.startsWith("prep_") && includePrepares) || !bench.startsWith("prep_" ))
				availBenchs.push(bench);
		});
	});

	if($("input[name='bench[]']").length > 0) {
		$("input[name='bench[]']").each(function(index,bench) {
			if(availBenchs.indexOf($(this).val()) == -1 ) {
				if($(this).prop('checked')) {
					$(this).prop('checked', false);
					reselect = true;
				}
				$(this).parent().hide();
			} else {
				$(this).parent().show();
			}

			if(reselect)
				$("input[name='bench[]']:visible").first().prop('checked',true);
		});
	} else {
		$("select[name='bench[]'] option").each(function() {
			if(availBenchs.indexOf($(this).val()) == -1) {
				if($(this).prop('selected')) {
					$(this).prop('selected', false);
					reselect = true;
				}
				$(this).hide();
			} else {
				$(this).show();
			}

			if(reselect) {
				$("select[name='bench[]'] option:visible").first().prop('selected',true);
			}
		});
	}
}

function showCorrectClusters(providerClusters) {
	var availClusters = new Array();
	var providersSelected = $("input[name='provider[]']:checked").length;
	if(providersSelected > 0) {
		$("input[name='provider[]']").each(function () {
			if($(this).is(':checked')) {
				$.each(providerClusters[$(this).val()], function (index2, clusterId) {
					availClusters.push(clusterId);
				});
			}
		});

		$("input[name='id_cluster[]']").each(function () {
			if (availClusters.indexOf($(this).val()) == -1) {
				if ($(this).is(':checked'))
					$(this).attr('checked', false);

				$(this).parent().hide();
			} else {
				$(this).parent().show();
			}
		});
	} else {
		$("input[name='id_cluster[]']").each(function () {
			if(!$(this).parent().is(':visible')) {
				$(this).parent().show();
			}
		});
	}
}

function calculateDatasize(value) {
	var nDigits = value.toString().length;
	var retorn = '';
	if(nDigits >= 4) {
		if(nDigits >= 8) {
			if(nDigits >= 10) {
				if(nDigits >= 13) {
					retorn =  Math.ceil((value/1000000000000)).toString() + ' TB';
				} else
					retorn =  Math.ceil((value/1000000000)).toString() + ' GB';
			} else
				retorn = Math.ceil((value/1000000)).toString() + ' MB';
		} else
			retorn = Math.ceil((value/1000)).toString() + ' KB';
	} else
		retorn = value.toString() + ' B';

	return retorn;
}