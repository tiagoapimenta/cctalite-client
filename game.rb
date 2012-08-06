require './navigator.rb'

class Game
	def initialize
		@nav = Navigator.new
	end

	def login(user, pass)
		@user = user
		@pass = pass
		remove_instance_variable '@sessionId' unless defined?(@sessionId).nil?
		remove_instance_variable '@playerInfo' unless defined?(@playerInfo).nil?

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
