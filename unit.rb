class Unit
	attr_reader :id, :level, :type, :x, :y, :attack?, :can_upgrade?

	def initialize(game, city, info)
		@game = game
		@city = city
		@id = info['i']
		@level = info['cl']
		@type = info['ui']
		@x = info['cx']
		@y = info['cy']
		@attack? =  @type > 96 # TODO: How to know if is it a offensive unit?
		@can_upgrade? = true # TODO: How to know when is it updateable?
	end

	def upgrade
		@game.command 'UnitUpgrade', {'cityid' => @city.id, 'unitId' => @id}
	end

	def move(x, y)
		@game.command 'UnitMove', {'cityid' => @city.id, 'unitId' => @id, 'coordX' => x, 'coordY' => y}
	end

	def destroy
		@game.command 'UnitDismiss', {'cityid' => @city.id, 'unitId' => @id}
	end
end
