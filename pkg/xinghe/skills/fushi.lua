local fushi = fk.CreateSkill{
  name = "fushi",
}

Fk:loadTranslationTable{
  ["fushi"] = "缚豕",
  [":fushi"] = "当一名角色使用【杀】后，若你至其距离小于2，你将此【杀】置于你的武将牌上。"..
  "你可以重铸任意张“缚豕”牌，视为使用一张具有以下等量项效果的【杀】：1.目标数+1；2.对一个目标造成的伤害-1；3.对一个目标造成的伤害+1。"..
  "若你选择的选项相邻且目标均相邻，此【杀】不计入限制的次数。",

  ["#fushi"] = "缚豕：重铸任意张“缚豕”牌，视为使用一张附加等量效果的【杀】",
  ["fushi1"] = "目标+1",
  ["fushi2"] = "对一个目标伤害-1",
  ["fushi3"] = "对一个目标伤害+1",
  ["#fushi1-choose"] = "缚豕：为此【杀】增加一个目标",
  ["#fushi2-choose"] = "缚豕：选择一个目标，此【杀】对其伤害-1",
  ["#fushi3-choose"] = "缚豕：选择一个目标，此【杀】对其伤害+1",

  ["$fushi1"] = "缚豕待宰，要让阿瞒吃个肚儿溜圆。",
  ["$fushi2"] = "今儿个呀，咱们吃油汪汪的猪肉！",
}

fushi:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#fushi",
  expand_pile = "fushi",
  derived_piles = "fushi",
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getPile(fushi.name), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = fushi.name
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:recastCard(self.cost_data, player, fushi.name)
    if player.dead then return end
    local choices = {"fushi1", "fushi2", "fushi3"}
    local n = math.min(#self.cost_data, 3)
    local chosen = room:askToChoices(player, {
      choices = choices,
      min_num = n,
      max_num = n,
      skill_name = fushi.name,
      cancelable = false,
    })
    if table.contains(chosen, "fushi1") then
      local tos = table.filter(room:getOtherPlayers(player, false), function (p)
        return not table.contains(use.tos, p) and player:canUseTo(use.card, p, use.extra_data)
      end)
      if #tos > 0 then
        tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = tos,
          skill_name = fushi.name,
          prompt = "#fushi1-choose",
          cancelable = false,
          no_indicate = true,
        })
        table.insert(use.tos, tos[1])
        room:sortByAction(use.tos)
      end
    end
    use.extra_data = use.extra_data or {}
    if table.contains(chosen, "fushi2") then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = use.tos,
        skill_name = fushi.name,
        prompt = "#fushi2-choose",
        cancelable = false,
        no_indicate = true,
      })
      use.extra_data.fushi2 = tos[1]
    end
    if table.contains(chosen, "fushi3") then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = use.tos,
        skill_name = fushi.name,
        prompt = "#fushi3-choose",
        cancelable = false,
        no_indicate = true,
      })
      use.extra_data.fushi3 = tos[1]
    end
    if #chosen > 1 and table.contains(chosen, "fushi2") and #use.tos > 1 then
      local yes = true
      for i = 1, #use.tos - 1, 1 do
        if use.tos[i]:getNextAlive() ~= use.tos[i + 1] then
          yes = false
        end
      end
      if yes then
        use.extraUse = true
      end
    end
  end,
  enabled_at_play = function(self, player)
    return #player:getPile(fushi.name) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getPile(fushi.name) > 0
  end,
})
fushi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fushi.name) and data.card.trueName == "slash" and player:distanceTo(target) <= 1 and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile(fushi.name, data.card, true, fushi.name)
  end,
})
fushi:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, fushi.name) then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      return e and e.data.extra_data and (e.data.extra_data.fushi2 or e.data.extra_data.fushi3)
    end
  end,
  on_use = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if not e then return end
    local use = e.data
    if use.extra_data.fushi3 == data.to then
      data:changeDamage(1)
    end
    if use.extra_data.fushi2 == data.to then
      data:changeDamage(-1)
    end
  end,
})

return fushi
