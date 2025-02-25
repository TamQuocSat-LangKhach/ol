local U =require("packages.utility.utility")

local this = fk.CreateSkill{
  name = "jianmie",
}

this:addEffect('active', {
  anim_type = "offensive",
  prompt = "#jianmie",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(this.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local result = U.askForJointChoice({player, target}, {"red", "black"}, this.name, "#jianmie-choice", true)
    local cards1 = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getColorString() == result[player.id] and
        not player:prohibitDiscard(id)
    end)
    local cards2 = table.filter(target:getCardIds("h"), function (id)
      return Fk:getCardById(id):getColorString() == result[target.id] and
        not target:prohibitDiscard(id)
    end)
    local moves = {}
    if #cards1 > 0 then
      table.insert(moves, {
        ids = cards1,
        from = player.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player.id,
        skillName = this.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moves, {
        ids = cards2,
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = target.id,
        skillName = this.name,
      })
    end
    room:moveCards(table.unpack(moves))
    local src, to = player, player
    if #cards1 > #cards2 then
      src, to = player, target
    elseif #cards1 < #cards2 then
      src, to = target, player
    end
    if src ~= to and not to.dead then
      room:useVirtualCard("duel", nil, src, to, this.name)
    end
  end,
})

Fk:loadTranslationTable{
  ["jianmie"] = "翦灭",
  [":jianmie"] = "出牌阶段限一次，你可以选择一名其他角色，你与其同时选择一种颜色，弃置所有各自选择颜色的手牌，然后弃置牌数较多的角色视为对"..
  "另一名角色使用【决斗】。",
  ["#jianmie"] = "翦灭：与一名角色同时选择一种颜色的手牌弃置，弃牌数多的角色视为对对方使用【决斗】",
  ["#jianmie-choice"] = "翦灭：选择一种颜色的手牌弃置，弃牌多的角色视为对对方使用【决斗】！",

  ["$jianmie1"] = "莫说是你，天潢贵胄亦可杀得！",
  ["$jianmie2"] = "你我不到黄泉，不复相见！",
}

return this
