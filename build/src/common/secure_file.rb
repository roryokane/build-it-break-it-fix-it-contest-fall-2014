require 'openssl'
require 'stringio'

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
