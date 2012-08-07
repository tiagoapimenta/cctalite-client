#!/usr/bin/env ruby

require './game.rb'

require './logins.rb'

@@orderBuilding = [1, 5, 16, 32, 10, 42, 40, 34, 35, 36, 24, 2, 81, 82]
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
		print "Building #{base['x']}x#{base['y']}: #{base['l']} (#{base['t']}) "
		res = @g.upgradeBuilding city['i'], base['x'], base['y']
		puts (res.respond_to?('key?') && res.key?('r') && res['r'] && 'OK' || 'ERR')
		break unless res['r']
		city = res['u'][0]['d']
	}
end

def upgradeUnit(city, attack = true, building = false)
	loop {
		unit = pushWeakestUnit city['u'], attack, building
		print "Unit #{unit['i']}: #{unit['cl']} (#{unit['ui']}) "
		res = @g.unitUpgrade city['i'], unit['i']
		puts (res.respond_to?('key?') && res.key?('r') && res['r'] && 'OK' || 'ERR')
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
		puts "City #{city['i']}"
		@g.repairBase city['i']
		@g.repairDefense city['i']
		@g.repairAttack city['i']
		city['b'].each { |block|
			if block['rd'] != 0 then
				print "Collect #{block['x']}x#{block['y']} (#{block['rv'].to_i}) "
				r = @g.collectResource city['i'], block['x'], block['y']
				puts (r.respond_to?('key?') && r.key?('r') && r['r'] && 'OK' || 'ERR')
			end
		}

		upgradeBuilding city

		upgradeUnit city
		upgradeUnit city, false
		upgradeUnit city, false, true
	}
end

first = true

$logins.each { |login|
	puts 'Troca' unless first
	first = false

	bot login['user'], login['pass']
}

puts 'FIM'
