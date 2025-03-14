local zhanding = fk.CreateSkill{
  name = "zhanding",
}

Fk:loadTranslationTable{
  ["zhanding"] = "斩钉",
  [":zhanding"] = "你可以将任意张牌当【杀】使用并令你手牌上限-1，若此【杀】：造成伤害，你将手牌数调整至手牌上限；未造成伤害，此【杀】不计入次数。",

  ["#zhanding"] = "斩钉：你可以将任意张牌当【杀】使用并令你手牌上限-1",

  ["$zhanding1"] = "汝颈硬，比之金铁何如？",
  ["$zhanding2"] = "魍魉鼠辈，速速系颈伏首！",
}

zhanding:addEffect("viewas", {
  pattern = "slash",
  prompt = "#zhanding",
  handly_pile = true,
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = zhanding.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    if player:getMaxCards() > 0 then
      local room = player.room
      room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    end
  end,
  after_use = function (self, player, use)
    if not player.dead then
      if use.damageDealt then
        local n = player:getHandcardNum() - player:getMaxCards()
        if n < 0 then
          player:drawCards(-n, zhanding.name)
        elseif n > 0 then
          player.room:askToDiscard(player, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = zhanding.name,
            cancelable = false,
          })
        end
      elseif not use.extraUse then
        use.extraUse = true
        player:addCardUseHistory(use.card.trueName, -1)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

return zhanding
