require './building.rb'
require './unit.rb'

class City
	REPAIR_BUILDINGS = 1
	REPAIR_DEFENSE   = 2
	REPAIR_ATTACK    = 4
	REPAIR_ALL       = REPAIR_BUILDINGS | REPAIR_DEFENSE | REPAIR_ATTACK

	attr_reader :id, :name, :level, :owner_id, :x, :y
	def initialize(game, info)
		@game = game
		@id = info['i']
		update info
	end

	def update(info)
		raise 'Can\'t update different id' unless info['i'] == @id
		@name = info['n']
		@level = info['lv'] if info.key? 'lv'
		@x = info['x']
		@y = info['y']
		@owner_id = info['o'] if info.key? 'o'
		@buildings = info['b'].map { |building| Building.new @game, self, building } if info.key? 'b'
		@units = info['u'].map { |unit| Unit.new @game, self, unit } if info.key? 'u'
	end

	def buildings
		@game.update_city self if @buildings.nil?
		@buildings
	end

	def units
		@game.update_city self if @units.nil?
		@units
	end

	def attack_units
		units.select { |unit| unit.attack? }
	end

	def defense_units
		units.reject { |unit| unit.attack? }
	end

	def destroyed?
		false # TODO: How to know when is it destroyed?
	end

	def need_repair?
		true # TODO: How to know when does it need to repair?
	end

	def move(x, y)
		@game.command('CityMove', {'cityId' => @id, 'coordX' => x, 'coordY' => y})
	end

	def repair(mode = REPAIR_ALL, entity = nil)
		raw_repair 1, (entity.nil? && -1 || entity.id) unless mode & REPAIR_BUILDINGS == 0
		raw_repair 5, (entity.nil? && -1 || entity.id) unless mode & REPAIR_DEFENSE == 0
		raw_repair 4, (entity.nil? && -1 || entity.id) unless mode & REPAIR_ATTACK == 0
	end

	def crete_building(type, x, y)
		@game.command 'CreateBuilding', {'cityid' => @id, 'posX' => x, 'posY' => y, 'type' => type, 'isPaid' => true}
	end

	def create_unit(type, x, y)
		@game.command 'StartUnitProduction', {'cityid' => @id, 'unitId' => type, 'coordX' => x, 'coordY' => y}
	end

	def trade(city, type, amount) # TODO: Enumarate resource_type
		@game.command 'SelfTrade', {'targetCityId' => @id, 'sourceCityId' => city.id, 'resourceType' => type, 'amount' => amount}
	end

	def trade_tiberium(city, amount)
		trade city, 1, amount
	end

	def trade_cristals(city, amount)
		trade city, 2, amount
	end

	def use_product(product)
		@game.command 'UseProduct', {'cityId' => @id, 'productId' => product}
	end

	def mission_reward(mission)
		@game.mission_reward mission, self
	end

	def rename(name)
		@game.command 'CityRename', {'cityId' => @id, 'name' => name}
	end

	def support(city)
		@game.command 'SetDedicatedSupport', {'sourceBaseId' => @id, 'targetBaseId' => city.id}
	end

	def to_s
		'#<City>'
	end

	private
	def raw_repair(mode, entity)
		@game.command('Repair', {'cityid' => @id, 'entityId' => entity, 'mode' => mode})
	end
end
