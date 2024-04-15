
local extension = Package:new("ol_token", Package.CardPack)
Fk:loadTranslationTable{
  ["ol_token"] = "OL衍生牌",
}

local U = require "packages/utility/utility"


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
  attached_equip = "jade_comb",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
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
    player:broadcastSkillInvoke("zhuangshu", 3)
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
  attached_equip = "rhino_comb",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Judge
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
    player:broadcastSkillInvoke("zhuangshu", 4)
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
  attached_equip = "golden_comb",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
    and player:getHandcardNum() < math.min(player:getMaxCards(), 5)
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("zhuangshu", 5)
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
  target_filter = function (self, to_select, selected, selected_cards, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
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
  on_cost = Util.TrueFunc,
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
    return target == player and player:hasSkill(self) and data.card:isCommonTrick() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.unoffsetableList = table.map(player.room.alive_players, Util.IdMapper)
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
  [":qin_dragon_sword"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：锁定技，你每回合使用的第一张普通锦囊牌不能被抵消。",
}

local qinSealSkill = fk.CreateTriggerSkill{
  name = "#qin_seal_skill",
  attached_equip = "qin_seal",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
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
  card_filter = Util.FalseFunc,
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
-- 彻里吉专属
local grain_cart_skill = fk.CreateTriggerSkill{
  name = "#grain_cart_skill",
  attached_equip = "grain_cart",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("#grain_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#caltrop_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#wheel_cart_skill", Player.HistoryTurn) > 0 then return false end
    return player:hasSkill(self) and table.find(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "grain_cart" end) and player:getHandcardNum() < player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#grain_cart-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "grain_cart" end)
    if #throw > 0 then
      room:throwCard(throw, self.name, player, player)
    end
  end,
}
Fk:addSkill(grain_cart_skill)
local grain_cart = fk.CreateTreasure{
  name = "&grain_cart",
  suit = Card.Heart,
  number = 5,
  equip_skill = grain_cart_skill,
}
extension:addCard(grain_cart)
Fk:loadTranslationTable{
  ["grain_cart"] = "四乘粮舆",
  ["#grain_cart_skill"] = "四乘粮舆",
  [":grain_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：一名角色的回合结束时，若你的手牌数小于体力值，你可以摸两张牌，然后弃置此牌。",
  ["#grain_cart-invoke"] = "四乘粮舆：你可以摸两张牌，然后弃置此牌",
}
local caltrop_cart_skill = fk.CreateTriggerSkill{
  name = "#caltrop_cart_skill",
  attached_equip = "caltrop_cart",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("#grain_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#caltrop_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#wheel_cart_skill", Player.HistoryTurn) > 0 then return false end
    if player:hasSkill(self) and table.find(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "caltrop_cart" end) and target ~= player then
      return #U.getActualDamageEvents(player.room, 1, function(e) return e.data[1].from == target end) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#caltrop_cart-invoke:"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForDiscard(target, 2, 2, true, self.name, false)
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "caltrop_cart" end)
    if #throw > 0 then
      room:throwCard(throw, self.name, player, player)
    end
  end,
}
Fk:addSkill(caltrop_cart_skill)
local caltrop_cart = fk.CreateTreasure{
  name = "&caltrop_cart",
  suit = Card.Club,
  number = 5,
  equip_skill = caltrop_cart_skill,
}
extension:addCard(caltrop_cart)
Fk:loadTranslationTable{
  ["caltrop_cart"] = "铁蒺玄舆",
  ["#caltrop_cart_skill"] = "铁蒺玄舆",
  [":caltrop_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：其他角色的回合结束时，若本回合未造成过伤害，你可以令其弃置两张牌，然后弃置此牌。",
  ["#caltrop_cart-invoke"] = "铁蒺玄舆：你可以令%src弃置两张牌，然后弃置此牌",
}
local wheel_cart_skill = fk.CreateTriggerSkill{
  name = "#wheel_cart_skill",
  attached_equip = "wheel_cart",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("#grain_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#caltrop_cart_skill", Player.HistoryTurn) > 0 or player:usedSkillTimes("#wheel_cart_skill", Player.HistoryTurn) > 0 then return false end
    if player:hasSkill(self) and table.find(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "wheel_cart" end) and not target:isNude() and target ~= player then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use and use.from == target.id and use.card.type ~= Card.TypeBasic
      end, Player.HistoryTurn)
      return #use_events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wheel_cart-invoke:"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#wheel_cart-give:"..player.id)
    room:obtainCard(player, card[1], false, fk.ReasonGive)
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(cid) return Fk:getCardById(cid).name == "wheel_cart" end)
    if #throw > 0 then
      room:throwCard(throw, self.name, player, player)
    end
  end,
}
Fk:addSkill(wheel_cart_skill)
local wheel_cart = fk.CreateTreasure{
  name = "&wheel_cart",
  suit = Card.Spade,
  number = 5,
  equip_skill = wheel_cart_skill,
}
extension:addCard(wheel_cart)
Fk:loadTranslationTable{
  ["wheel_cart"] = "飞轮战舆",
  ["#wheel_cart_skill"] = "飞轮战舆",
  [":wheel_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：其他角色的回合结束时，若本回合使用过非基本牌，你可以令其交给你一张牌，然后弃置此牌。",
  ["#wheel_cart-invoke"] = "飞轮战舆：你可以令%src交给你一张牌，然后弃置此牌",
  ["#wheel_cart-give"] = "飞轮战舆：你须交给%src一张牌",
}

local py_halberd_skill = fk.CreateTriggerSkill{
  name = "#py_halberd_skill",
  attached_equip = "py_halberd",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.chained
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1"}
    if not data.to:isNude() then table.insert(choices, "py_halberd_throw") end
    if room:askForChoice(player, choices, self.name) == "draw1" then
      player:drawCards(1, self.name)
    else
      local cid = room:askForCardChosen(player, data.to, "he", self.name)
      room:throwCard({cid}, self.name, data.to, player)
    end
  end,
}
Fk:addSkill(py_halberd_skill)
local py_halberd = fk.CreateWeapon{
  name = "&py_halberd",
  suit = Card.Diamond,
  number = 12,
  attack_range = 4,
  equip_skill = py_halberd_skill,
}
extension:addCard(py_halberd)
Fk:loadTranslationTable{
  ["py_halberd"] = "无双方天戟",
  ["#py_halberd_skill"] = "无双方天戟",
  [":py_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：你使用【杀】对目标角色造成伤害后，你可以摸一张牌或弃置该角色一张牌。",
  ["py_halberd_throw"] = "弃置其一张牌",
}

local py_blade_skill = fk.CreateTriggerSkill{
  name = "#py_blade_skill",
  attached_equip = "py_blade",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget and data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
Fk:addSkill(py_blade_skill)
local py_blade = fk.CreateWeapon{
  name = "&py_blade",
  suit = Card.Spade,
  number = 5,
  attack_range = 3,
  equip_skill = py_blade_skill,
}
extension:addCard(py_blade)
Fk:loadTranslationTable{
  ["py_blade"] = "鬼龙斩月刀",
  ["#py_blade_skill"] = "鬼龙斩月刀",
  [":py_blade"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你使用红色【杀】不能被【闪】响应。",
}

local blood_sword_skill = fk.CreateTriggerSkill{
  name = "#blood_sword_skill",
  attached_equip = "blood_sword",
  frequency = Skill.Compulsory,
  events = { fk.TargetSpecified },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    room:addPlayerMark(room:getPlayerById(data.to), "blood_swordMark")
    data.extra_data = data.extra_data or {}
    data.extra_data.blood_swordNullified = data.extra_data.blood_swordNullified or {}
    data.extra_data.blood_swordNullified[tostring(data.to)] = (data.extra_data.blood_swordNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.blood_swordNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.blood_swordNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
      if p:getMark("blood_swordMark") > 0 then
        room:removePlayerMark(p, "blood_swordMark", num)
      end
    end
    data.blood_swordNullified = nil
  end,
}
local blood_sword_prohibit = fk.CreateProhibitSkill{
  name = "#blood_sword_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("blood_swordMark") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds(Player.Hand), id) end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("blood_swordMark") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds(Player.Hand), id) end)
    end
  end,
}
blood_sword_skill:addRelatedSkill(blood_sword_prohibit)
Fk:addSkill(blood_sword_skill)
local blood_sword = fk.CreateWeapon{
  name = "&blood_sword",
  suit = Card.Spade,
  number = 6,
  attack_range = 2,
  equip_skill = blood_sword_skill,
}
extension:addCard(blood_sword)
Fk:loadTranslationTable{
  ["blood_sword"] = "赤血青锋",
  ["#blood_sword_skill"] = "赤血青锋",
  [":blood_sword"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：锁定技，你使用【杀】指定目标后，此【杀】无视目标角色的防具且目标不能使用或打出手牌，直至此【杀】结算完毕。",
}

local py_double_halberd_skill = fk.CreateTriggerSkill{
  name = "#py_double_halberd_skill",
  attached_equip = "py_double_halberd",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player.hp > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    local cards = room:getSubcardsByRule(data.card, { Card.Processing })
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
      })
    end
    if player.dead then return end 
    player:drawCards(1, self.name)
    room:addPlayerMark(player, "py_double_halberd-turn")
  end,
}
local py_double_halberd_targetmod = fk.CreateTargetModSkill{
  name = "#py_double_halberd_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("py_double_halberd-turn")
    end
  end,
}
py_double_halberd_skill:addRelatedSkill(py_double_halberd_targetmod)
Fk:addSkill(py_double_halberd_skill)
local py_double_halberd = fk.CreateWeapon{
  name = "&py_double_halberd",
  suit = Card.Diamond,
  number = 13,
  attack_range = 3,
  equip_skill = py_double_halberd_skill,
}
extension:addCard(py_double_halberd)
Fk:loadTranslationTable{
  ["py_double_halberd"] = "镔铁双戟",
  ["#py_double_halberd_skill"] = "镔铁双戟",
  [":py_double_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：你使用的【杀】被抵消后，你可以失去1点体力，然后获得此【杀】，摸一张牌，本回合使用【杀】的次数+1。",
}

local py_belt_skill = fk.CreateTriggerSkill{
  name = "#py_belt_skill",
  attached_equip = "py_belt",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
Fk:addSkill(py_belt_skill)
local py_belt = fk.CreateArmor{
  name = "&py_belt",
  suit = Card.Spade,
  number = 2,
  equip_skill = py_belt_skill,
}
extension:addCard(py_belt)
Fk:loadTranslationTable{
  ["py_belt"] = "玲珑狮蛮带",
  [":py_belt"] = "装备牌·防具<br /><b>防具技能</b>：当其他角色使用牌指定你为唯一目标后，你可以进行一次判定，若判定结果为红桃，则此牌对你无效。",
  ["#py_belt_skill"] = "玲珑狮蛮带",
}

local py_robe_skill = fk.CreateTriggerSkill{
  name = "#py_robe_skill",
  attached_equip = "py_robe",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType ~= fk.NormalDamage
  end,
  on_use = Util.TrueFunc,
}
Fk:addSkill(py_robe_skill)
local py_robe = fk.CreateArmor{
  name = "&py_robe",
  suit = Card.Club,
  number = 1,
  equip_skill = py_robe_skill,
}
extension:addCard(py_robe)
Fk:loadTranslationTable{
  ["py_robe"] = "红棉百花袍",
  [":py_robe"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，防止你受到的属性伤害。",
  ["#py_robe_skill"] = "红棉百花袍",
}

local py_cloak_skill = fk.CreateProhibitSkill{
  name = "#py_cloak_skill",
  attached_equip = "py_cloak",
  is_prohibited = function(self, from, to, card)
    return from ~= to and to:hasSkill(self) and card:isCommonTrick()
  end,
}
Fk:addSkill(py_cloak_skill)
local py_cloak = fk.CreateArmor{
  name = "&py_cloak",
  suit = Card.Spade,
  number = 9,
  equip_skill = py_cloak_skill,
}
extension:addCard(py_cloak)
Fk:loadTranslationTable{
  ["py_cloak"] = "国风玉袍",
  [":py_cloak"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，你不能成为其他角色使用普通锦囊牌的目标。",
  ["#py_cloak_skill"] = "国风玉袍",
}

local py_diagram_skill = fk.CreateTriggerSkill{
  name = "#py_diagram_skill",
  attached_equip = "py_diagram",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player.id == data.to and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = Util.TrueFunc,
}
Fk:addSkill(py_diagram_skill)
local py_diagram = fk.CreateArmor{
  name = "&py_diagram",
  suit = Card.Spade,
  number = 2,
  equip_skill = py_diagram_skill,
}
extension:addCard(py_diagram)
Fk:loadTranslationTable{
  ["py_diagram"] = "奇门八卦",
  [":py_diagram"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，【杀】对你无效。",
  ["#py_diagram_skill"] = "奇门八卦",
}

local py_hat_skill = fk.CreateTriggerSkill{
  name = "#py_hat_skill",
  attached_equip = "py_hat",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#py_hat-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage { from = player, to = player.room:getPlayerById(self.cost_data), damage = 1, skillName = self.name }
  end,
}
Fk:addSkill(py_hat_skill)
local py_hat = fk.CreateTreasure{
  name = "&py_hat",
  suit = Card.Diamond,
  number = 1,
  equip_skill = py_hat_skill,
}
extension:addCard(py_hat)
Fk:loadTranslationTable{
  ["py_hat"] = "束发紫金冠",
  ["#py_hat_skill"] = "束发紫金冠",
  [":py_hat"] = "装备牌·宝具<br/><b>宝具技能</b>：准备阶段，你可以对一名其他角色造成1点伤害。",
  ["#py_hat-choose"] = "束发紫金冠：你可以对一名其他角色造成1点伤害",
}

local py_coronet_skill = fk.CreateTriggerSkill{
  name = "#py_coronet_skill",
  attached_equip = "py_coronet",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local py_coronet_maxcards = fk.CreateMaxCardsSkill{
  name = "#py_coronet_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self) then
      return -1
    end
  end,
}
py_coronet_skill:addRelatedSkill(py_coronet_maxcards)
Fk:addSkill(py_coronet_skill)
local py_coronet = fk.CreateTreasure{
  name = "&py_coronet",
  suit = Card.Club,
  number = 4,
  equip_skill = py_coronet_skill,
  on_install = function(self, room, player)
    Treasure.onInstall(self, room, player)
    room:broadcastProperty(player, "MaxCards")
  end,
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    room:broadcastProperty(player, "MaxCards")
  end,
}
extension:addCard(py_coronet)
Fk:loadTranslationTable{
  ["py_coronet"] = "虚妄之冕",
  ["#py_coronet_skill"] = "虚妄之冕",
  [":py_coronet"] = "装备牌·宝具<br/><b>宝具技能</b>：锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限-1。",
}

local py_threebook_skill = fk.CreateAttackRangeSkill{
  name = "#py_threebook_skill",
  frequency = Skill.Compulsory,
  attached_equip = "py_threebook",
  correct_func = function (self, from)
    if from:hasSkill(self) then
      return 1
    end
  end,
}
local py_threebook_maxcards = fk.CreateMaxCardsSkill{
  name = "#py_threebook_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(py_threebook_skill) then
      return 1
    end
  end,
}
local py_threebook_targetmod = fk.CreateTargetModSkill{
  name = "#py_threebook_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(py_threebook_skill) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
py_threebook_skill:addRelatedSkill(py_threebook_maxcards)
py_threebook_skill:addRelatedSkill(py_threebook_targetmod)
Fk:addSkill(py_threebook_skill)
local py_threebook = fk.CreateTreasure{
  name = "&py_threebook",
  suit = Card.Spade,
  number = 5,
  equip_skill = py_threebook_skill,
  on_install = function(self, room, player)
    Treasure.onInstall(self, room, player)
    room:broadcastProperty(player, "MaxCards")
  end,
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    room:broadcastProperty(player, "MaxCards")
  end,
}
extension:addCard(py_threebook)
Fk:loadTranslationTable{
  ["py_threebook"] = "三略",
  [":py_threebook"] = "装备牌·宝具<br/><b>宝具技能</b>：锁定技，你的攻击范围+1；你的手牌上限+1；你出牌阶段使用【杀】的次数+1。",
}

local py_mirror_skill = fk.CreateTriggerSkill{
  name = "#py_mirror_skill",
  attached_equip = "py_mirror",
  events = {fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local ids = table.filter(player:getCardIds("h"), function (cid) 
      return Fk:getCardById(cid).type == Card.TypeBasic or Fk:getCardById(cid):isCommonTrick()
    end)
    if #ids == 0 then return false end
    local cards = player.room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|hand|.|.|"..table.concat(ids,","), "#py_mirror-show")
    if #cards > 0 then
      self.cost_data = cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local show = self.cost_data
    player:showCards({show})
    local card = Fk:cloneCard(Fk:getCardById(show).name)
    card.skillName = self.name
    local canUse = false
    local extra_data = { bypass_times = true }
    if player:canUse(card, extra_data) and not player:prohibitUse(card) then canUse = true end
    local dat
    if canUse then
      room:setPlayerMark(player, "py_mirror_name",card.name)
      _, dat = player.room:askForUseViewAsSkill(player, "py_mirror_viewas", "#py_mirror-use:::"..card.name, true, extra_data)
    end
    if dat then
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(p) return {p} end),
        card = card,
      }
    end
  end,
}
local py_mirror_viewas = fk.CreateViewAsSkill{
  name = "py_mirror_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(Self:getMark("py_mirror_name"))
    card.skillName = "#py_mirror_skill"
    return card
  end,
}
Fk:addSkill(py_mirror_viewas)
Fk:addSkill(py_mirror_skill)
local py_mirror = fk.CreateTreasure{
  name = "&py_mirror",
  suit = Card.Diamond,
  number = 1,
  equip_skill = py_mirror_skill,
}
extension:addCard(py_mirror)
Fk:loadTranslationTable{
  ["py_mirror"] = "照骨镜",
  ["#py_mirror_skill"] = "照骨镜",
  [":py_mirror"] = "装备牌·宝具<br/><b>宝具技能</b>：出牌阶段结束时，你可展示一张基本牌或普通锦囊牌，视为你使用之。",
  ["py_mirror_viewas"] = "照骨镜",
  ["#py_mirror-show"] = "照骨镜：你可展示一张基本牌或普通锦囊牌",
  ["#py_mirror-use"] = "照骨镜：视为使用%arg",
}

local siZhaoSwordSkill = fk.CreateTriggerSkill{
  name = "#sizhao_sword_skill",
  attached_equip = "sizhao_sword",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.card.number > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return false end
    --奇葩剑，随便整整算了
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "sizhao_sword", data.card.number)
    end
    use_event:addCleaner(function()
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "sizhao_sword", 0)
      end
    end)
  end,
}
local siZhaoSwordProhibit = fk.CreateProhibitSkill{
  name = "#sizhao_sword_prohibit",
  prohibit_use = function(self, player, card)
    return card.name == "jink" and player:getMark("sizhao_sword") > 0 and
    card.number > 0 and card.number < player:getMark("sizhao_sword")
  end,
}
siZhaoSwordSkill:addRelatedSkill(siZhaoSwordProhibit)
Fk:addSkill(siZhaoSwordSkill)
local siZhaoSword = fk.CreateWeapon{
  name = "&sizhao_sword",
  suit = Card.Diamond,
  number = 6,
  attack_range = 2,
  equip_skill = siZhaoSwordSkill,
}
extension:addCard(siZhaoSword)

Fk:loadTranslationTable{
  ["sizhao_sword"] = "思召剑",
  ["#sizhao_sword_skill"] = "思召剑",
  ["#sizhao_sword_prohibit"] = "思召剑",
  [":sizhao_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，当你使用【杀】时，你令所有角色不能使用点数小于此【杀】的【闪】直到此【杀】结算结束。",
}

return extension
