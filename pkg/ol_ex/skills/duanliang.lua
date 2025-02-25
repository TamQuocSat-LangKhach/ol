local this = fk.CreateSkill{
  name = "ol_ex__duanliang",
}

this:addEffect('viewas', {
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#ol_ex__duanliang-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
})

this:addEffect(fk.Damage, {
  anim_type = "control",
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ol_ex__duanliang_damage-turn", data.damage)
  end,
})

this:addEffect('targetmod', {
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(this.name) and skill.name == "supply_shortage_skill" and
    player:getMark("ol_ex__duanliang_damage-turn") == 0
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__duanliang"] = "断粮",
  [":ol_ex__duanliang"] = "①你可将一张不为锦囊牌的黑色牌转化为【兵粮寸断】使用。"..
  "②若你于当前回合内未造成过伤害，你使用【兵粮寸断】无距离关系的限制。",
  
  ["#ol_ex__duanliang-viewas"] = "你是否想要发动“断粮”，将一张黑色牌当【兵粮寸断】使用？",
  
  ["$ol_ex__duanliang1"] = "兵行无常，计行断粮。",
  ["$ol_ex__duanliang2"] = "焚其粮营，断其粮道。",
}

return this
