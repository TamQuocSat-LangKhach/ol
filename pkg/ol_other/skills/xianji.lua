local xianji = fk.CreateSkill{
  name = "qin__xianji",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["qin__xianji"] = "献姬",
  [":qin__xianji"] = "限定技，出牌阶段，你可以弃置所有牌和“期”标记并减1点体力上限，然后发动〖大期〗的回复效果和摸牌效果。",

  ["#qin__xianji"] = "献姬：弃置所有牌和“期”标记并减1点体力上限，发动“大期”的回复和摸牌效果！",

  ["$qin__xianji"] = "妾身能得垂爱，是妾身福气。",
}

xianji:addEffect("active", {
  anim_type = "support",
  prompt = "#qin__xianji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xianji.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:throwAllCards("he", xianji.name)
    if player.dead then return end
    room:setPlayerMark(player, "@qin__daqi", 0)
    room:changeMaxHp(player, -1)
    if player.dead then return end
    Fk.skills["qin__daqi"]:use(nil, player, player, nil)
  end,
})

return xianji
