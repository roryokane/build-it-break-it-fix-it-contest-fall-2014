def while_printing_errors(debug=false)
	if debug
		return yield
	end
	begin
		yield
	rescue BIBIFI::InvalidError
		$stderr.puts "invalid"
		exit(-1)
	rescue BIBIFI::SecurityError
		$stderr.puts "security error"
		exit(-1)
	rescue BIBIFI::IntegrityViolationError
		$stderr.puts "integrity violation"
		exit(-1)
	rescue StandardError # in case of bugs or bad input
		$stderr.puts "invalid"
		exit(-1)
	end
end
