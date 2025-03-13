local shicai = fk.CreateSkill{
  name = "guandu__shicai",
}

Fk:loadTranslationTable{
  ["guandu__shicai"] = "恃才",
  [":guandu__shicai"] = "出牌阶段，牌堆顶牌对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶牌，若本回合此牌仍在你手中，你不能发动此技能。",

  ["#guandu__shicai"] = "恃才：弃一张牌，获得牌堆顶牌，若“恃才”牌仍在你手中则不能发动<br>（点击“恃才”技能按钮可以观看牌堆顶牌）",
  ["@@guandu__shicai-inhand-turn"] = "恃才",

  ["$guandu__shicai1"] = "主公不听吾之言，实乃障目不见泰山也！",
  ["$guandu__shicai2"] = "遣轻骑以袭许都，大事可成。",
}

shicai:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#guandu__shicai",
  card_num = 1,
  target_num = 0,
  expand_pile = function()
    return {Fk:currentRoom().draw_pile[1]}
  end,
  card_filter = function (self, player, to_select, selected)
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@guandu__shicai-inhand-turn") > 0
    end) then
      return false
    else
      return #selected == 0 and not player:prohibitDiscard(to_select) and table.contains(player:getCardIds("he"), to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, shicai.name, player, player)
    if player.dead then return end
    room:moveCardTo(room.draw_pile[1], Card.PlayerHand, player, fk.ReasonJustMove, shicai.name, nil, false, player,
      "@@guandu__shicai-inhand-turn")
  end,
})

return shicai
