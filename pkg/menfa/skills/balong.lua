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

balong:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(balong.name) and not player:isKongcheng() and
      player:usedSkillTimes(balong.name, Player.HistoryTurn) == 0 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local types = { Card.TypeBasic, Card.TypeEquip, Card.TypeTrick }
      local num = {0, 0, 0}
      for i = 1, 3, 1 do
        num[i] = #table.filter(player:getCardIds("h"), function(id)
          return Fk:getCardById(id).type == types[i]
        end)
      end
      if num[3] <= num[1] or num[3] <= num[2] then return false end
      local changehp_events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who == player
      end, Player.HistoryTurn)
      return #changehp_events == 1 and changehp_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(player:getCardIds("h"))
    if player:getHandcardNum() < #player.room.alive_players and not player.dead then
      player:drawCards(#player.room.alive_players - player:getHandcardNum(), balong.name)
    end
  end,
})

return balong
