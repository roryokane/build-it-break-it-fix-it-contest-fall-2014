#!/usr/bin/env ruby

require 'openssl'
require 'stringio'
require 'pp'

# Hello breakers! Lucky you, I wrote this program in Ruby to save on developer time. Thus, you get to read my source code to look for flaws.
# Of course, I have accounted for that, and written the program such that that shouldn’t make a difference. I have included no private keys or secret algorithms in here. I invite you to prove me wrong.

module SecureFile
	KEY_STRETCHING_SALT = "Rory’s custom salt"
	
	# I use Marshal over JSON for the slight security through obscurity factor, to slow down breakers.
	# It is possible to inject code using Marshal, but it’s pretty easy to inject code into a local Ruby script anyway.
	
	def self.safe_write(file_path, password, data_object)
		key = key_from_password(password)
		iv = random_iv
		
		data_string = serialize_to_string(data_object)
		data_checksum = checksum(data_string)
		data_to_encrypt = serialize_to_string([data_checksum, data_string])
		cipher_text = encrypt(data_to_encrypt, key, iv)
		
		data_to_write = serialize_to_string([iv, cipher_text])
		File.write(file_path, data_to_write)
	end
	
	def self.safe_read(file_path, password)
		read_data = File.read(file_path)
		iv, cipher_text = deserialize_from_string(read_data)
		
		decrypted = decrypt(cipher_text, key_from_password(password), iv)
		checksum, data_string = deserialize_from_string(decrypted)
		
		verify_checksum_with_data(checksum, data_string)
		return deserialize_from_string(data_string)
	end
	
	private
	
	def self.encrypt(data, key, iv)
		cipher = new_cipher
		cipher.encrypt
		cipher.key = key
		cipher.iv = iv
		return cipher.update(data) + cipher.final
	end
	
	def self.decrypt(cipher_text, key, iv)
		decipher = new_cipher
		decipher.decrypt
		decipher.key = key
		decipher.iv = iv
		begin
			return decipher.update(cipher_text) + decipher.final
		rescue OpenSSL::Cipher::CipherError
			raise BIBIFI::SecurityError.new
		end
	end
	
	def self.checksum(data)
		OpenSSL::Digest::SHA256.new.digest(data)
	end
	
	def self.verify_checksum_with_data(supposed_checksum, data)
		actual_checksum = checksum(data)
		if supposed_checksum == actual_checksum
			return true
		else
			raise BIBIFI::IntegrityViolationError.new
		end
	end
	
	def self.serialize_to_string(object)
		StringIO.open('', 'w') do |string_io|
			Marshal.dump(object, string_io)
			return string_io.string
		end
	end
	
	def self.deserialize_from_string(serialized)
		StringIO.open(serialized, 'r') do |string_io|
			begin
				Marshal.load(string_io)
			rescue ArgumentError
				raise BIBIFI::IntegrityViolationError.new
			end
		end
	end
	
	def self.new_cipher
		OpenSSL::Cipher::AES.new(128, :CBC)
	end
	
	def self.random_iv
		new_cipher.random_iv
	end

	def self.key_from_password(password)
		OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, KEY_STRETCHING_SALT, 2000, 128)
	end
end


module BIBIFI # Build It Break It Fix It
	class Error < StandardError; end
	
	class IntegrityViolationError < Error; end
	class SecurityError < Error; end
	class InvalidError < Error; end
end


module HTMLExporter
	# fill in when I find commonalities
end


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


class ArgsParser
	
end

class LogAppendArgsParser < ArgsParser
	def initialize(allow_batch)
		
	end
end

class LogReadArgsParser < ArgsParser
	def initialize
		
	end
end


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
