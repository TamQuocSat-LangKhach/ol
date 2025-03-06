local mouzhu = fk.CreateSkill{
  name = "ol__mouzhu",
}

Fk:loadTranslationTable{
  ["ol__mouzhu"] = "谋诛",
  [":ol__mouzhu"] = "出牌阶段限一次，你可以令一名其他角色交给你一张手牌，若其手牌数小于你，其视为使用一张【杀】或【决斗】。",

  ["#ol__mouzhu"] = "谋诛：令一名角色交给你一张手牌，然后若其手牌数小于你，其视为使用【杀】或【决斗】",
  ["#ol__mouzhu-give"] = "谋诛：请交给 %src 一张手牌",
  ["#ol__mouzhu-use"] = "谋诛：视为使用一张【杀】或【决斗】",

  ["$ol__mouzhu1"] = "天下之乱，皆宦官所为！",
  ["$ol__mouzhu2"] = "宦官当道，当杀之以清君侧！",
}

mouzhu:addEffect("active", {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(mouzhu.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = mouzhu.name,
      prompt = "#ol__mouzhu-give:"..player.id,
      cancelable = false,
    })
    room:obtainCard(player, card, false, fk.ReasonGive, target, mouzhu.name)
    if not target.dead and player:getHandcardNum() > target:getHandcardNum() and
      #target:getViewAsCardNames(mouzhu.name, {"slash", "duel"}) > 0 then
      room:askToUseVirtualCard(target, {
        name = {"slash", "duel"},
        skill_name = mouzhu.name,
        prompt = "#ol__mouzhu-use",
        cancelable = false,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        }
      })
    end
  end,
})

return mouzhu
