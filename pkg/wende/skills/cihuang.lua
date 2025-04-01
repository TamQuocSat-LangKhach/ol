local cihuang = fk.CreateSkill{
  name = "cihuang",
}

Fk:loadTranslationTable{
  ["cihuang"] = "雌黄",
  [":cihuang"] = "当前回合角色对唯一目标使用的牌被抵消后，你可以将一张牌当一张本轮你未使用过的属性【杀】或单一目标普通锦囊牌对使用者使用"..
  "且此牌不能被响应。",

  ["#cihuang-invoke"] = "雌黄：你可以将一张牌当属性【杀】或单目标锦囊对 %dest 使用",

  ["$cihuang1"] = "腹存经典，口吐雌黄。",
  ["$cihuang2"] = "手把玉麈，胸蕴成篇。",
}

cihuang:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cihuang.name) and player.room.current == target and not target.dead and
      #data.tos == 1 and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("cihuang_all_names") == 0 then
      local all_names = {}
      for _, name in ipairs(Fk:getAllCardNames("bt")) do
        local card = Fk.all_card_types[name]
        if card.type == Card.TypeBasic then
          if card.trueName == "slash" and card.name ~= "slash" then
            table.insert(all_names, name)
          end
        elseif not (card.is_passive or card.multiple_targets) then
          table.insert(all_names, name)
        end
      end
      room:setPlayerMark(player, "cihuang_all_names", all_names)
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "cihuang_viewas",
      prompt = "#cihuang-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = {target.id},
      },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction, extra_data = dat.targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(event:getCostData(self).choice)
    card.skillName = cihuang.name
    card:addSubcards(event:getCostData(self).cards)
    local use = {
      from = player,
      tos = event:getCostData(self).extra_data,
      card = card,
      extraUse = true,
    }
    use.disresponsiveList = table.simpleClone(room.players)
    room:useCard(use)
  end,
})
cihuang:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "cihuang-round", data.card.name)
  end,
})

cihuang:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and (use.card.trueName == "slash" or use.card:isCommonTrick()) then
        table.insertIfNeed(mark, use.card.name)
      end
    end, Player.HistoryRound)
    room:setPlayerMark(player, "cihuang-round", mark)
  end
end)

return cihuang
