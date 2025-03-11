local hongde = fk.CreateSkill{
  name = "hongde",
}

Fk:loadTranslationTable{
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",

  ["#hongde-choose"] = "弘德：你可以令一名其他角色摸一张牌",

  ["$hongde1"] = "江南重义，东吴尚德。",
  ["$hongde2"] = "德无单行，福必双至。",
}

hongde:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(hongde.name) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and
          ((move.from == player and move.to ~= player) or
          (move.to == player and move.toArea == Card.PlayerHand)) then
          return #player.room:getOtherPlayers(player, false) > 0
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = hongde.name,
      prompt = "#hongde-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, hongde.name)
  end,
})

return hongde
