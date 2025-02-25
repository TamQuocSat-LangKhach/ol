local this = fk.CreateSkill{
  name = "ol_ex__qiangxi",
}

this:addEffect('active', {
  anim_type = "offensive",
  prompt = "#ol_ex__qiangxi",
  max_phase_use_time = 2,
  max_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local qiangxiRecorded = Self:getTableMark("ol_ex__qiangxi_targets-phase")
      return not table.contains(qiangxiRecorded, to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, "ol_ex__qiangxi_targets-phase", target.id)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, this.name, player)
    else
      room:damage{
        to = player,
        damage = 1,
        skillName = this.name,
      }
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = this.name,
      }
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__qiangxi"] = "强袭",
  [":ol_ex__qiangxi"] = "出牌阶段限两次，你可受到1点普通伤害或弃置一张武器牌并选择一名于此阶段内未选择过的其他角色，你对其造成1点普通伤害。",
  
  ["#ol_ex__qiangxi"] = "选择一张武器牌或不选（受到1点伤害），并选择强袭的目标",

  ["$ol_ex__qiangxi1"] = "典韦来也，谁敢一战！",
  ["$ol_ex__qiangxi2"] = "双戟青罡，百死无生！",
}

return this