local longdan = fk.CreateSkill {
  name = "ol_ex__longdan",
}

Fk:loadTranslationTable{
  ["ol_ex__longdan"] = "龙胆",
  [":ol_ex__longdan"] = "你可以将一张【杀】当【闪】、【闪】当【杀】、【酒】当【桃】、【桃】当【酒】使用或打出。",

  ["#ol_ex__longdan-viewas"] = "龙胆：将一张【杀】当【闪】、【闪】当【杀】、【酒】当【桃】、【桃】当【酒】使用或打出",

  ["$ol_ex__longdan1"] = "哼，有胆就先接我两招！",
  ["$ol_ex__longdan2"] = "龙游沙场，胆战群雄！",
}

longdan:addEffect("viewas", {
  pattern = "slash,jink,peach,analeptic",
  prompt = "#ol_ex__longdan-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    elseif _c.name == "peach" then
      c = Fk:cloneCard("analeptic")
    elseif _c.name == "analeptic" then
      c = Fk:cloneCard("peach")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and player:canUse(c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    elseif _c.name == "peach" then
      c = Fk:cloneCard("analeptic")
    elseif _c.name == "analeptic" then
      c = Fk:cloneCard("peach")
    end
    c.skillName = longdan.name
    c:addSubcard(cards[1])
    return c
  end,
})

longdan:addAI(nil, "vs_skill")

return longdan
