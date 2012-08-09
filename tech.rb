class Tech
	attr_reader :id, :type

	def initialize(game, info)
		@game = game
		@id = info['id']
		@type = info['mid']
	end

	def to_s
		'#<Tech>'
	end
end
