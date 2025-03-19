local quandao = fk.CreateSkill{
  name = "quandao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["quandao"] = "权道",
  [":quandao"] = "锁定技，当你使用【杀】或普通锦囊牌时，你将手牌中两者数量弃至相同并摸一张牌。",

  ["$quandao1"] = "继策掌权，符令吴会。",
  ["$quandao2"] = "以权驭衡，谋定天下。",
}

quandao:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quandao.name) and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isKongcheng() then
      local slash = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      local trick = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):isCommonTrick()
      end)
      if #slash ~= #trick then
        local n = #slash - #trick
        if n > 0 then
          room:askToDiscard(player, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = quandao.name,
            cancelable = false,
            pattern = "slash",
          })
        else
          room:askToDiscard(player, {
            min_num = -n,
            max_num = -n,
            include_equip = false,
            skill_name = quandao.name,
            cancelable = false,
            pattern = tostring(Exppattern{ id = trick }),
          })
        end
      end
    end
    if not player.dead then
      player:drawCards(1, quandao.name)
    end
  end,
})

return quandao
