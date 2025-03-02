local ziqu = fk.CreateSkill{
  name = "ziqu",
}

Fk:loadTranslationTable{
  ["ziqu"] = "资取",
  [":ziqu"] = "每名角色限一次，当你对其他角色造成伤害时，你可以防止此伤害，令其交给你一张点数最大的牌。",

  ["#ziqu-invoke"] = "资取：是否防止对 %dest 造成的伤害，改为令其交给你一张点数最大的牌？",
  ["#ziqu-give"] = "资取：你需要交给 %src 一张点数最大的牌",

  ["$ziqu1"] = "兵马已动，尔等速将粮草缴来。",
  ["$ziqu2"] = "留财不留命，留命不留财。",
}

ziqu:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ziqu.name) and
      not table.contains(player:getTableMark(ziqu.name), data.to.id)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = ziqu.name,
      prompt = "#ziqu-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:addTableMark(player, ziqu.name, data.to.id)
    if not data.to:isNude() then
      local ids = table.filter(data.to:getCardIds("he"), function(id)
        return table.every(data.to:getCardIds("he"), function(id2)
          return Fk:getCardById(id).number >= Fk:getCardById(id2).number
        end)
      end)
      local card = room:askToCards(data.to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = ziqu.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#ziqu-give:"..player.id,
        cancelable = false,
      })
      room:obtainCard(player, card, true, fk.ReasonGive, data.to, ziqu.name)
    end
  end,
})

return ziqu
