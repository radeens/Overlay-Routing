require 'openssl'

class Secure

	def self.encrypt(key, message)
		new_key = OpenSSL::PKey::RSA.new key
		cipher_text = new_key.public_encrypt(message)
	end

	def self.decrypt(cipher)
		message = @@new_key.private_decrypt(cipher)
	end
end
