local shidu = fk.CreateSkill{
  name = "shidu",
}

Fk:loadTranslationTable{
  ["shidu"] = "识度",
  [":shidu"] = "出牌阶段限一次，你可以与一名角色拼点，若你赢，你获得其所有手牌，然后你交给其你的一半手牌（向下取整）。",

  ["#shidu"] = "识度：与一名角色拼点，若你赢，你获得其所有手牌并交给其一半的手牌",
  ["#shidu-give"] = "识度：选择%arg张手牌交还给 %dest",

  ["$shidu1"] = "鉴识得体，气度雅涵。",
  ["$shidu2"] = "宽容体谅，宽人益己。",
}

shidu:addEffect("active", {
  anim_type = "control",
  prompt = "#shidu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shidu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, shidu.name)
    if player.dead or target.dead then return end
    if pindian.results[target].winner == player then
      if not target:isKongcheng() then
        room:obtainCard(player, target:getCardIds("h"), false, fk.ReasonPrey)
        if player.dead or target.dead then return end
      end
      if player:getHandcardNum() > 1 then
        local n = player:getHandcardNum() // 2
        local cards = room:askToCards(player, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = shidu.name,
          prompt = "#shidu-give::"..target.id..":"..n,
          cancelable = false,
        })
        room:obtainCard(target, cards, false, fk.ReasonGive, player, shidu.name)
      end
    end
  end,
})

return shidu
