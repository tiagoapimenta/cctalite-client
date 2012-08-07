require './city.rb'
require './alliance.rb'
require './tech.rb'

class Player
	attr_reader :id, :name, :cities, :units, :alliance, :techs

	def initialize(info, sumary = false)
		if sumary then
			@id = info['Id']
			@name = info['Name']
			@alliance = Alliance.new info, true
			@cities = info['Cities'].map { |city| City.new city, true }
			@techs = info['Techs'].map { |tech| Tech.new tech }
		else
			@id = info['i']
			@name = info['n']
			@alliance = Alliance.new info
			@cities = info['c'].map { |city| City.new city, true }
			@techs = nil
		end
	end

	def update_techs(techs)
		@techs = techs.map { |tech| Tech.new tech }
	end
end
