require './city.rb'
require './alliance.rb'
require './tech.rb'

class Player
	attr_reader :id, :name, :cities, :units, :alliance, :techs # TODO: Products?

	def initialize(game, info, sumary = false)
		@game = game
		if sumary then
			@id = info['Id']
			@name = info['Name']
			@alliance = Alliance.new @game, info, true unless info['AllianceId'] == 0
			@cities = info['Cities'].map { |city| City.new @game, city }
			@techs = info['Techs'].map { |tech| Tech.new @game, tech }
		else
			@id = info['i']
			update info
		end
	end

	def update(info)
		raise 'Can\'t update different id' unless info['i'] == @id
		@name = info['n']
		@alliance = Alliance.new @game, info, true unless info['a'] == 0
		@cities = info['c'].map { |city| City.new @game, city }
	end

	def update_techs(techs)
		raise 'Can\'t update techs from non-me player' unless @game.me == self
		@techs = techs.map { |tech| Tech.new @game, tech }
	end
end
