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
	puts gallery_state_from_all_events(log).to_s
end
