---@class Rouge1v1Logic : GameLogic
local Rouge1v1Logic = GameLogic:subclass("Rouge1v1Logic")

function Rouge1v1Logic:chooseGenerals()
  local room = self.room ---@type Room
  local generalNum = room.settings.generalNum
  local lord = room:getLord()
  room:setCurrent(lord)
  local players = room.players
  local generals = room:getNGenerals(2 * generalNum)
  local req = Request:new(players, "AskForGeneral")
  for i, p in ipairs(players) do
    local arg = table.slice(generals, (i - 1) * generalNum + 1, i * generalNum + 1)
    req:setData(p, { arg, 1 })
    req:setDefaultReply(p, { arg[1] })
  end
  req:ask()
  local selected = {}
  for _, p in ipairs(players) do
    local general_ret
    general_ret = req:getResult(p)[1]
    room:setPlayerGeneral(p, general_ret, true, true)
    table.insertIfNeed(selected, general_ret)
  end
  generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
  room:returnToGeneralPile(generals)
  for _, g in ipairs(selected) do
    room:findGeneral(g)
  end
  room:askForChooseKingdom(players)

  for _, p in ipairs(players) do
    room:broadcastProperty(p, "general")
  end
end

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
    room:setPlayerMark(p, "@rougelike1v1_skill_num", 2)
    room:setPlayerMark(p, "rougelike1v1_shop_num", 4)
  end
end

return Rouge1v1Logic