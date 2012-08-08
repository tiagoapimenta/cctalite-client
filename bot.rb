#!/usr/bin/env ruby

require './users.rb'
require './game.rb'

$users.each { |user|
	game = Game.new user['name'], user['pass']
	puts "Player #{game.me.name}"

	game.cities.each { |city|
		puts "City #{city.name}"
		if city.destroyed? then
			x = city.x
			y = city.y
			# TODO: find a unallocated near place
			puts "Move to #{x}x#{y}" if city.move x, y
		end

		city.buildings.each { |building|
			puts "Collect #{building.x}x#{building.y} (#{building.type})" if building.can_collect? && building.collect
		}

		city.repair city.need_repair? # TODO: repeat if is until in battle

		city.buildings.each { |building|
			# TODO: use products if necessary
			# TODO: Find weakest building first
			puts "Upgrade Building #{building.x}x#{building.y} (#{building.type})" if building.can_upgrade? && building.upgrade
		}

		city.attack_units { |unit|
			# TODO: use products if necessary
			# TODO: Find weakest unit first
			# TODO: Separate buildings unit from tech units
			puts "Upgrade Attack Unit #{unit.x}x#{unit.y} (#{unit.type})" if unit.can_upgrade? && unit.upgrade
		}

		city.defense_units { |unit|
			# TODO: use products if necessary
			# TODO: Find weakest unit first
			puts "Upgrade Defense Unit #{unit.x}x#{unit.y} (#{unit.type})" if unit.can_upgrade? && unit.upgrade
		}
	}

	if game.command_points > 80 then
		# TODO: find weakest near enemy and invoke battle
	end
}
