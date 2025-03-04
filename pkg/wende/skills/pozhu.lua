local pozhu = fk.CreateSkill{
  name = "pozhu",
}

Fk:loadTranslationTable{
  ["pozhu"] = "破竹",
  [":pozhu"] = "出牌阶段，你可以将一张手牌当【出其不意】使用，若此【出其不意】未造成伤害，此技能无效直到回合结束。",

  ["#pozhu"] = "破竹：你可以将一张手牌当【出其不意】使用",

  ["$pozhu1"] = "攻其不备，摧枯拉朽！",
  ["$pozhu2"] = "势如破竹，铁锁横江亦难挡！",
}

pozhu:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#pozhu",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("unexpectation")
    c.skillName = pozhu.name
    c:addSubcard(cards[1])
    return c
  end,
  after_use = function (self, player, use)
    if not player.dead and not use.damageDealt then
      player.room:invalidateSkill(player, pozhu.name, "-turn")
    end
  end,
})

return pozhu
