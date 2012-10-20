#!/usr/bin/env ruby

require './game.rb'

require './users.rb'
#require './evolution_rules.rb'

$building_order = [5, 32, 1, 16, 10, 42, 40, 34, 35, 36, 24, 2, 81, 82, 80]
$attack_unit_order = [81, 88, 86, 87, 98, 94, 92, 91]
$defense_unit_order = [102, 98, 100, 99, 101, 106]
$building_defense_units = [101, 106]

$building_levels = {
	34 =>  3, # repair
	35 =>  3, # repair
	36 =>  3, # repair
	24 =>  3, # attack
	32 =>  4, # havester
	 5 =>  4, # silo
	40 => -1, # defense
	42 => -1, # defense
	80 => -3, # support
	81 => -3, # support
	82 => -3, # support
}

$building_levels = {
	10 => -3
}

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

		puts 'All resources collected' if city.can_collect? && city.collect_all

		puts 'City repaired' if city.damaged? && city.repair # TODO: repeat if is until in battle

		# TODO: use products if necessary

		loop {
			weakest_building = nil
			weakest_level = nil
			city.buildings.each { |building|
				level = building.level + ($building_levels.key?(building.type)?-$building_levels[building.type]:0)
				if building.can_upgrade? && (weakest_building.nil? || level < weakest_level || level == weakest_level && $building_order.index(building.type) < $building_order.index(weakest_building.type)) then
					weakest_building = building
					weakest_level = level
				end
			}

			break unless weakest_building && weakest_building.upgrade

			puts "Upgrade Building #{weakest_building.x}x#{weakest_building.y} #{weakest_building.level} (#{weakest_building.type})"
		}

		loop {
			weakest_unit = nil
			city.offensive_units.each { |unit|
				weakest_unit = unit if unit.can_upgrade? && (weakest_unit.nil? || unit.level < weakest_unit.level || unit.level == weakest_unit.level && $attack_unit_order.index(unit.type) < $attack_unit_order.index(weakest_unit.type))
			}

			break unless weakest_unit && weakest_unit.upgrade

			puts "Upgrade Attack Unit #{weakest_unit.x}x#{weakest_unit.y} #{weakest_unit.level} (#{weakest_unit.type})"
		}

		2.times { |time|
			include_buildings = time != 0

			weakest_unit = nil
			city.defensive_units.each { |unit|
				weakest_unit = unit if unit.can_upgrade? && (include_buildings || !$building_defense_units.include?(unit.type)) && (weakest_unit.nil? || unit.level < weakest_unit.level || unit.level == weakest_unit.level && $defense_unit_order.index(unit.type) < $defense_unit_order.index(weakest_unit.type))
			}

			break unless weakest_unit && weakest_unit.upgrade

			puts "Upgrade Defense Unit #{weakest_unit.x}x#{weakest_unit.y} #{weakest_unit.level} (#{weakest_unit.type})"
		}
	}

	if game.command_points > 80 then
		# TODO: find weakest near enemy and invoke battle
	end
}

puts 'DONE'
