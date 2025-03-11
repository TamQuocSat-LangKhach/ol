local xianlue = fk.CreateSkill{
  name = "xianlue",
}

Fk:loadTranslationTable{
  ["xianlue"] = "先略",
  [":xianlue"] = "主公的回合开始时，你可以记录一个普通锦囊牌的牌名（覆盖原记录）。"..
  "每回合限一次，当其他角色使用与记录的牌牌名相同的牌结算后，你摸两张牌并分配给任意角色，"..
  "然后你记录一个普通锦囊牌的牌名（覆盖原记录）。",

  ["#xianlue-choice"] = "先略：选择要记录的牌名",
  ["#xianlue-give"] = "先略：将这些牌分配给任意角色，点“取消”自己保留",
  ["@[private]xianlue"] = "先略",

  ["$xianlue1"] = "行略于先，未雨绸缪。",
  ["$xianlue2"] = "先见梧叶，而后知秋。",
}

local U = require "packages/utility/utility"

xianlue:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[private]xianlue", 0)
end)

local function DoXianlue(player)
  local room = player.room
  local result = U.askForChooseCardNames(room, player, Fk:getAllCardNames("t"), 1, 1, xianlue.name, "#xianlue-choice")
  U.setPrivateMark(player, xianlue.name, {result[1]})
end

xianlue:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target.role == "lord" and player:hasSkill(xianlue.name)
  end,
  on_use = function (self, event, target, player, data)
    DoXianlue(player)
  end,
})
xianlue:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and table.contains(U.getPrivateMark(player, xianlue.name), data.card.trueName) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(2, xianlue.name)
    if player.dead then return end
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards > 0 then
      room:askToYiji(player, {
        cards = cards,
        targets = room.alive_players,
        skill_name = xianlue.name,
        min_num = 0,
        max_num = #cards,
        prompt = "#xianlue-give",
      })
      if player.dead then return end
    end
    DoXianlue(player)
  end,
})

return xianlue
