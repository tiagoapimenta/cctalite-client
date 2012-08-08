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

		city.bases.each { |base|
			base.collect if base.can_collect?
		}

		city.repair city.need_repair? # TODO: repeat if is until in battle

		city.bases.each { |base|
			# TODO: use products if necessary
			base.upgrade if base.can_upgrade? # TODO: Find weakest base first
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
