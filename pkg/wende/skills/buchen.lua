local buchen = fk.CreateSkill{
  name = "buchen",
  tags = { Skill.Hidden },
}

Fk:loadTranslationTable{
  ["buchen"] = "不臣",
  [":buchen"] = "隐匿技，当你于其他角色的回合登场后，你可以获得其一张牌。",

  ["#buchen-invoke"] = "不臣：你可以获得 %dest 一张牌",

  ["$buchen1"] = "螟蛉之光，安敢同日月争辉？",
  ["$buchen2"] = "巍巍隐帝，岂可为臣？",
}

local U = require "packages/utility/utility"

buchen:addEffect(U.GeneralAppeared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasShownSkill(buchen.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data.who
      if to ~= player and not to.dead and not to:isNude() then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = buchen.name,
      prompt = "#buchen-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = room.current,
      flag = "he",
      skill_name = buchen.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, buchen.name, nil, false, player)
  end,
})

return buchen
