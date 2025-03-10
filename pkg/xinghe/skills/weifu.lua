local weifu = fk.CreateSkill{
  name = "weifu",
}

Fk:loadTranslationTable{
  ["weifu"] = "威抚",
  [":weifu"] = "出牌阶段，你可以弃置一张牌并判定，你本回合下次使用与判定牌类别相同的牌无距离限制且可以多指定一个目标；若弃置牌"..
  "与判定牌类别相同，你摸一张牌。",

  ["#weifu"] = "威抚：弃一张牌并判定，你使用下一张判定结果类别的牌无距离限制且目标+1",
  ["@weifu-turn"] = "威抚",
  ["#weifu-invoke"] = "威抚：你可以为%arg额外指定至多%arg2个目标",

  ["$weifu1"] = "蛮人畏威，当束甲抚之。",
  ["$weifu2"] = "以威为抚，可定万世之太平。",
}

local updataWeifuMark = function (player)
  local room = player.room
  local mark = {}
  local basic = player:getMark("weifu_basic-turn")
  if basic > 0 then
    table.insert(mark, Fk:translate("basic_char")..basic)
  end
  local trick = player:getMark("weifu_trick-turn")
  if trick > 0 then
    table.insert(mark, Fk:translate("trick_char")..trick)
  end
  room:setPlayerMark(player, "@weifu-turn", #mark > 0 and mark or 0)
end

weifu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#weifu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, weifu.name, player, player)
    local judge = {
      who = player,
      reason = weifu.name,
      pattern = ".",
    }
    room:judge(judge)
    if player.dead then return end
    if judge.card.type ~= Card.TypeEquip then
      room:addPlayerMark(player, "weifu_"..judge.card:getTypeString().."-turn")
      updataWeifuMark(player)
    end
    if judge.card.type == Fk:getCardById(effect.cards[1]).type then
      player:drawCards(1, weifu.name)
    end
  end,
})
weifu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("weifu_"..data.card:getTypeString().."-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("weifu_"..data.card:getTypeString().."-turn")
    room:setPlayerMark(player, "weifu_"..data.card:getTypeString().."-turn", 0)
    updataWeifuMark(player)
    if (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      #data:getExtraTargets({bypass_distances = true}) > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = data:getExtraTargets({bypass_distances = true}),
        skill_name = weifu.name,
        prompt = "#weifu-invoke:::"..data.card:toLogString()..":"..n,
        cancelable = true,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          data:addTarget(p)
        end
      end
    end
  end,
})
weifu:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("weifu_"..card:getTypeString().."-turn") > 0
  end,
})

return weifu
