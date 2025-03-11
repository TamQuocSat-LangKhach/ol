local jianhe = fk.CreateSkill{
  name = "jianhe",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；"..
  "2.受到你造成的1点雷电伤害。",

  ["#jianhe"] = "剑合：重铸至少两张同名牌，令一名角色选择重铸等量同类别牌或对其造成1点雷电伤害",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张%arg2，否则受到1点雷电伤害",

  ["$jianhe1"] = "身临朝阙，腰悬太阿。",
  ["$jianhe2"] = "位登三事，当配龙泉。",
}

jianhe:addEffect("active", {
  anim_type = "offensive",
  prompt = "#jianhe",
  min_card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    else
      if Fk:getCardById(selected[1]).type == Card.TypeEquip then
        return Fk:getCardById(to_select).type == Card.TypeEquip
      end
      return Fk:getCardById(to_select).trueName == Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("jianhe-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "jianhe-phase", target.id)
    local n, type = #effect.cards, Fk:getCardById(effect.cards[1]):getTypeString()
    room:recastCard(effect.cards, player, jianhe.name)
    if target.dead then return end
    if #target:getCardIds("he") >= n then
      local cards = room:askToCards(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = jianhe.name,
        pattern = ".|.|.|.|.|"..type,
        prompt = "#jianhe-choose:::"..n..":"..type,
        cancelable = true,
      })
      if #cards > 0 then
        room:recastCard(cards, target, jianhe.name)
        return
      end
    end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = jianhe.name,
    }
  end
})

return jianhe
