class Alliance # TODO: GetPublicAllianceInfo | AllianceGetMemberData | AllianceSetMemberRole
	attr_reader :id, :name, :acronym, :description

	def initialize(game, info, sumary = false)
		@game = game
		if sumary then
			if info.key? 'AllianceId' then
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

	def invite(player)
		@game.alliance_invite_player player, self
	end

	def leave
		@game.leave_alliance
	end

	def destroy
		@game.destroy_alliance
	end

	def to_s
		'#<Alliance>'
	end
end
