require 'net/http';
require 'net/https'
require 'uri'
require 'json'

class Navigator
	def initialize
		@cookies = {}
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
	def go(url, data = nil, limit = 10)
		uri = URI.parse url
		http = Net::HTTP.new uri.host, uri.port
		if uri.scheme == 'https' then
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
		cookies = get_cookies uri
		request.add_field 'cookie', cookies unless cookies.empty?
		response = http.request request
		cookies = response.get_fields('set-cookie')
		save_cookies(uri, cookies) unless cookies.nil?
		response = go(response['location'], nil, limit - 1) if response.is_a? Net::HTTPRedirection
		response
	end
end
