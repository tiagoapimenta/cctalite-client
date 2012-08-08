require './base.rb'
require './unit.rb'

class City
	REPAIR_BASE    = 1
	REPAIR_DEFENSE = 2
	REPAIR_ATTACK  = 4
	REPAIR_ALL     = REPAIR_BASE | REPAIR_DEFENSE | REPAIR_ATTACK

	attr_reader :id, :name, :level, :owner_id, :x, :y, :destroyed?, :need_repair?
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
		@destroyed? = false # TODO: How to know when is it destroyed?
		@need_repair? = true # TODO: How to know when does it need to repair?
		@owner_id = info['o'] if info.key? 'o'
		@bases = info['b'].map { |base| Base.new base } if info.key? 'b'
		@units = info['u'].map { |unit| Unit.new unit } if info.key? 'u'
	end

	def bases
		@game.update_city self if @bases.nil?
		@bases
	end

	def units
		@game.update_city self if @bases.nil?
		@bases
	end

	def attack_units
		units.keep_if { |unit| unit.attack? }
	end

	def defense_units
		units.delete_if { |unit| unit.attack? }
	end

	def move(x, y)
		@game.command('CityMove', {'cityId' => @id, 'coordX' => x, 'coordY' => y})
	end

	def repair(mode = REPAIR_ALL, entity = nil)
		raw_repair 1, (entity.nil? && -1 || entity.id) unless mode & REPAIR_BASE == 0
		raw_repair 5, (entity.nil? && -1 || entity.id) unless mode & REPAIR_DEFENSE == 0
		raw_repair 4, (entity.nil? && -1 || entity.id) unless mode & REPAIR_ATTACK == 0
	end

	private
	def raw_repair(mode, entity)
		@game.command('Repair', {'cityid' => @id, 'entityId' => entity, 'mode' => mode})
	end
end
