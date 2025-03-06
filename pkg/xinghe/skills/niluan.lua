local niluan = fk.CreateSkill{
  name = "ol__niluan",
}

Fk:loadTranslationTable{
  ["ol__niluan"] = "逆乱",
  [":ol__niluan"] = "体力值大于你的角色的结束阶段，若其此回合使用过【杀】，你可以将一张黑色牌当【杀】对其使用。",

  ["#ol__niluan-invoke"] = "逆乱：你可以将一张黑色牌当【杀】对 %dest 使用",

  ["$ol__niluan1"] = "西凉铁骑，随我逆袭！",
  ["$ol__niluan2"] = "吃我一记回马枪！",
}

niluan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(niluan.name) and target.phase == Player.Finish and
      target.hp > player.hp and not target.dead and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == target and use.card.trueName == "slash"
      end, Player.HistoryTurn) > 0 and
      player:canUseTo(Fk:cloneCard("slash"), target, {bypass_distances = true, bypass_times = true}) and
      not (player:isNude() and #player:getHandlyIds() == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ol__niluan_viewas",
      prompt = "#ol__niluan-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = {target.id},
      },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", event:getCostData(self).cards, player, target, niluan.name, true)
  end,
})

return niluan
