#!/usr/bin/env ruby

require './users.rb'
require './game.rb'

$building_order = [5, 32, 1, 16, 10, 42, 40, 34, 35, 36, 24, 2, 81, 82, 80]
$attack_unit_order = [81, 88, 86, 87, 98, 94, 92]
$defense_unit_order = [102, 98, 100, 99, 101, 106]
$building_defense_units = [101, 106]

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

		puts 'City repaired' if city.need_repair? && city.repair # TODO: repeat if is until in battle

		# TODO: use products if necessary

		loop {
			weakest_building = nil
			city.buildings.each { |building|
				weakest_building = building if building.can_upgrade? && (weakest_building.nil? || building.level < weakest_building.level || building.level == weakest_building.level && $building_order.index(building.type) < $building_order.index(weakest_building.type))
			}

			break unless weakest_building && weakest_building.upgrade

			puts "Upgrade Building #{weakest_building.x}x#{weakest_building.y} #{weakest_building.level} (#{weakest_building.type})"
		}

		loop {
			weakest_unit = nil
			city.attack_units.each { |unit|
				weakest_unit = unit if unit.can_upgrade? && (weakest_unit.nil? || unit.level < weakest_unit.level || unit.level == weakest_unit.level && $attack_unit_order.index(unit.type) < $attack_unit_order.index(weakest_unit.type))
			}

			break unless weakest_unit && weakest_unit.upgrade

			puts "Upgrade Attack Unit #{weakest_unit.x}x#{weakest_unit.y} #{weakest_unit.level} (#{weakest_unit.type})"
		}

		2.times { |time|
			include_buildings = time != 0

			weakest_unit = nil
			city.defense_units.each { |unit|
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
