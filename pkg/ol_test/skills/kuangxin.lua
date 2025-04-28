local kuangxin = fk.CreateSkill{
  name = "kuangxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuangxin"] = "狂信",
  [":kuangxin"] = "锁定技，出牌阶段开始时，你失去任意点体力，摸等量的牌并展示已损失体力值+1张手牌。",

  ["#kuangxin-choice"] = "狂信：失去任意点体力，摸等量的牌，展示已损失体力值+1张手牌",
  ["#kuangxin-show"] = "狂信：请展示%arg张手牌",

  ["$kuangxin1"] = "",
  ["$kuangxin2"] = "",
}

kuangxin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(kuangxin.name) and player.phase == Player.Play and
      player.hp > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = room:askToNumber(player, {
      skill_name = kuangxin.name,
      prompt = "#kuangxin-choice",
      min = 1,
      max = player.hp,
    })
    room:loseHp(player, n, kuangxin.name)
    if player.dead then return end
    player:drawCards(n, kuangxin.name)
    if player.dead then return end
    if player:isKongcheng() then
      room:setPlayerMark(player, kuangxin.name, 0)
      return
    end
    local cards = player:getCardIds("h")
    n = player:getLostHp() + 1
    if #cards > n then
      cards = room:askToCards(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = kuangxin.name,
        prompt = "#kuangxin-show:::"..n,
        cancelable = false,
      })
    end
    room:setPlayerMark(player, kuangxin.name, #cards)
    player:showCards(cards)
  end,
})

return kuangxin
