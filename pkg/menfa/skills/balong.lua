local balong = fk.CreateSkill{
  name = "balong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",

  ["$balong1"] = "八龙之蜿蜿，云旗之委蛇。",
  ["$balong2"] = "穆王乘八牡，天地恣遨游。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(balong.name) and not player:isKongcheng() and
      player:usedSkillTimes(balong.name, Player.HistoryTurn) == 0 then
      local hp_change_event = player.room.logic:getCurrentEvent():searchEvents(GameEvent.ChangeHp, 1, Util.TrueFunc)
      if hp_change_event == nil then return false end
      local dat = hp_change_event[1].data
      if dat.extra_data and dat.extra_data.balong then
        local types = { Card.TypeBasic, Card.TypeEquip, Card.TypeTrick }
        local num = {0, 0, 0}
        for i = 1, 3, 1 do
          num[i] = #table.filter(player:getCardIds("h"), function(id)
            return Fk:getCardById(id).type == types[i]
          end)
        end
        return num[3] > num[1] and num[3] > num[2]
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(player:getCardIds("h"))
    local n = #player.room.alive_players - player:getHandcardNum()
    if n > 0 and not player.dead then
      player:drawCards(n, balong.name)
    end
  end,
}

balong:addEffect(fk.Damaged, spec)
balong:addEffect(fk.HpLost, spec)
balong:addEffect(fk.HpRecover, spec)
balong:addEffect(fk.MaxHpChanged, spec)

balong:addEffect(fk.HpChanged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(balong.name, true) and
      player:usedSkillTimes(balong.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function (self, event, target, player, data)
    local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local changehp_events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
      return e.data.who == player
    end, Player.HistoryTurn)
    if #changehp_events == 1 and changehp_events[1].data == data then
      data.extra_data = data.extra_data or {}
      data.extra_data.balong = true
    end
  end,
})

return balong
