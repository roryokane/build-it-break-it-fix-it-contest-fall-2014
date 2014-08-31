def parse_args(args)
	options = Hash.new
	
	while args.length > 0
		arg = args.shift
		case arg
		when "-K"
			token_arg = args.shift
			raise BIBIFI::InvalidError.new if token_arg.nil?
			raise BIBIFI::InvalidError.new if ! token_arg.match(/[a-zA-Z0-9]+/)
			options[:token] = token_arg
		when "-H"
			options[:html_output] = true
		when "-S"
			options[:print_state] = true
		when "-R"
			options[:list_rooms] = true
		when "-T"
			options[:print_total_time] = true
		when "-I"
			options[:print_rooms] = true
		when "-A"
			options[:print_employes_within_time] = true
		when "-B"
			options[:print_employes_within_only_first_time] = true
		when "-E"
			employee_name_arg = args.shift
			raise BIBIFI::InvalidError.new if employee_name_arg.nil?
			raise BIBIFI::InvalidError.new if ! employee_name_arg.match(/[a-zA-Z]+/)
			initialize_or_push_to_array_key(options, :employee_names, employee_name_arg)
		when "-G"
			guest_name_arg = args.shift
			raise BIBIFI::InvalidError.new if guest_name_arg.nil?
			raise BIBIFI::InvalidError.new if ! guest_name_arg.match(/[a-zA-Z]+/)
			initialize_or_push_to_array_key(options, :guest_names, guest_name_arg)
		when "-L"
			lower_bound_arg = args.shift
			raise BIBIFI::InvalidError.new if lower_bound_arg.nil?
			raise BIBIFI::InvalidError.new if ! lower_bound_arg.match(/[a-zA-Z]+/)
			initialize_or_push_to_array_key(options, :lower_bound, lower_bound_arg)
		when "-U"
		else # it’s the <log> argument
			raise BIBIFI::InvalidError.new if options[:log_file] # only allow one log to be specified
			options[:log_file] = arg
		end
	end
	
	options
end

def initialize_or_push_to_array_key(hash, key, value_to_add)
	if hash[key] == nil
		hash[key] = [value_to_add]
	else
		hash[key] = hash[key].push(value_to_add)
	end
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
	log_file = options[:log_file]
	token = options[:token]
	log = SecureFile.safe_read(log_file, token)
	
	if options[:print_state]
		print_state(log)
	elsif options[:list_rooms]
		list_rooms(log, options)
	end
end


def print_state(log)
	puts gallery_state_from_all_events(log).to_s
end

def list_rooms(log, options)
	person = begin
		if options[:employee_names].size > 0
			{type: :employee, name: options[:employee_names].first}
		elsif options[:guest_names].size > 0
			{type: :guest, name: options[:guest_names].first}
		else
			raise BIBIFI::InvalidError.new
		end
	end
	state = GalleryState.new
	rooms = []
	
	events.each do |event|
		state.update_state_with_event!(event)
		# TODO
	end
	
	return rooms.sort
end

def gallery_state_from_all_events(events)
	state = GalleryState.new
	events.each do |event|
		state.update_state_with_event!(event)
	end
	state
end


while_printing_errors(true) do
	log_file = ARGV[0]
	token = ARGV[1]
	log = SecureFile.safe_read(log_file, token)
	#pp log # DEBUG
	# to start with, assume -S
	
end
while_printing_errors(false) do
	args = ARGV
	p args # DEBUG
	options = parse_args(args)
	p options # DEBUG
	
	validate_options(options)
	delegate_operation_with_options(options)
end
