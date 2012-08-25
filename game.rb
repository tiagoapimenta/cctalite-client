require './navigator.rb'
require './player.rb'
require './alliance.rb'
# TODO: Reports | Messages -> GetReportHeaderBaseCount | GetReportHeaderBase | GetReportData | NotificationGetSingle | GetCombatData
# TODO: alliances -> GetPublicAllianceInfo
# TODO: player -> GetPublicPlayerInfoByName | GetPublicPlayerInfo
# TODO: city -> ajax 'GetPublicCityInfoById', {'session' => @session, 'id'=> id}

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
		poll ["OCITY:#{city.id}:-1"]
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
		# Samples: "UA", "WC:A", "TIME:#{(Time.new.to_f * 1000).floor}", "CHAT:", "WORD:", "GIFT:", "ACS:999", "ASS:99", "CAT:1", "ABW:5555555:0", "OCITY:5555555:5"
		command 'Poll', {'requests' => requests.join("\f")}, true
	end

	def unlock_tech(type)
		command 'UnlockTech', {'mdbtechid' => type}
	end

	def battle
		# TODO: command 'InvokeBattle', {'battleSetup' => {'d' => Fixnum, 'a' => Fixnum, 'u' => [{'i' => unity.id, 'x' => x, 'y' => y}, ...], 's' => 0}}
	end

	def create_city(name, x, y)
		command 'CityFound', {'name' => name, 'coordX' => x, 'coordY' => y}
	end

	def create_alliance(name, tag)
		open_session if @session.nil?
		res = ajax 'AllianceCreate', {'session' => @session, 'name' => name, 'tag' => tag}
		unless res.is_a? Hash then
			open_session
			res = create_alliance name, tag
		end
		res # TODO: res['i'] -> new alliance id
	end

	def join_alliance(alliance)
		open_session if @session.nil?
		invite_id = -1
		player_invitations.each { |invitation|
			if invitation['j'] == alliance.id then
				invite_id = invitation['i']
				break
			end
		}
		res = ajax 'AllianceInviteAccept', {'session' => @session, 'invitationId' => invite_id, 'allianceId' => alliance.id}
		if res.is_a? Hash then
			res['r'] == 0
		else
			open_session
			join_alliance alliance
		end
	end

	def leave_alliance
		open_session if @session.nil?
		res = ajax 'AllianceLeave', {'session' => @session}
		unless res.is_a? String then
			open_session
			res = leave_alliance
		end
		res.to_i == 0
	end

	def destroy_alliance
		open_session if @session.nil?
		res = ajax 'AllianceDisband', {'session' => @session}
		unless res.is_a? String then
			open_session
			res = destroy_alliance
		end
		res.to_i == 0
	end

	def alliance_invite_player(player, alliance = nil)
		alliance ||= me.alliance
		open_session if @session.nil?
		res = ajax 'AllianceInvite', {'session' => @session, 'inviteeName' => player.name}
		unless res.is_a? String then
			open_session
			res = alliance_invite_player player, alliance
		end
		res.to_i == 0
	end

	def mission_reward(mission, city = nil)
		city ||= me.cities[0]
		open_session if @session.nil?
		res = ajax 'ClaimMissionStepReward', {'session' => @session, 'cityid' => city.id, 'missionStepId' => mission}
		if res.is_a? Hash then
			res
		else
			open_session
			mission_reward mission, city
		end
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

		# TODO: Perhaps I should use nokogiri instead, I'll think about it later.
		raise 'Login or password wrong.' if @navigator.go('https://alliances.commandandconquer.com/j_security_check', {'spring-security-redirect' => '', 'id' => '', 'timezone' => '-3', 'j_username' => @user, 'j_password' => @pass, '_web_remember_me' => ''}).body.include? 'loginForm'
		res = @navigator.go 'https://alliances.commandandconquer.com/pt_BR/game/launch'

		@login_session = res.body[/sessionId.*>/][/value=".*"/][7..-2]
		@url_ajax = res.body[/action=".*"/].gsub(/method="POST"/i, '').strip[8..-2].gsub(/^http\:/i, 'https:').split('/')[0..-2].join('/') + '/Presentation/Service.svc/ajaxEndpoint/'
		@navigator.go 'https://prodgame09.alliances.commandandconquer.com/45/index.aspx'
		sleep 5
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

	def player_invitations
		open_session if @session.nil?
		res = ajax 'PlayerGetInvitations', {'session' => @session}
		if res.is_a? Hash then
			res
		else
			open_session
			player_info
		end
	end

	def server_info
		open_session if @session.nil?
		res = ajax 'GetServerInfo', {'session' => @session}
		if res.is_a? Hash then
			res
		else
			open_session
			player_info
		end
	end

	def notification_range(take = 50)
		open_session if @session.nil?
		res = ajax 'NotificationGetRange', {'session' => @session, 'category' => 0, 'skip' => 0, 'take' => take, 'sortOrder' => 1, 'ascending' => false}
		if res.is_a? Array then
			res
		else
			open_session
			player_info
		end
	end

	def incentive_rewards
		open_session if @session.nil?
		res = ajax 'GetIncentiveRewards', {'session' => @session}
		unless res.is_a? Fixnum || res.nil? then
			res
		else
			open_session
			player_info
		end
	end

	def command_response(type, data)
		case type
			when 'SYS'
				raise "Unknown system call, please report the developer about \"#{data}\" call." unless data == 'CLOSED' || data == 'LOGOUT'
				@logged = false
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
				# TODO: log unknown commands
		end
	end
end
