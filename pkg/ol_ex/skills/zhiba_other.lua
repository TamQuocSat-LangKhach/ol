local zhiba_active = fk.CreateSkill {
  name = "ol_ex__zhiba_active&",
}

Fk:loadTranslationTable {
  ["ol_ex__zhiba_active&"] = "制霸",
  [":ol_ex__zhiba_active&"] = "出牌阶段限一次，你可与孙策拼点（其可拒绝此次拼点），若你没赢，其获得两张拼点牌。",

  ["#ol_ex__zhiba_active&"] = "制霸：你可与孙策拼点（其可拒绝此次拼点），若你没赢，其获得两张拼点牌",
  ["ol_ex__zhiba_accept"] = "接受拼点",
  ["ol_ex__zhiba_refuse"] = "拒绝拼点",
}

zhiba_active:addEffect("active", {
  anim_type = "support",
  prompt = "#ol_ex__zhiba_active&",
  can_use = function(self, player)
    return player.kingdom ~= "wu" and not player:isKongcheng() and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p:hasSkill("ol_ex__zhiba") and
          not table.contains(player:getTableMark("ol_ex__zhiba_sources-phase"), p.id)
      end)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:hasSkill("ol_ex__zhiba") and
      player:canPindian(to_select) and
      not table.contains(player:getTableMark("ol_ex__zhiba_sources-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, "ol_ex__zhiba_sources-phase", target.id)
    if room:askToChoice(target, {
      choices = {"ol_ex__zhiba_accept", "ol_ex__zhiba_refuse"},
      skill_name = zhiba_active.name,
      prompt = "#ol_ex__zhiba-ask:" .. player.id,
    }) == "ol_ex__zhiba_accept" then
      player:pindian({target}, zhiba_active.name)
    end
  end,
})

return zhiba_active