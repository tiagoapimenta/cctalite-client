#!/usr/bin/env ruby

require './game.rb'

require './logins.rb'

@@orderBuilding = [5, 32, 1, 16, 10, 42, 40, 34, 35, 36, 24, 2, 81, 82]
@@orderUnitAttack = [81, 88, 86, 87, 98, 94, 92]
@@orderUnitDefense = [102, 98, 101]
@@orderUnitBuilding = [101]

def pushWeakestBuilding(bases)
	weak_base = nil

	bases.each { |base|
		weak_base = base if weak_base.nil? || base['l'] < weak_base['l'] || base['l'] == weak_base['l'] && @@orderBuilding.index(base['t']) < @@orderBuilding.index(weak_base['t']) # TODO: diferenciar haverster de tiberium de cristais
	}

	weak_base
end

def pushWeakestUnit(units, attack = true, building = false)
	if attack then
		orderUnit = @@orderUnitAttack
	else
		orderUnit = @@orderUnitDefense
	end

	weak_unit = nil

	units.each { |unit|
		weak_unit = unit if orderUnit.include?(unit['ui']) && (building || !@@orderUnitBuilding.include?(unit['ui'])) && (weak_unit.nil? || unit['cl'] < weak_unit['cl'] || unit['cl'] == weak_unit['cl'] && orderUnit.index(unit['ui']) < orderUnit.index(weak_unit['ui']))
	}

	weak_unit
end

def upgradeBuilding(city)
	loop {
		base = pushWeakestBuilding city['b']
		res = @g.upgradeBuilding city['i'], base['x'], base['y']
		puts "Building #{base['x']}x#{base['y']}: #{base['l']} (#{base['t']})" if res['r']
		break unless res['r']
		city = res['u'][0]['d']
	}
end

def upgradeUnit(city, attack = true, building = false)
	loop {
		unit = pushWeakestUnit city['u'], attack, building
		res = @g.unitUpgrade city['i'], unit['i']
		puts "Unit #{unit['i']}: #{unit['cl']} (#{unit['ui']})" if res['r']
		break unless res['r']
		city = res['u'][0]['d']
	}
end

def bot login, password
	@g = Game.new
	@g.login login, password
	res = @g.poll []
	cities = []
	res.each { |r|
		cities = r['d']['c'] if r['t'] == 'CITIES'
	}
	cities.each { |city|
		puts "City #{city['i']}: #{city['n']}"
		puts 'Base repaired' if @g.repairBase(city['i'])['r']
		puts 'Defense repaired' if @g.repairDefense(city['i'])['r']
		puts 'Attack repaired' if @g.repairAttack(city['i'])['r']
		city['b'].each { |block|
			puts "Collect #{block['x']}x#{block['y']} (#{block['rv'].to_i})" if block['rd'] != 0 && @g.collectResource(city['i'], block['x'], block['y'])['r']
		}

		upgradeBuilding city

		upgradeUnit city
		upgradeUnit city, false
		upgradeUnit city, false, true
	}
end

$logins.each { |login|
	puts "User #{login['user']}"

	bot login['user'], login['pass']
}

puts 'FINISH'
