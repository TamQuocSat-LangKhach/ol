local zishu = fk.CreateSkill{
  name = "shengxiao_zishu",
}

Fk:loadTranslationTable{
  ["shengxiao_zishu"] = "子鼠",
  [":shengxiao_zishu"] = "出牌阶段限一次，你可以获得手牌数大于你的其他角色一张手牌，你可以重复此流程直到你的手牌数为全场最多。",

  ["#shengxiao_zishu"] = "子鼠：你可以获得手牌数大于你的角色一张手牌",
  ["#shengxiao_zishu-prey"] = "子鼠：获得 %dest 一张手牌",
}

zishu:addEffect("active", {
  anim_type = "control",
  prompt = "#shengxiao_zishu",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
    to_select:getHandcardNum() > player:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = zishu.name,
      prompt = "#shengxiao_zishu-prey::"..target.id,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zishu.name, nil, false, player)
    while not player.dead and
      table.find(room:getOtherPlayers(player), function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end) do
      if not room:askToUseActiveSkill(player, {
        skill_name = zishu.name,
        prompt = "#shengxiao_zishu",
        cancelable = true,
        no_indicate = false,
      }) then
        return
      end
    end
  end,
})

return zishu
