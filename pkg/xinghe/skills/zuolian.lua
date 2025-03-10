local zuolian = fk.CreateSkill{
  name = "zuolian",
}

Fk:loadTranslationTable{
  ["zuolian"] = "佐练",
  [":zuolian"] = "出牌阶段限一次，你可以选择至多X名有手牌的角色（X为你的体力值），这些角色各随机展示一张手牌，"..
  "你可以令这些角色各将展示的牌与弃牌堆或牌堆中的火【杀】或雷【杀】交换。",

  ["#zuolian"] = "佐练：选择至多%arg名角色，可以将这些角色的随机手牌换为属性【杀】",
  ["#zuolian-exchange"] = "佐练：是否将展示的牌与火【杀】或雷【杀】交换（优先检索火【杀】）",

  ["$zuolian1"] = "有我操练水军，曹公大可放心！",
  ["$zuolian2"] = "好！儿郎们很有精神！",
}

zuolian:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  min_target_num = 1,
  prompt = function(self, player)
    return "#zuolian:::"..player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zuolian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < player.hp and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local showMap = {}
    for _, p in ipairs(effect.tos) do
      if not (p.dead or p:isKongcheng()) then
        local id = table.random(p:getCardIds("h"))
        p:showCards(id)
        table.insert(showMap, {p, id})
      end
    end
    if not room:askToSkillInvoke(player, {
      skill_name = zuolian.name,
      prompt = "#zuolian-exchange",
    }) then return end
    for _, dat in ipairs(showMap) do
      local p = dat[1]
      if not p.dead and table.contains(p:getCardIds("h"), dat[2]) then
        local area_name = "Top"
        local slashs = room:getCardsFromPileByRule(".|.|.|.|fire__slash", 1, "discardPile")
        if #slashs == 0 then
          slashs = room:getCardsFromPileByRule(".|.|.|.|fire__slash")
          if #slashs == 0 then
            slashs = room:getCardsFromPileByRule(".|.|.|.|thunder__slash", 1, "discardPile")
            if #slashs == 0 then
              slashs = room:getCardsFromPileByRule(".|.|.|.|thunder__slash")
              if #slashs == 0 then
                break
              end
            else
              area_name = "discardPile"
            end
          end
        else
          area_name = "discardPile"
        end
        room:swapCardsWithPile(p, {dat[2]}, slashs, zuolian.name, area_name, true, player)
      end
    end
  end,
})

return zuolian
