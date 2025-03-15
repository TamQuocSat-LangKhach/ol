local xiongzhi = fk.CreateSkill{
  name = "xiongzhi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongzhi"] = "雄志",
  [":xiongzhi"] = "限定技，出牌阶段，你可以展示牌堆顶牌并使用之，重复此流程直到牌堆顶牌不能被使用。",

  ["#xiongzhi"] = "雄志：你可以重复展示牌堆顶牌并使用之（有次数限制）",
  ["#xiongzhi-use"] = "雄志：你可以使用这张牌",

  ["$xiongzhi1"] = "鹰扬千里，明察秋毫。",
  ["$xiongzhi2"] = "鸢飞戾天，目入百川。",
}

xiongzhi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xiongzhi",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xiongzhi.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    while not player.dead do
      local cards = room:getNCards(1)
      room:turnOverCardsFromDrawPile(player, cards, xiongzhi.name)
      if not room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = xiongzhi.name,
        prompt = "#xiongzhi-use",
        extra_data = {
          bypass_times = false,
          extraUse = false,
          expand_pile = cards,
        }
      }) then
        room:moveCards({
          ids = cards,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = xiongzhi.name,
        })
        break
      end
    end
  end,
})

return xiongzhi
