local manwang = fk.CreateSkill{
  name = "manwang",
  dynamic_desc = function(self, player)
    local choices = {}
    for i = 1, 4 - player:getMark(self.name), 1 do
      table.insert(choices, Fk:translate("manwang_inner"..i))
    end
    return "manwang_inner:"..table.concat(choices, "；")
  end,
}

Fk:loadTranslationTable{
  ["manwang"] = "蛮王",
  [":manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",

  [":manwang_inner"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：{1}。",
  ["manwang_inner1"] = "1.获得〖叛侵〗",
  ["manwang_inner2"] = "2.摸一张牌",
  ["manwang_inner3"] = "3.回复1点体力",
  ["manwang_inner4"] = "4.摸两张牌并失去〖叛侵〗",

  ["#manwang"] = "蛮王：弃置任意张牌，依次执行〖蛮王〗的前等量项（剩余 %arg 项）",

  ["$manwang1"] = "不服王命，纵兵凶战危，也应以血相偿！",
  ["$manwang2"] = "夷汉所服，据南中诸郡，当以蛮王为号！",
}

local function doManwang(player, i)
  local room = player.room
  if i == 1 then
    room:handleAddLoseSkills(player, "panqin")
  elseif i == 2 then
    player:drawCards(1, "manwang")
  elseif i == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "manwang",
      }
    end
  elseif i == 4 then
    player:drawCards(2, "manwang")
    room:handleAddLoseSkills(player, "-panqin")
  end
end

manwang:addEffect("active", {
  anim_type = "special",
  prompt = function (self, player)
    return "#manwang:::"..(4 - player:getMark(manwang.name))
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, manwang.name, player, player)
    for i = 1, #effect.cards, 1 do
      if i > 4 or player:getMark(manwang.name) > (4 - i) or player.dead then return end
      doManwang(player, i)
    end
  end,
})

return manwang
