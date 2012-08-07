require './base.rb'
require './unit.rb'

class City
	attr_reader :id, :name, :level, :owner_id, :x, :y, :bases, :units # TODO: separe attack/defense units

	def initialize(info)
		@id = info['i']
		@name = info['n']
		@x = info['x']
		@y = info['y']
		@level = info['lv'] if info.key? 'lv'
		@owner_id = info['o'] if info.key? 'o'
		@bases = info['b'].map { |base| Base.new base } if info.key? 'b'
		@units = info['u'].map { |unit| Unit.new unit } if info.key? 'u'
	end
end
