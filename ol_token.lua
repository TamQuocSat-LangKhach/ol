
local extension = Package:new("ol_token", Package.CardPack)
Fk:loadTranslationTable{
  ["ol_token"] = "OL衍生牌",
}

local sevenStarsSwordSkill = fk.CreateTriggerSkill{
  name = "#seven_stars_sword_skill",
  attached_equip = "seven_stars_sword",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    if not room:getPlayerById(data.to):isWounded() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.qinggangNullified = data.extra_data.qinggangNullified or {}
    data.extra_data.qinggangNullified[tostring(data.to)] = (data.extra_data.qinggangNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qinggangNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.qinggangNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.qinggangNullified = nil
  end,
}
Fk:addSkill(sevenStarsSwordSkill)
local sevenStarsSword = fk.CreateWeapon{
  name = "&seven_stars_sword",
  suit = Card.Spade,
  number = 6,
  attack_range = 2,
  equip_skill = sevenStarsSwordSkill,
}
extension:addCard(sevenStarsSword)
Fk:loadTranslationTable{
  ["seven_stars_sword"] = "七宝刀",
  ["#seven_stars_sword_skill"] = "七宝刀",
  [":seven_stars_sword"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。",
}

local honeyTrapSkill = fk.CreateActiveSkill{
  name = "honey_trap_skill",
  target_num = 1,
  target_filter = function(self, to_select)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and not target:isKongcheng() and target.gender == General.Male
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    local female = table.filter(room:getAlivePlayers(), function(p) return p.gender == General.Female end)
    if #female > 0 then
      for _, p in ipairs(female) do
        if target:isKongcheng() or target.dead then break end
        local id = room:askForCardChosen(p, target, "h", self.name)
        room:obtainCard(p, id, false, fk.ReasonPrey)
        if not player.dead and not p:isKongcheng() then
          local card = room:askForCard(p, 1, 1, false, self.name, false, ".", "#honey_trap-card:"..player.id)
          room:obtainCard(player, card[1], false, fk.ReasonGive)
        end
      end
    end
    local from, to = player, target
    if #player.player_cards[Player.Hand] == #target.player_cards[Player.Hand] then
      return
    elseif #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
      from, to = target, player
    end
    room:damage({
      from = from,
      to = to,
      card = effect.card,
      damage = 1,
      skillName = self.name
    })
  end,
}
local honeyTrap = fk.CreateTrickCard{
  name = "&honey_trap",
  skill = honeyTrapSkill,
  is_damage_card = true,
}
extension:addCard(honeyTrap)
Fk:loadTranslationTable{
  ["honey_trap"] = "美人计",
  ["honey_trap_skill"] = "美人计",
  [":honey_trap"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他男性角色<br/><b>效果</b>：所有女性角色获得目标角色的一张手牌"..
  "并交给你一张手牌，然后你与目标中手牌数少的角色对手牌数多的角色造成1点伤害。",
  ["#honey_trap-card"] = "美人计：请将一张手牌交给 %src",
}

local daggarInSmileSkill = fk.CreateActiveSkill{
  name = "daggar_in_smile_skill",
  target_num = 1,
  target_filter = function(self, to_select)
    return to_select ~= Self.id
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if target:isWounded() then
      target:drawCards(math.min(target:getLostHp(), 5), self.name)
    end
    room:damage({
      from = player,
      to = target,
      card = effect.card,
      damage = 1,
      skillName = self.name
    })
  end,
}
local daggarInSmile = fk.CreateTrickCard{
  name = "&daggar_in_smile",
  skill = daggarInSmileSkill,
  is_damage_card = true,
}
extension:addCard(daggarInSmile)
Fk:loadTranslationTable{
  ["daggar_in_smile"] = "笑里藏刀",
  ["daggar_in_smile_skill"] = "笑里藏刀",
  [":daggar_in_smile"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：目标角色摸X张牌（X为其已损失体力值"..
  "且至多为5），然后你对其造成1点伤害。",
}

return extension
