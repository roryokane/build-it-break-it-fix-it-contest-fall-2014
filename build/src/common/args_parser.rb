class ArgsParser
	
end

class LogAppendArgsParser
	def initialize(allow_batch)
		parser = ArgsParser.new
		parser.foo
	end
end
class LogReadArgsParser
	def initialize
		
	end
end


if false
	# demo of usage of my planned module
	NAME_REGEX = /a-zA-Z0-9/
	
	# arguments shared between many
	employee_argument = ArgumentFlag.new('E', :employee_name, validation_regex: NAME_REGEX)
	guest_argument = ArgumentFlag.new('G', :guest_name, validation_regex: name_regex)
	person_argument = AlternativeArgs.new(:name, [employee_argument, guest_argument])
	token_argument = ArgumentFlag.new('K', :token)
	html_argument = OptionalArgs.new(:html_format, SimpleFlag.new('H', :html_format))
	
	options_parser.add_argument_list(
		token_argument,
		html_argument,
		SimpleFlag.new('R', :list_rooms),
		person_argument,
		PlainArg.new(:log)
	) do |token, html_format, list_rooms, name, log|
		# which is better – these arguments or an options hash? arguments are convenient, but make it hard to deak with optional (-H) and ignorable (-R) flags.
		if html_format
			
		else
			
		end
	end
	

	# start of implementation – for the idea, at least
	class ArgumentFlag
		attr_reader :flag_name
		
		# do I need full_name? what is it used for? The key in the returned options hash? printing a debug representation?
		def initialize(flag_name, full_name=nil, validation_regex: nil)
			if full_name.nil?
				full_name = flag_name.to_sym
			end
			@flag_name = flag_name
		end
		
		# returns the number of arguments used
		def try_parse_using_some_arguments(remaining_arguments)
			return nil if remaining_arguments.size < 2
			return nil unless remaining_arguments[0] == flag_argument
			
			return 2
		end
		
		private
		
		def flag_argument
			"-" + @flag_name
		end
	end
	
	class ArgumentParser
		def initialize(patterns)
			
		end
		
		def parse_arguments(arguments)
			# FIXME this is re-implementing a parser. I could just re-join the arguments with spaces and then parse that text with Parslet. It would be able to distinguish the different argument sets using alternation.
			# The only problems is that Parslet is an external library. Is there a good-enough alternative in the standard library, or a short Gist equivalent I can copy? Maybe a simple-to-implement recursive-descent parser is good enough?
			# A https://en.wikipedia.org/wiki/Recursive_descent_parser would only work for algorithms that require no or limited backtracking. This program requires no backtracking, so it would work.
			possible_patterns = @patterns.dup
			until arguments.size == 0
				arg = arguments.shift
				# test arg against all possible_patterns
				# provide the patterns with all the arguments they need
				# remove patterns that said they don’t match
			end
			# at this point, hopefully exactly one pattern matched.
			# If more than one matched, the input was ambiguous – programmer’s fault. Maybe throw error or choose the first pattern.
			# If none matched, the arguments were invalid. `raise BIBIFI::InvalidError.new`
		end
	end
end


# (old version; not sure if I want to do it the same way)
if false # still in development
	def abstracted_parse_args(args_info)
		options = Hash.new
		
		while args.length > 0
			arg = args.shift
			
			handler = args_info[arg][:handler]
			handler.call(args)
			
			case arg
			when "-T"
				timestamp_arg = args.shift
				raise BIBIFI::InvalidError.new if timestamp_arg.nil?
				options[:timestamp] = timestamp_arg.to_i
			else # it’s the <log> argument
				raise BIBIFI::InvalidError.new if options[:log_file] # only allow one log to be specified
				options[:log_file] = arg
			end
		end
		
		options
	end
	
	args_info = Hash.new do |hash, key|
		# default arg handler
		
	end.merge({
		"-T" => {
			takes_arg: true,
			handler: lambda do
				timestamp_arg = args.shift
				raise BIBIFI::InvalidError.new if timestamp_arg.nil?
				options[:timestamp] = timestamp_arg.to_i
			end,
		},
	})
	abstracted_parse_args(args_info)
end
