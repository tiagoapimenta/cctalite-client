class Building
	attr_reader :id, :level, :type, :x, :y, :can_collect?, :can_upgrade?

	def initialize(game, city, info)
		@game = game
		@city = city
		@id = info['i']
		@level = info['l']
		@type = info['t']
		@x = info['x']
		@y = info['y']
		@can_collect? = info['rv'] != 0 # TODO: How to know when is it collectable?
		@can_upgrade? = true # TODO: How to know when is it updateable?
	end

	def collect
		@game.command 'CollectResource', {'cityid' => @city.id, 'posX' => @x, 'posY' => @y}
	end

	def upgrade
		@game.command 'UpgradeBuilding', {'cityid' => @city.id, 'posX' => @x, 'posY' => @y, 'isPayd' => true}
	end

	def move(x, y)
		@game.command 'MoveBuilding', {'cityid' => @city.id, 'posX' => @x, 'posY' => @y, 'targetPosX' => x, 'targetPosY' => y}
	end

	def destroy
		@game.command 'DemolishBuilding', {'cityid' => @city.id, 'posX' => @x, 'posY' => @y}
	end
end