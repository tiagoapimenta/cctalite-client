require './navigator.rb'
require './player.rb'
require './alliance.rb'

class Game
	MAX_TRIES = 10

	attr_reader :command_points

	def initialize(user, pass)
		@navigator = Navigator.new
		@user = user
		@pass = pass
		@logged = false
		@tries = 0

		login
	end

	def me
		@me ||= Player.new self, player_info, true
	end

	def cities
		me.cities
	end

	def find_alliance(info, sumary = false)
		id = sumary && (info.key?('AllianceId') && info['AllianceId'] || info['a']) || info['i']
		@alliances.key?(id) && @alliances[id] || Alliance.new(@game, info, sumary)
	end

	def find_player(info)
		id = info['i']
		player = (me.id == id) && me || @players.key?(id) && @players[id] || nil

		if player.nil? then
			@players[id] = Player.new self, info
		else
			player.update info
		end

		@unallocated_cities.delete_if { |city|
			if city.owner_id == player.id then
				player.add_city city
				true
			else
				false
			end
		}

		player
	end

	def find_city(info)
		id = info['i']
		player = info.key?('o') && ((me.id == info['o']) && me || @players.key?(info['o']) && @players[info['o']] || nil) || nil
		city = nil

		if player then
			player.cities.each { |player_city|
				if player_city.id == id then
					city = player_city
					break
				end
			}
		else
			@unallocated_cities.each { |local_city|
				if local_city.id == id then
					city = local_city
					break
				end
			}
		end

		if city.nil? then
			city = City.new self, info
			player.add_city city unless player.nil?
		else
			city.update info
		end

		city
	end

	def update_city(city)
		poll ["OCITY:#{city.id}"]
	end

	def command(method, data, request = false) # TODO: make it protected, friendly for player, alliance, city, building, unit, etc
		open_session if @session.nil?
		tolken = {'session' => @session, 'sequenceid' => @sequence += 1}
		tolken['requestid'] = @sequence if request
		res = ajax method, data.merge(tolken)
		ok = true

		if res.is_a?(Hash) && res.key?('r') && res.key?('u') then
			ok = res['r']
			res['u'].each { |data| command_response data['t'], data['d'] } unless res['u'].nil?
		elsif res.is_a? Array then
			res.each { |data| command_response data['t'], data['d'] }
		end

		unless @logged then
			open_session
			ok = command method, data, request
		end

		ok
	end

	def poll(requests) # TODO: check if is necessary to be private
		command 'Poll', {'requests' => requests.join("\f")}, true
	end

	def to_s
		'#<Game>'
	end

	private
	def login
		@me = nil
		@players = {}
		@alliances = {}
		@unallocated_cities = {}
		@session = nil
		@command_points = 0

		@navigator.go 'https://alliances.commandandconquer.com/j_security_check', {'spring-security-redirect' => '', 'id' => '', 'timezone' => '-3', 'j_username' => @user, 'j_password' => @pass, '_web_remember_me' => ''}
		res = @navigator.go 'https://alliances.commandandconquer.com/pt_BR/game/launch'

		@login_session = res.body[/sessionId.*>/][/value=".*"/][7..-2]
		@url_ajax = res.body[/action=".*"/].gsub(/method="POST"/i, '').strip[8..-2].gsub(/^http\:/i, 'https:').split('/')[0..-2].join('/') + '/Presentation/Service.svc/ajaxEndpoint/'
		@logged = true
	end

	def ajax(method, data)
		res = @navigator.go "#{@url_ajax}#{method}", data.to_json
		if res.is_a? Net::HTTPOK then
			if res.body.strip.empty? then
				nil
			else
				['[', '{'].include?(res.body.strip[0]) && JSON.parse(res.body) || res.body
			end
		else
			res.code
		end
	end

	def open_session
		res = ajax 'OpenSession', {'session' => @login_session, 'reset' => true, 'refId' => (Time.new.to_f * 1000).floor, 'version' => -1}
		if res.is_a?(Hash) && res['r'] == 0 then
			@sequence = -1
			@session = res['i']
			@tries = 0
			true
		else
			@session = nil
			@logged = false
			@tries += 1
			if @tries > MAX_TRIES then
				false
			else
				login
				open_session
			end
		end
	end

	def player_info
		open_session if @session.nil?
		res = ajax 'GetPlayerInfo', {'session' => @session}
		if res.is_a? Hash then
			res
		else
			open_session
			player_info
		end
	end

	def command_response(type, data)
		case type
			when 'SYS'
				@logged = false if data == 'CLOSED' || data == 'LOGOUT' # TODO: log if different
			when 'PLAYER'
				find_player data
			when 'PLAYERTECH'
				me.update_techs data
			when 'CITIES'
				data['c'].each { |city| command_response 'CITY', city } if data['c'].is_a? Array
			when 'CITY'
				find_city({'o' => me.id}.merge data)
			when 'OCITY'
				find_city data
			else
				# TODO: log unknowed command
		end
	end
end
