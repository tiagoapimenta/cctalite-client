class Unit
	# TODO: types

	attr_reader :id, :level, :type, :x, :y, :hp, :max_hp

	def initialize(game, city, info)
		@game = game
		@city = city
		@id = info['i']
		@level = info['cl']
		@type = info['ui']
		@x = info['cx']
		@y = info['cy']
		@hp = info['h']
		@max_hp = @game.calc_max_hp(@level, @game.data['units'][@id.to_s])
	end

	def offensive?
		@type < 96 # TODO: How to know if is it a offensive unit?
	end

	def can_upgrade?
		true # TODO: How to know when is it updateable?
	end

	def upgrade
		@game.command 'UnitUpgrade', {'cityid' => @city.id, 'unitId' => @id}
	end

	def damaged?
		@hp < @max_hp
	end

	def move(x, y)
		@game.command 'UnitMove', {'cityid' => @city.id, 'unitId' => @id, 'coordX' => x, 'coordY' => y}
	end

	def destroy
		@game.command 'UnitDismiss', {'cityid' => @city.id, 'unitId' => @id}
	end

	def to_s
		'#<Unit>'
	end
end
