def parse_args(args)
	options = Hash.new
	
	while args.length > 0
		arg = args.shift
		case arg
		when "-T"
			timestamp_arg = args.shift
			raise BIBIFI::InvalidError.new if timestamp_arg.nil?
			options[:timestamp] = timestamp_arg.to_i
		when "-K"
			token_arg = args.shift
			raise BIBIFI::InvalidError.new if token_arg.nil?
			raise BIBIFI::InvalidError.new if ! token_arg.match(/[a-zA-Z0-9]+/)
			options[:token] = token_arg
		when "-E"
			employee_name_arg = args.shift
			raise BIBIFI::InvalidError.new if employee_name_arg.nil?
			raise BIBIFI::InvalidError.new if ! employee_name_arg.match(/[a-zA-Z]+/)
			options[:employee_name] = employee_name_arg
		when "-G"
			guest_name_arg = args.shift
			raise BIBIFI::InvalidError.new if guest_name_arg.nil?
			raise BIBIFI::InvalidError.new if ! guest_name_arg.match(/[a-zA-Z]+/)
			options[:guest_name] = guest_name_arg
		when "-A"
			options[:arrival] = true
		when "-L"
			options[:departure] = true
		when "-R"
			room_id_arg = args.shift
			raise BIBIFI::InvalidError.new if room_id_arg.nil?
			raise BIBIFI::InvalidError.new if ! room_id_arg.match(/\d+/)
			options[:room_id] = room_id_arg.to_i
		when "-B"
			batch_file_arg = args.shift
			raise BIBIFI::InvalidError.new if batch_file_arg.nil?
			options[:batch_file] = batch_file_arg.to_i
		else # it’s the <log> argument
			raise BIBIFI::InvalidError.new if options[:log_file] # only allow one log to be specified
			options[:log_file] = arg
		end
	end
	
	options
end


def validate_options(options, batch_is_allowed=true)
	incompatible_options = {
		mutually_exclusive: [
			[:arrival, :departure],
			[:employee_name, :guest_name],
		],
		one_incompatible_with_many: [
			[:batch_file, [:timestamp, :token, :employee_name, :guest_name, :arrival, :departure, :room_id]],
		],
	}
	validate_options_against_incompatible_options(options, incompatible_options)
	
	if ! options[:batch_file]
		required_options = [:timestamp, :token]
		options_where_at_least_one_is_required = [
			[:arrival, :departure],
			[:employee_name, :guest_name]
		]
		validate_required_options(options, required_options)
		validate_options_where_at_least_one_is_required(options, options_where_at_least_one_is_required)
	end
	if !batch_is_allowed && options[:batch_file]
		raise BIBIFI::InvalidError.new
	end
end


def delegate_operation_with_options(options)
	if options[:batch_file]
		run_batch_file(options[:batch_file])
	else
		add_event(options)
	end
end

def run_batch_file(batch_file_path)
	line = nil
	while line = gets
		begin
			line = line.chomp
			args = line.split
			options = parse_args(args)
			validate_options(options, false)
			delegate_operation_with_options(options)
		rescue BIBIFI::InvalidError
			$stderr.puts "invalid"
		end
	end
end

def add_event(options)
	log = read_or_initialize_log(options[:log_file], options[:token])
	event = event_from_options(options)
	validate_event_against_log(event, log)
	log.push(event)
	SecureFile.safe_write(options[:log_file], options[:token], log)
end

def read_or_initialize_log(log_file_path, token)
	if File.exists?(log_file_path)
		return SecureFile.safe_read(log_file_path, token)
	else
		return []
	end
end

def event_from_options(options)
	event = Hash.new
	event[:timestamp] = options[:timestamp]
	if options[:arrival]
		event[:type] = :arrival
	elsif options[:departure]
		event[:type] = :departure
	end
	if options[:employee_name]
		event[:person] = {type: :employee, name: options[:employee_name]}
	elsif options[:guest_name]
		event[:person] = {type: :guest, name: options[:guest_name]}
	end
	event[:room_id] = options[:room_id]
	#p event # DEBUG
	return event
end

def validate_event_against_log(event, log)
	# TODO check timestamps
	# TODO check room leaving/entering rules
	# TODO check anything else I need to validate
end


while_printing_errors(false) do
	args = ARGV
	#p args # DEBUG
	options = parse_args(args)
	#p options # DEBUG
	
	validate_options(options)
	delegate_operation_with_options(options)
end
