
local fuhun = fk.CreateSkill {
  name = "ol_ex__fuhun",
}

Fk:loadTranslationTable{
  ["ol_ex__fuhun"] = "父魂",
  [":ol_ex__fuhun"] = "你可以将两张牌当【杀】使用或打出，你使用的转化【杀】只能被颜色相同的手牌响应；当你于出牌阶段内使用【杀】"..
  "造成伤害后，本回合获得〖武圣〗和〖咆哮〗。",

  ["#ol_ex__fuhun"] = "父魂：将两张牌当【杀】使用或打出",

  --["$ol_ex__fuhun1"] = "",
  --["$ol_ex__fuhun2"] = "",
}

fuhun:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ol_ex__fuhun",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = fuhun.name
    c:addSubcards(cards)
    return c
  end,
})

fuhun:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuhun.name) and
      data.card and data.card.trueName == "slash" and
      player.phase == Player.Play
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, skill_name in ipairs({"ex__wusheng", "ex__paoxiao"}) do
      if not player:hasSkill(skill_name, true) then
        table.insert(skills, skill_name)
      end
    end
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(skills, "|"))
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
      end)
    end
  end,
})

fuhun:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(fuhun.name) and data.eventData and data.eventData.from == player and
      data.eventData.card.trueName == "slash" and data.eventData.card:isVirtual() and
      #data.eventData.card.subcards > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("ol_ex__fuhun", data.eventData.card.color)
    else
      room:setBanner("ol_ex__fuhun", 0)
    end
  end,
})

fuhun:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local color = Fk:currentRoom():getBanner("ol_ex__fuhun")
    if card and color then
      local ids = Card:getIdList(card)
      return #ids == 0 or card.color ~= color or card.color == Card.NoColor or
        table.find(ids, function (id)
          return not table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

return fuhun
