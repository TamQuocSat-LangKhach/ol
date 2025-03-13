local lunzhan = fk.CreateSkill{
  name = "lunzhan",
}

Fk:loadTranslationTable{
  ["lunzhan"] = "轮战",
  [":lunzhan"] = "出牌阶段，你可以将任意张牌当一张【决斗】使用（至多为5，不能与本回合以此法使用张数相同），若对唯一目标角色造成了伤害，"..
  "你可以摸X张牌，然后你本回合不能再以此法对其使用【决斗】（X为本回合你使用牌指定其为目标的次数）。",

  ["#lunzhan"] = "轮战：将任意张牌当【决斗】使用（至多5张，本回合张数不能重复）",
  ["#lunzhan-draw"] = "轮战：是否摸%arg张牌，本回合不能再对 %dest 发动“轮战”？",

  ["$lunzhan1"] = "",
  ["$lunzhan2"] = "",
}

lunzhan:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#lunzhan",
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected < 5
  end,
  view_as = function (self, player, cards)
    if #cards == 0 or #cards > 5 or table.contains(player:getTableMark("lunzhan-turn"), #cards) then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = lunzhan.name
    return card
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, "lunzhan-turn", #use.card.subcards)
  end,
  after_use = function (self, player, UseCardData)
    if player.dead or not UseCardData.damageDealt then return end
    if #UseCardData.tos == 1 and UseCardData.damageDealt[UseCardData.tos[1]] then
      local room = player.room
      local to = UseCardData.tos[1]
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        local use = e.data
        return use.from == player and table.contains(use.tos, to)
      end, Player.HistoryTurn)
      if room:askToSkillInvoke(player, {
        skill_name = lunzhan.name,
        prompt = "#lunzhan-draw::"..to.id..":"..n,
      }) then
        room:addTableMark(player, "lunzhan_prohibit-turn", to.id)
        player:drawCards(n, lunzhan.name)
      end
    end
  end,
  enabled_at_play = function (self, player)
    return #player:getTableMark("lunzhan-turn") < 5
  end,
})
lunzhan:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and table.contains(card.skillNames, lunzhan.name) and
      table.contains(from:getTableMark("lunzhan_prohibit-turn"), to.id)
  end,
})

return lunzhan
