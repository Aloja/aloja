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