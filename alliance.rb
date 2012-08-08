class Alliance
	attr_reader :id, :name, :acronym, :description

	def initialize(game, info, sumary = false)
		@game = game
		if sumary then
			if info.respond_to? 'AllianceId' then
				@id = info['AllianceId']
				@name = info['AllianceName']
			else
				@id = info['a']
				@id = info['an']
			end
		else
			@id = info['i']
			update info
		end
	end

	def update(info)
		raise 'Can\'t update different id' unless info['i'] == @id
		@name = info['n']
		@acronym = info['a']
		@description = info['d']
	end
end
