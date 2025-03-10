local pijing = fk.CreateSkill{
  name = "pijingl",
}

Fk:loadTranslationTable{
  ["pijingl"] = "披荆",
  [":pijingl"] = "每回合限一次，当你使用【杀】或普通锦囊牌指定目标时，"..
  "你可以为此牌增加或取消目标合计至多X名其他角色，并随机交给你一张牌（X为你已损失的体力值且至少为1），"..
  "这些角色下次使用基本牌或普通锦囊牌指定唯一目标时，其可以指定你为额外目标或摸一张牌。",

  ["#pijingl-choose"] = "披荆：为此%arg增加或取消至多%arg2个目标，并随机交给你一张牌",
  ["@@pijingl"] = "披荆",
  ["pijingl_target"] = "令%dest也成为此%arg目标",
  ["#pijingl-choice"] = "披荆：你可以摸一张牌，或令 %dest 也成为%arg的目标",

  ["$pijingl1"] = "今青锋在手，必破敌军于域外。",
  ["$pijingl2"] = "荆楚多锦绣，安能丧于小儿之手！",
}

pijing:addLoseEffect(function (self, player, is_death)
  if is_death and player:getMark(pijing.name) ~= 0 then
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if table.contains(player:getMark(pijing.name), p.id) and
        not table.find(room:getOtherPlayers(player, false), function (q)
          return table.contains(q:getMark(pijing.name), p.id)
        end) then
        room:setPlayerMark(p, "@@pijingl", 0)
      end
    end
  end
end)

pijing:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pijing.name) and data.firstTarget and
      player:usedSkillTimes(pijing.name, Player.HistoryTurn) == 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(1, player:getLostHp())
    local targets = table.simpleClone(data.use.tos)
    table.insertTable(targets, data:getExtraTargets())
    table.removeOne(targets, player)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#pijingl-choose:::"..data.card:toLogString()..":"..n,
      skill_name = pijing.name,
      cancelable = true,
      extra_data = table.map(data.use.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      room:addTableMarkIfNeed(player, pijing.name, p.id)
      room:setPlayerMark(p, "@@pijingl", 1)
      if table.contains(data.use.tos, p) then
        data:cancelTarget(p)
      else
        data:addTarget(p)
      end
    end
    for _, p in ipairs(tos) do
      if not (p.dead or p:isNude()) then
        room:obtainCard(player, table.random(p:getCardIds("he")), false, fk.ReasonGive, p, pijing.name)
        if player.dead then break end
      end
    end
  end,
})
pijing:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and
      table.contains(player:getTableMark(pijing.name), target.id) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #data.tos == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, pijing.name, target.id)
    if not table.find(room.alive_players, function (p)
      return table.contains(p:getTableMark(pijing.name), target.id)
    end) then
      room:setPlayerMark(target, "@@pijingl", 0)
    end
    local choices = {"draw1", "Cancel"}
    if table.contains(data:getExtraTargets({bypass_distances = true}), player) then
      table.insert(choices, 1, "pijingl_target::"..player.id..":"..data.card:toLogString())
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = pijing.name,
      prompt = "#pijingl-choice::"..player.id..":"..data.card:toLogString(),
    })
    if choice == "draw1" then
      target:drawCards(1, pijing.name)
    else
      room:doIndicate(target, {player})
      data:addTarget(player)
    end
  end,
})

return pijing
