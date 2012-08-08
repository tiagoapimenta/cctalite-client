class Tech
	attr_reader :id, :type

	def initialize(game, info)
		@game = game
		@id = info['id']
		@type = info['mid']
	end

	def unlock
		# TODO: Unlock new tech? It shouldn't be here, maybe in game.unlock_tech
	end

	def to_s
		'#<Tech>'
	end
end
