require "fonepaisaPG/version"

module FonepaisaPG

	class Functions
		DIGEST = OpenSSL::Digest::SHA512.new
		def get_sign(privKey,apiKey,id,merchant_id,invoice,invoice_amt)
			@hash_input =  apiKey + '#' + id + '#' + merchant_id + '#' + invoice + '#' + invoice_amt + '#'
			@PRIVATE_KEY = OpenSSL::PKey::RSA.new(privKey)
			@sign = @PRIVATE_KEY.sign DIGEST, @hash_input
			@sign.unpack('H*').first
		end

		def cancel(privKey,apiKey,id,merchant_id,invoice)
			@hash_input = apiKey + '#' + id + '#' + merchant_id + '#' + invoice + '#'
			@PRIVATE_KEY = OpenSSL::PKey::RSA.new(privKey)
			@signature = @PRIVATE_KEY.sign DIGEST, @hash_input
			@sign = @signature.unpack('H*').first
			@post_data = Hash[ :id => id, :merchant_id => merchant_id,:sign=>@sign,:invoice=>invoice]
			if Rails.env.test? || Rails.env.development?
				test_url_cancel = 'https://test.fonepaisa.com/portal/payment/cancel'
			elsif Rails.env.production?
				test_url_cancel = 'https://secure.fonepaisa.com/portal/payment/cancel'
			end
			uri = URI.parse(test_url_cancel)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
			request.body = @post_data.to_json
			response = http.request(request)
			return response.body
		end

		def confirm(pubKey,invoice,paymentReference,sign)
			@hash_input = '#' + invoice + '#' + paymentReference + '#'
			@FONEPAISA_PUBLIC_KEY = OpenSSL::PKey::RSA.new(pubKey)
			sign_raw = Array[sign]
			@signVerify = @FONEPAISA_PUBLIC_KEY.verify(DIGEST, sign_raw.pack('H*'), @hash_input)
			return @signVerify
		end

		def inquire(privKey,apiKey,id,merchant_id,invoice)
			@hash_input = apiKey + '#' + id + '#' + merchant_id + '#' + invoice + '#'
			@PRIVATE_KEY = OpenSSL::PKey::RSA.new(privKey)
			@signature = @PRIVATE_KEY.sign DIGEST, @hash_input
			@sign = @signature.unpack('H*').first
			@post_data = Hash[ :id => id, :merchant_id => merchant_id,:sign=>@sign,:invoice=>invoice]
			if Rails.env.test? || Rails.env.development?
				test_url_inquire = 'https://test.fonepaisa.com/portal/payment/inquire'
			elsif Rails.env.production?
				test_url_inquire = 'https://secure.fonepaisa.com/portal/payment/inquire'
			end
			uri = URI.parse(test_url_inquire)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
			request.body = @post_data.to_json
			response = http.request(request)
			return response.body
		end
	end
end
