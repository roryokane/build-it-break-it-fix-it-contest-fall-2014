module LogAppending
	def append_to_log!(event, log)
		check_that_event_is_after_last_logged_event(event, log)
	end

	def check_that_event_is_after_last_logged_event(event, log)
		if log.size > 0
			last_logged_event = log.last
			last_logged_time = last_logged_event[:timestamp]
			event_time = event[:timestamp]
			if event_time < last_logged_time
				raise InvalidError.new
			end
		end
	end
end
