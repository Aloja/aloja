casper.test.begin("Datatable tests", function(test) {
	casper.on('remote.message', function(msg) {
		this.echo(msg);
	});

	casper.start('http://localhost:8080/benchexecs?pageTab=DETAIL', function() {
		test.assertExists("table#benchmarks", "Datatable created");
		test.assertEval(function() {
			return $("#benchmarks td").length > 1;
		}, 'Datatable has content');
		test.assertEval(
				function() {
					return $("tr:nth-child(2) th").children('select').eq(1)
							.val() == '';
				}, 'Network filter field exists');
		test.assertEval(
				function() {
					return $('select[name="benchmarks_length"]').val() != null;
				}, 'Number of entries per page filter exists'
		);
		this.evaluate(function() {
			$('select[name="benchmarks_length"]').val(-1).change();
		});
	});
	
	casper.then(function() {
		this.evaluate(function() {
			$("tr:nth-child(2) th").children('select').eq(1).val('ETH').change();
		});
	});

	casper.then(function() {
		test.assertEval(function() {
			var isOk = true;
			$("tbody tr td:nth-child(6)").each(function() {
				var text = $(this).text();
				if (text.substr(0,3) != "ETH")
					isOk = false;
			});
			return isOk;
		}, 'All networks are ETH after filtering out the others');

		this.evaluate(function() {
			$("tr:nth-child(2) th").children('select').eq(1).val('').change();
		});
	});

	casper.then(function() {
		test.assertEval(function() {
			var isOk = false;
			$("tbody tr td:nth-child(6)").each(function() {
				var text = $(this).text();
				if (text.substring(0,2) == "IB")
					isOk = true;
			});
			return isOk;
		}, 'There is an IB network after restoring filters');

		test.assertEval(function() {
			return $("#benchmarks_filter input") != null;
		}, 'Global filter input exists');

		this.evaluate(function() {
			$("#benchmarks_filter input").val('IB').keyup();
		});
	});

	casper.then(function() {
		test.assertEval(function() {
			var isOk = true;
			$("tbody tr td:nth-child(6)").each(function() {
				var text = $(this).text();
				if (text.substring(0, 2) != 'IB')
					isOk = false;
			});
			return isOk;
		}, 'All networks are IB after using global filter with IB text');
	});

	casper.run(function() {
		test.done();
	});
});
