local qiangxi = fk.CreateSkill{
  name = "ol_ex__qiangxi",
}

Fk:loadTranslationTable{
  ["ol_ex__qiangxi"] = "强袭",
  [":ol_ex__qiangxi"] = "出牌阶段限两次，你可以受到1点普通伤害或弃置一张武器牌，选择一名于此阶段内未选择过的其他角色，你对其造成1点普通伤害。",

  ["#ol_ex__qiangxi"] = "强袭：弃置一张武器牌，或不选受到1点伤害，对目标造成1点伤害",

  ["$ol_ex__qiangxi1"] = "典韦来也，谁敢一战！",
  ["$ol_ex__qiangxi2"] = "双戟青罡，百死无生！",
}

qiangxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_ex__qiangxi",
  max_phase_use_time = 2,
  max_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("ol_ex__qiangxi_targets-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, "ol_ex__qiangxi_targets-phase", target.id)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, qiangxi.name, player, player)
    else
      room:damage{
        to = player,
        damage = 1,
        skillName = qiangxi.name,
      }
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = qiangxi.name,
      }
    end
  end,
})

return qiangxi