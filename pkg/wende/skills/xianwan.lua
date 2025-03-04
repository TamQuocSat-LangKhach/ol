local xianwan = fk.CreateSkill{
  name = "xianwan",
}

Fk:loadTranslationTable{
  ["xianwan"] = "娴婉",
  [":xianwan"] = "当你需使用【闪】时，你可以横置，视为使用一张【闪】；当你需使用【杀】时，你可以重置，视为使用一张【杀】。",

  ["#xianwan-slash"] = "娴婉：你可以重置，视为使用一张【杀】",
  ["#xianwan-jink"] = "娴婉：你可以横置，视为使用一张【闪】",

  ["$xianwan1"] = "婉而从物，不竞不争。",
  ["$xianwan2"] = "娴婉恭谨，重贤加礼。",
}

xianwan:addEffect("viewas", {
  pattern = "slash,jink",
  anim_type = "defensive",
  prompt = function(self, player)
    if player.chained then
      return "#xianwan-slash"
    else
      return "#xianwan-jink"
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card
    if player.chained then
      card = Fk:cloneCard("slash")
    else
      card = Fk:cloneCard("jink")
    end
    card.skillName = xianwan.name
    return card
  end,
  before_use = function(self, player, use)
    player:setChainState(not player.chained)
  end,
  enabled_at_response = function(self, player, response)
    if not response then
      if player.chained then
        return #player:getViewAsCardNames(xianwan.name, {"slash"}) > 0
      else
        return #player:getViewAsCardNames(xianwan.name, {"jink"}) > 0
      end
    end
  end,
})

return xianwan
