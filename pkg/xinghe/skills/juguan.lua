local juguan = fk.CreateSkill{
  name = "juguan",
}

Fk:loadTranslationTable{
  ["juguan"] = "拒关",
  [":juguan"] = "出牌阶段限一次，你可以将一张手牌当【杀】或【决斗】使用。若受到此牌伤害的角色未在你的下回合开始前对你造成过伤害，"..
  "你的下个摸牌阶段摸牌数+2。",

  ["#juguan"] = "拒关：将一张手牌当【杀】或【决斗】使用",
  ["@@juguan"] = "拒关",

  ["$juguan1"] = "吾欲自立，举兵拒关。",
  ["$juguan2"] = "自立门户，拒关不开。",
}

local U = require "packages/utility/utility"

juguan:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#juguan",
  interaction = U.CardNameBox {choices = {"slash", "duel"}},
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = juguan.name
    c:addSubcard(cards[1])
    return c
  end,
  after_use = function (self, player, use)
    if player.dead or not use.damageDealt then return end
    local room = player.room
    local mark = {}
    for _, p in ipairs(room.players) do
      if use.damageDealt[p] then
        table.insertIfNeed(mark, p.id)
      end
    end
    room:setPlayerMark(player, "@@juguan", mark)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(juguan.name, Player.HistoryPhase) == 0
  end,
})
juguan:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@juguan") ~= 0 and
      data.from and table.contains(player:getMark("@@juguan"), data.from.id)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:removeTableMark(player, "@@juguan", data.from.id)
  end,
})
juguan:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@juguan") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@juguan", 0)
    player.room:addPlayerMark(player, "juguan_draw", 1)
  end,
})
juguan:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("juguan_draw") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + 2 * player:getMark("juguan_draw")
    player.room:setPlayerMark(player, "juguan_draw", 0)
  end,
})

return juguan
