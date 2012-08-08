#!/usr/bin/env ruby

require './users.rb'
require './game.rb'

$users.each { |user|
	game = Game.new user['name'], user['pass']

	game.cities.each { |city|
		if city.destroyed? then
			x = city.x
			y = city.y
			# TODO: find a unallocated near place
			city.move x, y
		end

		city.buildings.each { |building|
			building.collect if building.can_collect?
		}

		city.repair city.need_repair? # TODO: repeat if is until in battle

		city.buildings.each { |building|
			# TODO: use products if necessary
			building.upgrade if building.can_upgrade? # TODO: Find weakest building first
		}

		city.attack_units { |unit|
			# TODO: use products if necessary
			unit.upgrade if unit.can_upgrade? # TODO: Find weakest unit first
		}

		city.defense_units { |unit|
			# TODO: use products if necessary
			unit.upgrade if unit.can_upgrade? # TODO: Find weakest unit first
		}
	}

	if game.command_points > 80 then
		# TODO: find weakest near enemy and invoke battle
	end
}
