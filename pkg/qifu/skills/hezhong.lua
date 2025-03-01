local hezhong = fk.CreateSkill{
  name = "hezhong",
}

Fk:loadTranslationTable{
  ["hezhong"] = "和衷",
  [":hezhong"] = "每回合各限一次，当你的手牌数变为1后，你可以展示手牌并摸一张牌，然后本回合你使用的下一张点数大于/小于此牌点数的普通锦囊牌"..
  "额外结算一次。",

  ["#hezhong-choice"] = "和衷：令你本回合点数大于或小于%arg的普通锦囊多结算一次",
  ["hezhong1"] = "大于",
  ["hezhong2"] = "小于",
  ["@hezhong-turn"] = "和衷",

  ["$hezhong1"] = "家和而万事兴，国亦如是。",
  ["$hezhong2"] = "你我同殿为臣，理当协力齐心。",
}

---@param player ServerPlayer
local updataHezhongMark = function (player)
  local room = player.room
  local mark = {}
  if player:getMark("hezhong1-turn") > 0 and player:getMark("hezhong1used-turn") == 0 then
    table.insert(mark, ">"..player:getMark("hezhong1-turn"))
  end
  if player:getMark("hezhong2-turn") > 0 and player:getMark("hezhong2used-turn") == 0 then
    table.insert(mark, "&lt;"..player:getMark("hezhong2-turn"))
  end
  room:setPlayerMark(player, "@hezhong-turn", #mark > 0 and table.concat(mark, ";") or 0)
end

hezhong:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(hezhong.name) and player:getHandcardNum() == 1 and
      player:usedSkillTimes(hezhong.name, Player.HistoryTurn) < 2 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:getCardById(player:getCardIds("h")[1]).number
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    player:drawCards(1, hezhong.name)
    if player.dead then return end
    local choices = {}
    for i = 1, 2, 1 do
      if player:getMark("hezhong"..i.."-turn") == 0 then
        table.insert(choices, "hezhong"..i)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = hezhong.name,
      prompt = "#hezhong-choice:::"..n,
      all_choices = {"hezhong1", "hezhong2"},
    })
    room:setPlayerMark(player, choice.."-turn", n)
    updataHezhongMark(player)
  end,
})
hezhong:addEffect(fk.CardUsing, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #data.tos > 0 and data.card:isCommonTrick() and data.card.number > 0 and
      ((player:getMark("hezhong1-turn") > 0 and
        player:getMark("hezhong1used-turn") == 0 and
        data.card.number > player:getMark("hezhong1-turn")) or
      (player:getMark("hezhong2-turn") > 0 and
        player:getMark("hezhong2used-turn") == 0 and
        data.card.number < player:getMark("hezhong2-turn")))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if player:getMark("hezhong1-turn") > 0 and player:getMark("hezhong1used-turn") == 0 and
      data.card.number > player:getMark("hezhong1-turn") then
      n = n + 1
      room:setPlayerMark(player, "hezhong1used-turn", 1)
    end
    if player:getMark("hezhong2-turn") > 0 and player:getMark("hezhong2used-turn") == 0 and
      data.card.number < player:getMark("hezhong2-turn") then
      n = n + 1
      room:setPlayerMark(player, "hezhong2used-turn", 1)
    end
    updataHezhongMark(player)
    data.additionalEffect = (data.additionalEffect or 0) + n
  end,
})

return hezhong
