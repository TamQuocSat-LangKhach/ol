local shandao = fk.CreateSkill{
  name = "shandao",
}

Fk:loadTranslationTable{
  ["shandao"] = "善刀",
  [":shandao"] = "出牌阶段限一次，你可以将任意名角色的各一张牌置于牌堆顶，视为对这些角色使用一张【五谷丰登】，"..
  "然后视为对除这些角色外的其他角色使用一张【万箭齐发】。",

  ["#shandao"] = "善刀：将任意名角色各一张牌置于牌堆顶，视为对这些角色使用【五谷丰登】，然后视为对其余角色使用【万箭齐发】",

  ["$shandao1"] = "君子藏器，待天时而动。",
  ["$shandao2"] = "善刀而藏之，可解充栋之牛。",
}

shandao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#shandao",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shandao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    local tos = {}
    for _, target in ipairs(targets) do
      table.insert(tos, target)
      if not (target.dead or target:isNude()) then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = shandao.name,
        })
        room:moveCards({
          ids = {card},
          from = target,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = shandao.name,
        })
        if player.dead then return end
      end
    end
    tos = table.filter(tos, function (p)
      return not p.dead
    end)
    room:useVirtualCard("amazing_grace", nil, player, tos, shandao.name)
    if player.dead then return end
    local others = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(targets, p)
    end)
    room:useVirtualCard("archery_attack", nil, player, others, shandao.name)
  end,
})

return shandao
