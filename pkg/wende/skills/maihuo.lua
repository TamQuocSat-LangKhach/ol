local maihuo = fk.CreateSkill{
  name = "maihuo",
}

Fk:loadTranslationTable{
  ["maihuo"] = "埋祸",
  [":maihuo"] = "当你成为其他角色不因本技能使用的非转化【杀】的唯一目标后，若其没有“祸”，你可以令此【杀】对你无效并将之置于其武将牌上，"..
  "称为“祸”，其下个出牌阶段开始时对你使用此【杀】（有合法性限制和次数限制，不合法则移去之）。当你对其他角色造成伤害后，你移去其“祸”。",

  ["yangzhi_huo"] = "祸",
  ["#maihuo-invoke"] = "埋祸：令 %dest 对你使用的%arg无效并将之置为“祸”，延迟到其下个出牌阶段对你使用",

  ["$maihuo1"] = "祸根未决，转而滋蔓。",
  ["$maihuo2"] = "无德之亲，终为祸根。",
}

maihuo:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  derived_piles = "yangzhi_huo",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(maihuo.name) and
      data:isOnlyTarget(player) and data.card.trueName == "slash" and not data.card:isVirtual() and
      data.from ~= player and not data.from.dead and
      #data.from:getPile("yangzhi_huo") == 0 and
      not (data.extra_data and data.extra_data.maihuo)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = maihuo.name,
      prompt = "#maihuo-invoke::"..data.from.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
    if room:getCardArea(data.card) == Card.Processing then
      room:setPlayerMark(data.from, maihuo.name, {player.id, data.card.id})
      data.from:addToPile("yangzhi_huo", data.card, true, maihuo.name)
    end
  end,
})
maihuo:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Play and #target:getPile("yangzhi_huo") > 0 and
      target:getMark(maihuo.name) ~= 0 and target:getMark(maihuo.name)[1] == player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "maihuo", 0)
    if not player.dead and
      target:canUseTo(Fk:getCardById(target:getPile("yangzhi_huo")[1]), player, {bypass_distances = false, bypass_times = false}) then
      room:useCard({
        from = target,
        tos = {player},
        card = Fk:getCardById(target:getPile("yangzhi_huo")[1]),
        extraUse = false,
        extra_data = {
          maihuo = true,
        },
      })
    else
      room:moveCardTo(target:getPile("yangzhi_huo"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, maihuo.name, nil, true, target)
    end
  end,
})
maihuo:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(maihuo.name) and
      data.to ~= player and not data.to.dead and #data.to:getPile("yangzhi_huo") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.to, maihuo.name, 0)
    room:moveCardTo(data.to:getPile("yangzhi_huo"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, maihuo.name, nil, true, player)
  end,
})

return maihuo
