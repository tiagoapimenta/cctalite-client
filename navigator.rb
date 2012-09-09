require 'net/http'
require 'net/https'
require 'uri'
require 'rubygems'
require 'json'
require 'timeout'

class Navigator
	def initialize
		@cookies = {}
		@requests = {}
	end

	def save_cookies(uri, cookies)
		cookies.each { |cookie|
			key = ''
			value = ''
			domain = uri.host
			path = '/'
			#expires = ''
			secure = false
			#httponly = false
			args = cookie.split ';'
			val = args[0].strip.split '=', 2
			key = val[0]
			value = val[1]
			args[1..-1].each { |arg|
				val = arg.strip.split '=', 2
				case val[0].downcase
					#when 'expires' then
					when 'domain' then
						domain = val[1]
					when 'path' then
						path = val[1]
					when 'secure' then
						secure = true
					#when 'httponly' then
				end
			}
			@cookies[domain] ||= {}
			@cookies[domain][key] = {
				'path' => path,
				'value' => value,
				'secure' => secure
				#expires
			}
		}
	end

	def get_cookies(uri)
		cookies = []
		@cookies.each { |domain, keys|
			if domain == uri.host || domain[0] == '.' && (domain[1..-1] == uri.host || uri.host.end_with?(domain)) then
				keys.each { |key, data|
					cookies << "#{key}=#{data['value']}" if (!data['secure'] || data['secure'] && uri.scheme == 'https') && uri.request_uri.start_with?(data['path'])
				}
			end
		}
		cookies.join '; '
	end

	def go(url, data = nil, limit = 10, again = true)
		request_key = nil
		Timeout::timeout(120) {
			uri = url.is_a?(URI) && url || URI.parse(url)
			request_key = "#{uri.scheme}:#{uri.host}:#{uri.port}"
			if @requests.key? request_key then
				http = @requests[request_key]
			else
				http = Net::HTTP.new uri.host, uri.port
				if uri.scheme == 'https' then
					http.use_ssl = true # TODO: record certify
					http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				end
				@requests[request_key] = http
			end
			if data.nil? then
				request = Net::HTTP::Get.new uri.request_uri
			else
				request = Net::HTTP::Post.new uri.request_uri
				if data.respond_to? 'each'
					request.set_form_data data
				else
					request.body = data
					request['Content-Type'] = 'application/json'
				end
			end
			request['User-Agent'] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1'
			cookies = get_cookies uri
			request.add_field 'cookie', cookies unless cookies.empty?
			response = http.request request
			cookies = response.get_fields('set-cookie')
			save_cookies(uri, cookies) unless cookies.nil?
			response = go(uri + response['location'], nil, limit - 1) if response.is_a? Net::HTTPRedirection
			response
		}
	rescue
		if again then
			@requests.delete request_key unless request_key.nil?
			go url, data, limit, false
		else
			nil
		end
	end

	def to_s
		'#<Navigator>'
	end
end
