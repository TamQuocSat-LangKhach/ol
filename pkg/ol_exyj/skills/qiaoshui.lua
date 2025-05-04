local qiaoshui = fk.CreateSkill{
  name = "ol_ex__qiaoshui",
}

Fk:loadTranslationTable{
  ["ol_ex__qiaoshui"] = "巧说",
  [":ol_ex__qiaoshui"] = "出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以增加或取消一个目标（无距离限制）；"..
  "若你没赢，此技能失效且你不能使用锦囊牌直到回合结束。",

  ["#ol_ex__qiaoshui"] = "巧说：与一名角色拼点，若赢，下一张基本牌或普通锦囊牌可增加或取消一个目标",
  ["#ol_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加/减少一个目标",
  ["@@ol_ex__qiaoshui-turn"] = "巧说",
}

qiaoshui:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__qiaoshui",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    local pindian = player:pindian({to}, qiaoshui.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 1)
    else
      room:invalidateSkill(player, qiaoshui.name, "-turn")
      room:setPlayerMark(player, "ol_ex__qiaoshui_fail-turn", 1)
    end
  end,
})

qiaoshui:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_ex__qiaoshui-turn") > 0 and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 0)
    local targets = data:getExtraTargets({bypass_distances = true})
    if #data.tos > 1 then
      table.insertTable(targets, data.tos)
    end
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__qiaoshui-choose:::"..data.card:toLogString(),
      skill_name = qiaoshui.name,
      cancelable = true,
      target_tip_name = "addandcanceltarget_tip",
    })
    if #tos == 0 then return end
    if table.contains(data.tos, tos[1]) then
      table.removeOne(data.tos, tos[1])
      room:sendLog{
        type = "#RemoveTargetsBySkill",
        from = target.id,
        to = tos,
        arg = qiaoshui.name,
        arg2 = data.card:toLogString(),
      }
    else
      table.insert(data.tos, tos[1])
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = target.id,
        to = table.map(tos, Util.IdMapper),
        arg = qiaoshui.name,
        arg2 = data.card:toLogString(),
      }
    end
  end,
})

qiaoshui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("ol_ex__qiaoshui_fail-turn") > 0 and card and card.type == Card.TypeTrick
  end,
})

return qiaoshui