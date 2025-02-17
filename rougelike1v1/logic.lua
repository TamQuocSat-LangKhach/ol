local RougeUtil = require "packages.ol.rougelike1v1.util"

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
  local players = room.alive_players
  for _, p in ipairs(players) do
    room:setPlayerMark(p, "@[rouge1v1]mark", {})
    room:setPlayerMark(p, "@[rouge_skills]", {})
    room:setPlayerMark(p, "rougelike1v1_skill_num", 2)
    room:setPlayerMark(p, "rougelike1v1_shop_num", 4)
  end

  -- 选初始战法
  local req = Request:new(players, "AskForChoice")
  req.focus_text = "rougelike1v1"
  req.receive_decode = false
  local _talents = table.random(RougeUtil.talents, 3 * #players)
  local talents = table.map(_talents, function(t) return t[2] end)
  for i, p in ipairs(players) do
    local choices = table.slice(talents, 3 * (i - 1) + 1, 3 * (i - 1) + 4)
    req:setData(p, {
      choices, choices, "rougelike1v1", "#rouge-init-talent", true
    })
    req:setDefaultReply(p, choices[1])
  end
  for _, p in ipairs(players) do
    local result = req:getResult(p)
    for _, t in ipairs(_talents) do
      if t[2] == result then
        room:sendLog {
          type = "#rouge_init_talent",
          from = p.id,
          arg = t[2],
        }
        t[3](t[2], p)
        break
      end
    end
  end
end

return Rouge1v1Logic
