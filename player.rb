require './city.rb'
require './tech.rb'

class Player
	attr_reader :id, :name, :cities, :alliance, :techs # TODO: Products?

	def initialize(game, info, sumary = false)
		@game = game
		@cities = []
		if sumary then
			@id = info['Id']
			@name = info['Name']
			@alliance = @game.find_alliance(info, true) unless info['AllianceId'] == 0
			@cities = info['Cities'].map { |city| @game.find_city city }
			@techs = info['Techs'].map { |tech| Tech.new @game, tech }
		else
			@id = info['i']
			update info
		end
	end

	def update(info)
		raise 'Can\'t update different id' unless info['i'] == @id
		@name = info['n']
		@alliance = info['a'] == 0 && nil || @game.find_alliance(info, true)
		@cities = info['c'].map { |city| @game.find_city city } if info.key?('c') && info['c'].is_a?(Array)
	end

	def update_techs(techs)
		raise 'Can\'t update techs from non-me player' unless @game.me == self
		@techs = techs.map { |tech| Tech.new @game, tech }
	end

	def add_city(city)
		raise 'Can\'t add another player\'s city' unless city.owner_id == @id
		@cities << city
	end

	def to_s
		'#<Player>'
	end
end
