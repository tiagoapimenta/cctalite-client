require './navigator.rb'
require './player.rb'
require './alliance.rb'

class Game
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

	# TODO: find_player, find_city...

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

	def poll(requests) # TODO: verify if is necessary to be private
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
			@logged = false
			@tries += 1
			if @tries > 10 then
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
				id = data['i']
				player = (me.id == id) && me || @players.key?(id) && @players[id] || nil

				if player.nil? then
					@players[id] = Player.new self, data
				else
					player.update data
				end

				@unallocated_cities.delete_if! { |city|
					if city.owner_id == player.id then
						player.add_city city
						true
					else
						false
					end
				}
			when 'PLAYERTECH'
				me.update_techs data
			when 'CITIES'
				data.each { |city| command_response 'CITY', city }
			when 'CITY'
				id = data['i']
				player = nil
				city = nil
				if info.key?('o') && @players.key?(data['o']) then
					player = @players[data['o']]
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
					city = City.new self, data
					player.add_city city unless player.nil?
				else
					city.update data
				end
			else
				# TODO: log unknowed command
		end
	end















begin
	public
	def initialize
		@nav = Navigator.new
		@cache = nil
	end

	def clear
		remove_instance_variable '@sessionId' unless defined?(@sessionId).nil?
		remove_instance_variable '@playerInfo' unless defined?(@playerInfo).nil?
		@cache = nil
	end

	def login(user, pass)
		@user = user
		@pass = pass
		clear

		data = {
			'spring-security-redirect' => '',
			'id' => '',
			'timezone' => '-3',
			'j_username' => @user,
			'j_password' => @pass,
			'_web_remember_me' => ''
		}
		@nav.go 'https://alliances.commandandconquer.com/j_security_check', data
		res = @nav.go 'https://alliances.commandandconquer.com/pt_BR/game/launch'
		# do it with nokogiri?
		@globalSessionId = res.body[/sessionId.*>/][/value=".*"/][7..-2]
		@urlBase = res.body[/action=".*"/].gsub(/method="POST"/i, '').strip[8..-2].gsub(/^http\:/i, 'https:') # https://prodgame09.alliances.commandandconquer.com/45/index.aspx
		@ajax = @urlBase.split('/')[0..-2].join('/') + "/Presentation/Service.svc/ajaxEndpoint/"
		# @nav.go @urlBase, {'sessionId' => @sessionId}
	end

	def rawAjax(method, data)
		res = @nav.go "#{@ajax}#{method}", data.to_json
		if res.is_a? Net::HTTPOK then
			if res.body.empty? then
				nil
			else
				JSON.parse res.body
			end
		else
			res.code
		end
	end

	def ajax(method, data)
		openSession if defined?(@sessionId).nil?
		res = rawAjax method, data.merge({'session' => @sessionId, 'sequenceid' => @sequence += 1})
		ok = true
		if res.respond_to? 'each' then
			res.each { |cmd|
				if cmd.is_a? Hash and cmd['t'] == 'SYS' and cmd['d'] == 'CLOSED' then
					ok = false
					break
				end
			}
		end
		unless ok then
			remove_instance_variable '@sessionId'
			openSession
		end
		res
	end

	def time
		(Time.new.to_f * 1000).floor
	end

	def openSession
		5.times {
			res = rawAjax 'OpenSession', {'session' => @globalSessionId, 'reset' => true, 'refId' => time, 'version' => -1}
			unless res.nil? or res.is_a? Numeric then
				case res['r']
					when 0
						@sequence = -1
						@sessionId = res['i']
						break
					when -50
						login @user, @pass
				end
			end
		}
	end

	def getServerInfo
		openSession if defined?(@sessionId).nil?
		@serverInfo = rawAjax 'GetServerInfo', {'session' => @sessionId}
	end

	def getPlayerInfo
		openSession if defined?(@sessionId).nil?
		@playerInfo = rawAjax 'GetPlayerInfo', {'session' => @sessionId}
	end

	def notificationGetRange
		openSession if defined?(@sessionId).nil?
		rawAjax 'NotificationGetRange', {'session' => @sessionId, 'category' => 0, 'skip' => 0, 'take' => 50,'sortOrder' => 1, 'ascending' => false}
	end

	def getIncentiveRewards
		openSession if defined?(@sessionId).nil?
		rawAjax 'GetIncentiveRewards', {'session' => @sessionId}
	end

	def cities
		getPlayerInfo if defined?(@playerInfo).nil?
		@playerInfo['Cities']
	end

	def collectResource(city, x, y)
		res = ajax 'CollectResource', {'cityid' => city, 'posX' => x, 'posY' => y}
		poll [] if res['u'].nil?
		res
	end

	def repair(city, mode = 1, entity = -1)
		ajax 'Repair', {'cityid' => city, 'entityId' => entity, 'mode' => mode}
	end

	def repairBase(city, entity = -1)
		repair city, 1, entity
	end

	def repairDefense(city, entity = -1)
		repair city, 5, entity
	end

	def repairAttack(city, entity = -1)
		repair city, 4, entity
	end

	def upgradeBuilding(city, x, y, paid = true)
		ajax 'UpgradeBuilding', {'cityid' => city, 'posX' => x, 'posY' => y, 'isPaid' => paid}
	end

	def unitUpgrade(city, unit)
		ajax 'UnitUpgrade', {'cityid' => city, 'unitId' => unit}
	end

	def unitMove(city, unit, x, y)
		ajax 'UnitMove', {'cityid' => city, 'unitId' => unit, 'coordX' => x, 'coordY' => y}
	end

	def moveBuilding(city, x, y, x2, y2)
		ajax 'MoveBuilding', {'cityid' => city, 'posX' => x, 'posY' => y, 'targetPosX' => x2, 'targetPosY' => y2}
	end

	def cityMove(city, x, y)
		ajax 'CityMove', {'cityId'  => city, 'coordX' => x, 'coordY' => y}
	end

	def poll reqs
		openSession if defined?(@sessionId).nil?
		ajax 'Poll', {'requestid' => @sequence + 1, 'requests' => reqs.join("\f")}
	end

	def selfTrade(target, source, type, amount)
		ajax 'SelfTrade', {'targetCityId' => target, 'sourceCityId' => source, 'resourceType' => type, 'amount' => amount}
	end
end
end
