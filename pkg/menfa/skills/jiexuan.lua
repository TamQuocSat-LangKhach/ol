local jiexuan = fk.CreateSkill{
  name = "jiexuan",
  tags = { Skill.Switch, Skill.Limited },
}

Fk:loadTranslationTable{
  ["jiexuan"] = "解悬",
  [":jiexuan"] = "转换技，限定技，阳：你可以将一张红色牌当【顺手牵羊】使用；阴：你可以将一张黑色牌当【过河拆桥】使用。",

  ["#jiexuan-yang"] = "解悬：你可以将一张红色牌当【顺手牵羊】使用",
  ["#jiexuan-yin"] = "解悬：你可以将一张黑色牌当【过河拆桥】使用",

  ["$jiexuan1"] = "允不才，愿以天下苍生为己任。",
  ["$jiexuan2"] = "愿以此躯为膳，饲天下以太平。",
}

jiexuan:addEffect("viewas", {
  anim_type = "switch",
  prompt = function(self, player)
    return "#jiexuan-"..player:getSwitchSkillState(jiexuan.name, false, true)
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if player:getSwitchSkillState(jiexuan.name, false) == fk.SwitchYang then
        return Fk:getCardById(to_select).color == Card.Red
      else
        return Fk:getCardById(to_select).color == Card.Black
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card
    if player:getSwitchSkillState(jiexuan.name, false) == fk.SwitchYang then
      card = Fk:cloneCard("snatch")
    else
      card = Fk:cloneCard("dismantlement")
    end
    card.skillName = jiexuan.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(jiexuan.name, Player.HistoryGame) == 0
  end,
})

return jiexuan
