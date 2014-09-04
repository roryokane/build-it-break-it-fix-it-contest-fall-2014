# TODO put the below in a module for organization
def validate_options_against_incompatible_options(options, incompatible_options)
	incompatible_options[:mutually_exclusive].each do |mut_ex_options|
		option_values = mut_ex_options.map do |option|
			options[option]
		end
		if count_truthy(option_values) > 1
			raise BIBIFI::InvalidError.new
		end
	end
	incompatible_options[:one_incompatible_with_many].each do |one, many|
		if options[one]
			many.each do |option|
				if options[option]
					raise BIBIFI::InvalidError.new
				end
			end
		end
	end
end

def validate_required_options(options, required_options)
	required_options.each do |option|
		if ! options[option]
			raise BIBIFI::InvalidError.new
		end
	end
end

def validate_options_where_at_least_one_is_required(options, options_where_at_least_one_is_required)
	options_where_at_least_one_is_required.each do |option_set|
		option_values = option_set.map do |option|
			options[option]
		end
		num_options_used = count_truthy(option_values)
		if num_options_used == 0
			raise BIBIFI::InvalidError.new
		end
	end
end

def count_truthy(array)
	array.map do |value|
		(!! value) ? 1 : 0
	end.reduce(0, &:+)
end
