local fanghun = fk.CreateSkill{
  name = "fanghun",
}

Fk:loadTranslationTable{
  ["fanghun"] = "芳魂",
  [":fanghun"] = "当你使用【杀】造成伤害后或受到【杀】造成的伤害后，你获得等于伤害值的“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",

  ["@meiying"] = "梅影",
  ["#fanghun"] = "芳魂：你可以移去1个“梅影”标记，发动〖龙胆〗并摸一张牌",

  ["$fanghun1"] = "万花凋落尽，一梅独傲霜。",
  ["$fanghun2"] = "暗香疏影处，凌风踏雪来！",
}

fanghun:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@meiying", 0)
end)

fanghun:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#fanghun",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    if card.trueName == "slash" then
      return #player:getViewAsCardNames(fanghun.name, {"jink"}) > 0
    elseif card.name == "jink" then
      return #player:getViewAsCardNames(fanghun.name, {"slash"}) > 0
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, fanghun.name)
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying", 1)
  end,
  after_use = function (self, player, use)
    if not player.dead then
      player:drawCards(1, fanghun.name)
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@meiying") > 0
  end,
})

local fanghun_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fanghun.name) and data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", data.damage)
  end,
}

fanghun:addEffect(fk.Damage, fanghun_spec)
fanghun:addEffect(fk.Damaged, fanghun_spec)

return fanghun
