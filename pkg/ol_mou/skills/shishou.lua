local shishou = fk.CreateSkill{
  name = "shishouy",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["shishouy"] = "士首",
  [":shishouy"] = "主公技，当其他群势力角色失去装备区里的牌后，若你的装备区里没有武器牌，其可以将【思召剑】置入你的装备区。",

  ["#shishouy-invoke"] = "士首：是否令 %src 将【思召剑】置入其装备区？",

  ["$shishouy1"] = "今执牛耳，当为天下之先。",
  ["$shishouy2"] = "士者不徒手而战，况其首乎。",
  ["$shishouy3"] = "吾居群士之首，可配剑履否？",
  ["$shishouy4"] = "剑来！",
  ["$shishouy5"] = "今秉七尺之躯，不负三尺之剑！",
  ["$shishouy6"] = "拔剑四顾，诸位识得我袁本初？",
}

local U = require "packages/utility/utility"

local shishouyTriggerable = function (player)
  if #player:getEquipments(Card.SubtypeWeapon) > 0 then return false end
  local room = player.room
  local id = U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards")[1]
  return table.contains({Card.PlayerEquip, Card.DrawPile, Card.DiscardPile, Card.Void}, room:getCardArea(id))
end

shishou:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(shishou.name) and shishouyTriggerable(player)) then return false end
    local targets = {}
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
    end
    for _, to in ipairs(targets) do
      if not to.dead and to ~= player and to.kingdom == "qun" then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = table.simpleClone(event:getCostData(self).tos)
    local room = player.room
    room:sortByAction(targets)
    for _, to in ipairs(targets) do
      if not to.dead and to ~= player and to.kingdom == "qun" then
        event:setCostData(self, {extra_data = to})
        self:doCost(event, nil, player, data)
      end
      if not (player:hasSkill(shishou.name) and shishouyTriggerable(player)) then break end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).extra_data
    if room:askToSkillInvoke(to, {
      skill_name = shishou.name,
      prompt = "#shishouy-invoke:"..player.id,
    }) then
      room:doIndicate(to, {player})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardIntoEquip(player, U.prepareDeriveCards(room, {{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), shishou.name)
  end,
})

return shishou
