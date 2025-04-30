local chengxiang = fk.CreateSkill{
  name = "ol_ex__chengxiang",
}

Fk:loadTranslationTable{
  ["ol_ex__chengxiang"] = "称象",
  [":ol_ex__chengxiang"] = "当你受到1点伤害后，你可以亮出牌堆顶四张牌，获得其中任意张数量点数之和不大于13的牌，将其余的牌置入弃牌堆。"..
  "若获得的牌点数之和恰好为13，你下次发动〖称象〗时多亮出一张牌。",

  ["$ol_ex__chengxiang1"] = "谁知道称大象需要几步？",
  ["$ol_ex__chengxiang2"] = "象虽大，然可并舟称之。",
}

chengxiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 4
    if player:getMark(chengxiang.name) > 0 then
      num = 5
      room:setPlayerMark(player, chengxiang.name, 0)
    end
    local cards = room:getNCards(num)
    room:turnOverCardsFromDrawPile(player, cards, chengxiang.name)
    local get = room:askToArrangeCards(player, {
      skill_name = chengxiang.name,
      card_map = {cards},
      prompt = "#chengxiang-choose",
      free_arrange = false,
      box_size = 0,
      max_limit = {num, num},
      min_limit = {0, 1},
      poxi_type = "chengxiang",
      default_choice = {{}, {cards[1]}},
    })[2]
    local n = 0
    for _, id in ipairs(get) do
      n = n + Fk:getCardById(id).number
    end
    if n == 13 then
      room:setPlayerMark(player, chengxiang.name, 1)
    end
    room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, chengxiang.name, nil, true, player)
    room:cleanProcessingArea(cards, chengxiang.name)
  end
})

return chengxiang