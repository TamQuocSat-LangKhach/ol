local zhiba_active = fk.CreateSkill {
  name = "ol_ex__zhiba_active&",
}

Fk:loadTranslationTable {
  ["ol_ex__zhiba_active&"] = "制霸",
  [":ol_ex__zhiba_active&"] = "出牌阶段限一次，你可与孙策拼点（其可拒绝此次拼点），若你没赢，其获得两张拼点牌。",

  ["#ol_ex__zhiba_active&"] = "制霸：你可与孙策拼点（其可拒绝此次拼点），若你没赢，其获得两张拼点牌",
}

zhiba_active:addEffect("active", {
  anim_type = "support",
  prompt = "#ol_ex__zhiba_active&",
  can_use = function(self, player)
    if player.kingdom ~= "wu" or player:isKongcheng() then return false end
    local targetRecorded = player:getTableMark("ol_ex__zhiba_sources-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ol_ex__zhiba") and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      local target = to_select
      return target:hasSkill("ol_ex__zhiba") and Self:canPindian(target) and
      not table.contains(Self:getTableMark("ol_ex__zhiba_sources-phase"), to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, "ol_ex__zhiba_sources-phase", target.id)
    if room:askToChoice(target, { choices = {"ol_ex__zhiba_accept", "ol_ex__zhiba_refuse"}, skill_name = zhiba_active.name, prompt = "#ol_ex__zhiba-ask:" .. player.id}) == "ol_ex__zhiba_accept" then
      player:pindian({target}, zhiba_active.name)
    end
  end,
})

return zhiba_active