require 'stringio'
class GalleryState
	def initialize
		@employee_locations = Hash.new
		@guest_locations = Hash.new
	end
	
	def employees
		@employee_locations.keys
	end
	
	def guests
		@guest_locations.keys
	end
	
	def person_locations
		@employee_locations.each do |employee_name, room_id|
			# TODO
		end
	end
	
	def people_by_location
		people_by_location = Hash.new { Array.new }
		@employee_locations.each do |employee_name, room_id|
			employee = {type: :employee, name: employee_name}
			people_by_location[room_id] += [employee]
		end
		@guest_locations.each do |guest_name, room_id|
			guest = {type: :guest, name: guest_name}
			people_by_location[room_id] += [guest]
		end
		people_by_location
	end
	
	def people_in_room(room_id)
		people_by_location[room_id]
	end
	
	def people_in_room_by_type(room_id)
		people = people_in_room(room_id)
		employees_by_type, guests_by_type = people.partition do |person, room_num|
			person[:type] == :employee
		end
		employee_names_by_type = employees_by_type.map do |person, room_num|
			[person[:name], room_num]
		end.to_h
		guest_names_by_type = guests_by_type.map do |person, room_num|
			[person[:name], room_num]
		end.to_h
		return {employee: employee_names_by_type, guest: guest_names_by_type}
	end
	
	def update_state_with_event!(event)
		room_id = event[:room_id]
		person = event[:person]
		
		locations_hashes_by_person_type = {
			:employee => @employee_locations,
			:guest => @guest_locations,
		}
		appropriate_locations_hash = locations_hashes_by_person_type[person[:type]]
		
		case event[:type]
		when :arrival
			# TODO check that this event is valid
			appropriate_locations_hash[person[:name]] = room_id
		when :departure
			person = event[:person]
			# TODO check that this event is valid
			if room_id == nil
				appropriate_locations_hash.delete(person[:name])
			else
				appropriate_locations_hash[person[:name]] = nil
			end
		end
	end
	
	def to_s
		StringIO.open('', 'w') do |string_io|
			string_io.puts(employees.sort)
			string_io.puts(guests.sort)
			people_by_location.sort_by do |location, people|
				location.nil? ? -1 : location
			end.each do |location, people|
				if location != nil && people.size > 0
					people_string = people.map{|person|person[:name]}.sort.join(",")
					string_io.puts(location.to_s + ":" + people_string)
				end
			end
			return string_io.string
		end
	end
	
	def to_html
		
	end
end
