
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
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and not target:isKongcheng() and target.gender == General.Male
  end,
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
    if player:getHandcardNum() == target:getHandcardNum() then
      return
    elseif player:getHandcardNum() > target:getHandcardNum() then
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
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= Self.id
  end,
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

local jadeCombSkill = fk.CreateTriggerSkill{
  name = "#jade_comb_skill",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = data.damage
    local pattern
    if player:getEquipment(Card.SubtypeTreasure) then
      pattern = ".|.|.|.|.|.|^"..tostring(player:getEquipment(Card.SubtypeTreasure))
    else
      pattern = "."
    end
    local cards = room:askForDiscard(player, x, x, true, self.name, true, pattern, "#jade_comb-invoke:::"..tostring(x), true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke("zhuangshu", 3)
    player.room:throwCard(self.cost_data, "jade_comb", player, player)
    return true
  end,
}
Fk:addSkill(jadeCombSkill)
local jadeComb = fk.CreateTreasure{
  name = "&jade_comb",
  suit = Card.Spade,
  number = 12,
  equip_skill = jadeCombSkill,
}
extension:addCard(jadeComb)

Fk:loadTranslationTable{
  ["jade_comb"] = "琼梳",
  ["#jade_comb_skill"] = "琼梳",
  [":jade_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：当你受到伤害时，你可以弃置X张牌（X为伤害值），防止此伤害。",

  ["#jade_comb-invoke"] = "是否使用 琼梳，弃置%arg张牌来防止此伤害",
}

local rhinoCombSkill = fk.CreateTriggerSkill{
  name = "#rhino_comb_skill",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Judge
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"rhino_comb_judge", "Cancel"}
    if not player.skipped_phases[Player.Discard] then
      table.insert(choices, 2, "rhino_comb_discard")
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke("zhuangshu", 4)
    if self.cost_data == "rhino_comb_judge" then
      player:skip(Player.Judge)
      return true
    elseif self.cost_data == "rhino_comb_discard" then
      player:skip(Player.Discard)
    end
  end,
}
Fk:addSkill(rhinoCombSkill)
local rhinoComb = fk.CreateTreasure{
  name = "&rhino_comb",
  suit = Card.Club,
  number = 12,
  equip_skill = rhinoCombSkill,
}
extension:addCard(rhinoComb)

Fk:loadTranslationTable{
  ["rhino_comb"] = "犀梳",
  ["#rhino_comb_skill"] = "犀梳",
  [":rhino_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：判定阶段开始前，你可选择：1.跳过此阶段；2.跳过此回合的弃牌阶段。",

  ["rhino_comb_judge"] = "跳过判定阶段",
  ["rhino_comb_discard"] = "跳过弃牌阶段",
}

local goldenCombSkill = fk.CreateTriggerSkill{
  name = "#golden_comb_skill",
  mute = true,
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
    and player:getHandcardNum() < math.min(player:getMaxCards(), 5)
  end,
  on_use = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke("zhuangshu", 5)
    local x = math.min(player:getMaxCards(), 5) - player:getHandcardNum()
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
Fk:addSkill(goldenCombSkill)
local goldenComb = fk.CreateTreasure{
  name = "&golden_comb",
  suit = Card.Heart,
  number = 12,
  equip_skill = goldenCombSkill,
}
extension:addCard(goldenComb)

Fk:loadTranslationTable{
  ["golden_comb"] = "金梳",
  ["#golden_comb_skill"] = "金梳",
  [":golden_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：锁定技，出牌阶段结束时，你将手牌补至X张（X为你的手牌上限且至多为5）。",
}

local shangyangReformSkill = fk.CreateActiveSkill{
  name = "shangyang_reform_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= Self.id
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    room:damage({
      from = player,
      to = target,
      card = effect.card,
      damage = math.random(2),
      skillName = self.name
    })
  end,
}
local shangyangReformTrigger = fk.CreateTriggerSkill{
  name = "shangyang_reform_trigger",
  mute = true,
  global = true,
  priority = 0, -- game rule
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.damage and data.damage.card and data.damage.card.name == "shangyang_reform" and
      data.damage.from and not data.damage.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = data.damage.from,
      reason = "shangyang_reform_skill",
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      data.extra_data = data.extra_data or {}
      data.extra_data.shangyangReform = true
    end
  end,
}
local shangyangReformProhibit = fk.CreateProhibitSkill{
  name = "#shangyang_reform_prohibit",
  global = true,
  prohibit_use = function(self, player, card)
    if card and card.name == "peach" and not player.dying then
      if RoomInstance and RoomInstance.logic:getCurrentEvent().event == GameEvent.Dying then
        local data = RoomInstance.logic:getCurrentEvent().data[1]
        return data and data.extra_data and data.extra_data.shangyangReform
      end
    end
  end,
}
Fk:addSkill(shangyangReformTrigger)
Fk:addSkill(shangyangReformProhibit)
local shangyangReform = fk.CreateTrickCard{
  name = "&shangyang_reform",
  skill = shangyangReformSkill,
  is_damage_card = true,
}
extension:addCards({
  shangyangReform:clone(Card.Spade, 5),
  shangyangReform:clone(Card.Spade, 7),
  shangyangReform:clone(Card.Spade, 9),
})
Fk:loadTranslationTable{
  ["shangyang_reform"] = "商鞅变法",
  ["shangyang_reform_skill"] = "商鞅变法",
  [":shangyang_reform"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：你对目标角色造成随机1~2点伤害，"..
  "若其因此伤害进入濒死状态，你判定，若为黑色，除其以外的角色不能对其使用【桃】直到濒死结算结束。",
}

local qinDragonSwordSkill = fk.CreateTriggerSkill{
  name = "#qin_dragon_sword_skill",
  attached_equip = "qin_dragon_sword",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card:isCommonTrick() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.prohibitedCardNames = {"nullification"}
  end,
}
Fk:addSkill(qinDragonSwordSkill)
local qinDragonSword = fk.CreateWeapon{
  name = "&qin_dragon_sword",
  suit = Card.Heart,
  number = 2,
  attack_range = 4,
  equip_skill = qinDragonSwordSkill,
}
extension:addCard(qinDragonSword)
Fk:loadTranslationTable{
  ["qin_dragon_sword"] = "真龙长剑",
  ["#qin_dragon_sword_skill"] = "真龙长剑",
  [":qin_dragon_sword"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：锁定技，你每回合使用的第一张普通锦囊牌不能被【无懈可击】响应。",
}

local qinSealSkill = fk.CreateTriggerSkill{
  name = "#qin_seal_skill",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "qin_seal_viewas", "#qin_seal-choice", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk.skills["qin_seal_viewas"]:viewAs(self.cost_data.cards)
    player.room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
local qinSealViewAs = fk.CreateViewAsSkill{
  name = "qin_seal_viewas",
  interaction = function()
    return UI.ComboBox {choices = {"savage_assault", "archery_attack", "god_salvation", "amazing_grace"}}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "#qin_seal_skill"
    return card
  end,
}
Fk:addSkill(qinSealSkill)
Fk:addSkill(qinSealViewAs)
local qinSeal = fk.CreateTreasure{
  name = "&qin_seal",
  suit = Card.Heart,
  number = 7,
  equip_skill = qinSealSkill,
}
extension:addCard(qinSeal)
Fk:loadTranslationTable{
  ["qin_seal"] = "传国玉玺",
  ["#qin_seal_skill"] = "传国玉玺",
  [":qin_seal"] = "装备牌·宝物<br/><b>宝物技能</b>：出牌阶段开始时，你可以视为使用【南蛮入侵】、【万箭齐发】、【桃园结义】或【五谷丰登】。",
  ["qin_seal_viewas"] = "传国玉玺",
  ["#qin_seal-choice"] = "传国玉玺：你可以视为使用一种锦囊",
}

return extension
