---@class Rouge1v1Logic : GameLogic
local Rouge1v1Logic = GameLogic:subclass("Rouge1v1Logic")

function Rouge1v1Logic:attachSkillToPlayers()
  GameLogic.attachSkillToPlayers(self)
  local room = self.room
  local p = room.players[1]
  room:handleAddLoseSkills(p, "#rougelike1v1_rule", nil, false, true)
end

function Rouge1v1Logic:prepareForStart()
  GameLogic.prepareForStart(self)
  local room = self.room
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@[rouge1v1]mark", {})
  end
end

return Rouge1v1Logic