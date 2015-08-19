require 'net/http'
require 'securerandom'
require 'json'
require 'uri'
require 'httparty'
require 'typhoeus'
require 'curl'

class Error < StandardError; end
class BadRequestError < Error; end
class AuthenticationError < Error; end

class Response
	attr_reader :status, :message, :description, :message_id

	def initialize( http_response, message_id )
		response = JSON.parse(http_response.body)
		@status = response['status']
		@message = response['message']
		@description = response['description']
		@message_id = message_id
	end
end

class Chikka
	attr_accessor :client_id, :secret_key, :shortcode, :http
	SMSAPI_PATH = '/smsapi/request'
	URL_FULLPATH = 'https://post.chikka.com/smsapi/request'
	HEADERS = { 'Content-Type' => 'application/x-www-form-urlencoded' }
	DEFAULT_PARAMS = {}

	def initialize( options = {} )
		@client_id = options.fetch(:client_id) { ENV.fetch('CHIKKA_CLIENT_ID') }
		@secret_key = options.fetch(:secret_key) { ENV.fetch('CHIKKA_SECRET_KEY') }
		@shortcode = options.fetch(:shortcode) { ENV.fetch('CHIKKA_SHORTCODE') }

		@uri = URI.parse("https://post.chikka.com/smsapi/request") #options.fetch(:host) { 'post.chikka.com' }
		@http = Net::HTTP.new(@uri.host, Net::HTTP.https_default_port)
		@http.use_ssl = true

		DEFAULT_PARAMS[:client_id] = @client_id
		DEFAULT_PARAMS[:secret_key] = @secret_key
		DEFAULT_PARAMS[:shortcode] = @shortcode
	end

	def send_message( params = {} )
		params[:message_id] = params.fetch(:message_id) { generate_message_id }

		message_type = "SEND"
		if params[:request_id]
			message_type = "REPLY"
			params[:request_cost] = params.fetch(:request_cost) { "FREE" }
		end

		post_params = DEFAULT_PARAMS.merge({
			message_type: message_type
			}.merge(params))

		data = URI.encode_www_form(post_params)
		uri = URI('https://post.chikka.com/smsapi/request')

		# req = Net::HTTP::Post.new(uri)
		# req.body = data
		# req.content_type = 'application/x-www-form-urlencoded'
		# response = @http.request(req)
	
		puts "#{post_params}"
		puts "----------------"
		puts "#{data}"

		# request = Typhoeus::Request.new(
		# 	"https://post.chikka.com/smsapi/request",
		# 	method: :post,
		# 	body: data,
		# 	headers: HEADERS
		# )

		# request.on_complete do | response |
		# 	if response.success?
		# 		puts "Hell Yeah!"
		# 	elsif response.timed_out?
		# 		puts "Got a time out"
		# 	elsif response.code == 0
		# 		puts "#{response.return_message}"
		# 	else
		# 		puts "HTTP request failed: #{response.code.to_s}"
		# 	end
		# end

		# request.run

		# response = post(post_params)
		# message_sent?(response) || raise(RuntimeError, response)
		# response
		
		parse(@http.post(SMSAPI_PATH, data, { 'Content-Type' => 'application/x-www-form-urlencoded'}), params[:message_id])
	end

	private

	def generate_message_id
		SecureRandom.hex
	end

	def post( http_response )
		 HTTParty.post(URL_FULLPATH, headers: HEADERS, body: http_response)
	end

	def parse(http_response, message_id)
		response_obj = Response.new(http_response, message_id)
		case response_obj.status
		when 200
			response_obj
		when 401
			raise AuthenticationError.new( message = response_obj.description )
		when 400
			raise BadRequestError.new( message = response_obj.description )
		else
			raise Error.new( message = response_obj.description)
		end
	end

	def message_sent?(response)
		response.code == 201
	end

end

client = Chikka.new(client_id:'e2822181ab7c3b95b8d7adb04038c1ba2e456ad045983de1f3572fa9b6676b05d3a4271e', secret_key:'5vb0475dd45630c5943f6e30490747c15e27f2de7161bs9c34ja1dbd0d66db9qw3f1b6', shortcode:'2929xxxxx')
client.send_message(message: "Edsil Gwapo", mobile_number: "09263593778")

# require 'chikka'

# client = Chikka::Client.new(client_id:'e28281ab7c3b95b8d7b04038c1ba2e4ad0453de1f3572fa9b6676b05d3a4271e', secret_key:'50475dd45630c5943f6e30490747c15e27f2de7161b9c34a1dbd0d66db93f1b6', shortcode:'29290 690361')
# client.send_message(message:'This is a test', mobile_number:'639263593778')