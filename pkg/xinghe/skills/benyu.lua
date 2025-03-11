local benyu = fk.CreateSkill{
  name = "benyu",
}

Fk:loadTranslationTable{
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；"..
  "否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",

  ["#benyu-discard"] = "贲育：你可以弃置至少%arg张手牌，对 %dest 造成1点伤害",
  ["#benyu-draw"] = "贲育：你可以将手牌摸至 %arg 张",

  ["$benyu1"] = "曹公智略乃上天所授！",
  ["$benyu2"] = "天下大乱，群雄并起，必有命事。",
}

benyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benyu.name) and data.from and not data.from.dead and
      (player:getHandcardNum() > data.from:getHandcardNum() or
      player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > data.from:getHandcardNum() then
      local num = data.from:getHandcardNum() + 1
      local cards = room:askToDiscard(player, {
        min_num = num,
        max_num = 999,
        include_equip = false,
        skill_name = benyu.name,
        prompt = "#benyu-discard::"..data.from.id..":"..num,
        cancelable = true,
        skip = true,
      })
      if #cards >= num then
        event:setCostData(self, {tos = {data.from}, cards = cards})
        return true
      end
    elseif room:askToSkillInvoke(player, {
      skill_name = benyu.name,
      prompt = "#benyu-draw:::"..math.min(data.from:getHandcardNum(), 5),
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).cards then
      room:throwCard(event:getCostData(self).cards, benyu.name, player, player)
      if not data.from.dead then
        room:damage{
          from = player,
          to = data.from,
          damage = 1,
          skillName = benyu.name,
        }
      end
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum(), benyu.name)
    end
  end,
})

return benyu
