-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("variation", Package.CardPack)

local slash = Fk:cloneCard("slash")
extension:addCards{
  slash:clone(Card.Diamond, 6),
  slash:clone(Card.Diamond, 7),
  slash:clone(Card.Diamond, 9),
  slash:clone(Card.Diamond, 13),
  slash:clone(Card.Heart, 10),
  slash:clone(Card.Heart, 10),
  slash:clone(Card.Heart, 11),
  slash:clone(Card.Club, 6),
  slash:clone(Card.Club, 7),
  slash:clone(Card.Club, 8),
  slash:clone(Card.Club, 11),
  slash:clone(Card.Club, 8),
  slash:clone(Card.Spade, 9),
  slash:clone(Card.Spade, 9),
  slash:clone(Card.Spade, 10),
  slash:clone(Card.Spade, 10),
  slash:clone(Card.Club, 2),
  slash:clone(Card.Club, 3),
  slash:clone(Card.Club, 4),
  slash:clone(Card.Club, 5),
  slash:clone(Card.Club, 11),
  slash:clone(Card.Diamond, 8),
}

local iceSlashSkill = fk.CreateActiveSkill{
  name = "ice__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from
    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1 + (effect.additionalDamage or 0),
      damageType = fk.IceDamage,
      skillName = self.name
    })
  end
}
local IceDamageSkill = fk.CreateTriggerSkill{
  name = "ice_damage_skill",
  global = true,
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.damageType == fk.IceDamage and not data.chain and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    for i = 1, 2 do
      if to:isNude() then break end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(card, self.name, to, player)
    end
    return true
  end
}
Fk:addSkill(IceDamageSkill)
local iceSlash = fk.CreateBasicCard{
  name = "ice__slash",
  skill = iceSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
}

local thunderSlash = Fk:cloneCard("thunder__slash")
extension:addCards{
  thunderSlash:clone(Card.Spade, 4),
  thunderSlash:clone(Card.Spade, 5),
  thunderSlash:clone(Card.Spade, 6),
  thunderSlash:clone(Card.Club, 5),
  thunderSlash:clone(Card.Club, 6),
  thunderSlash:clone(Card.Club, 7),
  thunderSlash:clone(Card.Club, 8),
  thunderSlash:clone(Card.Club, 9),
  thunderSlash:clone(Card.Club, 9),
  thunderSlash:clone(Card.Club, 10),
  thunderSlash:clone(Card.Club, 10),
}

local fireSlash = Fk:cloneCard("fire__slash")
extension:addCards{
  fireSlash:clone(Card.Heart, 4),
  fireSlash:clone(Card.Heart, 7),
  fireSlash:clone(Card.Diamond, 5),
  fireSlash:clone(Card.Heart, 10),
  fireSlash:clone(Card.Diamond, 4),
  fireSlash:clone(Card.Diamond, 10),
}

local jink = Fk:cloneCard("jink")
extension:addCards{
  jink:clone(Card.Diamond, 11),
  jink:clone(Card.Diamond, 3),
  jink:clone(Card.Diamond, 5),
  jink:clone(Card.Diamond, 6),
  jink:clone(Card.Diamond, 7),
  jink:clone(Card.Diamond, 8),
  jink:clone(Card.Diamond, 9),
  jink:clone(Card.Diamond, 10),
  jink:clone(Card.Diamond, 11),
  jink:clone(Card.Heart, 13),
  jink:clone(Card.Heart, 8),
  jink:clone(Card.Heart, 9),
  jink:clone(Card.Heart, 11),
  jink:clone(Card.Heart, 12),
  jink:clone(Card.Diamond, 6),
  jink:clone(Card.Diamond, 7),
  jink:clone(Card.Diamond, 8),
  jink:clone(Card.Diamond, 10),
  jink:clone(Card.Diamond, 11),
  jink:clone(Card.Heart, 2),
  jink:clone(Card.Heart, 2),
  jink:clone(Card.Diamond, 2),
  jink:clone(Card.Diamond, 2),
  jink:clone(Card.Diamond, 4),
}

local peach = Fk:cloneCard("peach")
extension:addCards{
  peach:clone(Card.Diamond, 12),
  peach:clone(Card.Heart, 3),
  peach:clone(Card.Heart, 4),
  peach:clone(Card.Heart, 6),
  peach:clone(Card.Heart, 7),
  peach:clone(Card.Heart, 8),
  peach:clone(Card.Heart, 9),
  peach:clone(Card.Heart, 12),
  peach:clone(Card.Heart, 5),
  peach:clone(Card.Heart, 6),
  peach:clone(Card.Diamond, 2),
  peach:clone(Card.Diamond, 3),
}

local analeptic = Fk:cloneCard("analeptic")
extension:addCards{
  analeptic:clone(Card.Diamond, 9),
  analeptic:clone(Card.Spade, 3),
  analeptic:clone(Card.Spade, 9),
  analeptic:clone(Card.Club, 3),
  analeptic:clone(Card.Club, 9),
}

extension:addCards{
  Fk:cloneCard("crossbow", Card.Diamond, 1),
  Fk:cloneCard("crossbow", Card.Club, 1),
  Fk:cloneCard("double_swords", Card.Spade, 2),
  Fk:cloneCard("qinggang_sword", Card.Spade, 6),
  Fk:cloneCard("blade", Card.Spade, 5),
  Fk:cloneCard("spear", Card.Spade, 12),
  Fk:cloneCard("axe", Card.Diamond, 5),
  Fk:cloneCard("kylin_bow", Card.Heart, 5),
  Fk:cloneCard("guding_blade", Card.Spade, 1),
}

local blackChainSkill = fk.CreateTriggerSkill{
  name = "#black_chain_skill",
  attached_equip = "black_chain",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not player.room:getPlayerById(data.to).chained
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(data.to):setChainState(true)
  end,
}
Fk:addSkill(blackChainSkill)
local blackChain = fk.CreateWeapon{
  name = "black_chain",
  suit = Card.Diamond,
  number = 12,
  attack_range = 3,
  equip_skill = blackChainSkill,
}
extension:addCard(blackChain)

local fiveElementsFanSkill = fk.CreateViewAsSkill{
  name = "five_elements_fan_skill",
  attached_equip = "five_elements_fan",
  interaction = function(self)
    local choices = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and card.name ~= "slash" then
        table.insertIfNeed(choices, card.name)
      end
    end
    return UI.ComboBox{choices = choices}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash" and Fk:getCardById(to_select).name ~= "slash" and
      Fk:getCardById(to_select).name ~= self.interaction.data
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "five_elements_fan"
    return card
  end,
}
Fk:addSkill(fiveElementsFanSkill)
local fiveElementsFan = fk.CreateWeapon{
  name = "five_elements_fan",
  suit = Card.Diamond,
  number = 1,
  attack_range = 4,
  equip_skill = fiveElementsFanSkill,
}
extension:addCard(fiveElementsFan)

extension:addCards{
  Fk:cloneCard("eight_diagram", Card.Spade, 2),
  Fk:cloneCard("nioh_shield", Card.Club, 2),
  Fk:cloneCard("vine", Card.Spade, 2),
  Fk:cloneCard("vine", Card.Club, 2),
}
--♣A 护心镜
--当你受到大于1点的伤害或致命伤害时，你可将装备区里的【护心镜】置入弃牌堆，若如此做，防止此伤害。出牌阶段，你可将手牌中的【护心镜】置入其他角色的装备区。
--♣2 黑光铠
--锁定技，当你成为【杀】、伤害锦囊或黑色锦囊牌的目标后，若你不是唯一目标，此牌对你无效。
--♣Q 天机图
--锁定技，此牌进入你的装备区时，弃置一张其他牌；此牌离开你的装备区时，你将手牌摸至五张。
--♠A 太公阴符
--出牌阶段开始时，你可以横置或重置一名角色；出牌阶段结束时，你可以重铸一张手牌。
--♣K 铜雀
--你每回合使用的第一张带有强化效果的牌无使用条件。

extension:addCards{
  Fk:cloneCard("chitu", Card.Heart, 5),
  Fk:cloneCard("zixing", Card.Diamond, 13),
  Fk:cloneCard("dayuan", Card.Spade, 13),
  Fk:cloneCard("jueying", Card.Spade, 5),
  Fk:cloneCard("dilu", Card.Club, 5),
  Fk:cloneCard("zhuahuangfeidian", Card.Heart, 13),
  Fk:cloneCard("hualiu", Card.Diamond, 13),
}

extension:addCards{
  Fk:cloneCard("snatch", Card.Diamond, 3),
  Fk:cloneCard("snatch", Card.Diamond, 4),
  Fk:cloneCard("snatch", Card.Spade, 11),
  Fk:cloneCard("dismantlement", Card.Heart, 12),
  Fk:cloneCard("dismantlement", Card.Spade, 4),
  Fk:cloneCard("dismantlement", Card.Heart, 2),
  Fk:cloneCard("amazing_grace", Card.Heart, 3),
  Fk:cloneCard("amazing_grace", Card.Heart, 4),
  Fk:cloneCard("duel", Card.Diamond, 1),
  Fk:cloneCard("duel", Card.Spade, 1),
  Fk:cloneCard("duel", Card.Club, 1),
  Fk:cloneCard("savage_assault", Card.Spade, 13),
  Fk:cloneCard("savage_assault", Card.Spade, 7),
  Fk:cloneCard("savage_assault", Card.Club, 7),
  Fk:cloneCard("archery_attack", Card.Heart, 1),
  Fk:cloneCard("lightning", Card.Heart, 12),
  Fk:cloneCard("god_salvation", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Club, 12),
  Fk:cloneCard("nullification", Card.Club, 13),
  Fk:cloneCard("nullification", Card.Spade, 11),
  Fk:cloneCard("nullification", Card.Diamond, 12),
  Fk:cloneCard("nullification", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Spade, 13),
  Fk:cloneCard("nullification", Card.Heart, 13),
  Fk:cloneCard("indulgence", Card.Heart, 6),
  Fk:cloneCard("indulgence", Card.Club, 6),
  Fk:cloneCard("indulgence", Card.Spade, 6),
  Fk:cloneCard("iron_chain", Card.Spade, 11),
  Fk:cloneCard("iron_chain", Card.Spade, 12),
  Fk:cloneCard("iron_chain", Card.Club, 10),
  Fk:cloneCard("iron_chain", Card.Club, 11),
  Fk:cloneCard("iron_chain", Card.Club, 12),
  Fk:cloneCard("iron_chain", Card.Club, 13),
  Fk:cloneCard("supply_shortage", Card.Spade, 10),
  Fk:cloneCard("supply_shortage", Card.Club, 4),
}

local drowningSkill = fk.CreateActiveSkill{
  name = "drowningskill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if #to.player_cards[Player.Equip] == 0 then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name
      })
    else
      if room:askForSkillInvoke(to, self.name, nil, "#drowning-discard::"..from.id) then
        to:throwAllCards("e")
      else
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name
        })

      end
    end
  end
}
local drowning = fk.CreateTrickCard{
  name = "drowning",
  skill = drowningSkill,
}
extension:addCards({
  drowning:clone(Card.Spade, 3),
  drowning:clone(Card.Spade, 4),
})

local unexpectationSkill = fk.CreateActiveSkill{
  name = "unexpectation_skill",
  target_num = 1,
  target_filter = function(self, to_select)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to:isKongcheng() then return end
    local showCard = room:askForCardChosen(from, to, "h", self.name)
    to:showCards(showCard)
    showCard = Fk:getCardById(showCard)
    if showCard.suit == Card.NoSuit or effect.card.suit == Card.NoSuit then return end
    if showCard.suit ~= effect.card.suit then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        skillName = self.name
      })
    end
  end,
}
local unexpectation = fk.CreateTrickCard{
  name = "unexpectation",
  skill = unexpectationSkill,
  is_damage_card = true,
}
extension:addCards{
  unexpectation:clone(Card.Heart, 3),
  unexpectation:clone(Card.Diamond, 11),
}

--随机应变♠2

local foresightSkill = fk.CreateActiveSkill{
  name = "foresight_skill",
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = {{cardUseEvent.from}}
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    room:askForGuanxing(to, room:getNCards(2))
    room:drawCards(to, 2, self.name)
  end
}
local foresight = fk.CreateTrickCard{
  name = "foresight",
  skill = foresightSkill,
}
extension:addCards({
  foresight:clone(Card.Heart, 7),
  foresight:clone(Card.Heart, 8),
  foresight:clone(Card.Heart, 9),
  foresight:clone(Card.Heart, 11),
})

local chasingNearSkill = fk.CreateActiveSkill{
  name = "chasing_near_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to:isAllNude() then return end
    local id = room:askForCardChosen(from, to, "hej", self.name)
    if from:distanceTo(to) > 1 then
      room:throwCard(id, self.name, to, from)
    elseif from:distanceTo(to) == 1 then
        room:obtainCard(from, id)
    end
  end
}
local chasing_near = fk.CreateTrickCard{
  name = "chasing_near",
  skill = chasingNearSkill,
}
extension:addCards({
  chasing_near:clone(Card.Spade, 3),
  chasing_near:clone(Card.Spade, 12),
  chasing_near:clone(Card.Club, 3),
  chasing_near:clone(Card.Club, 4),
})


Fk:loadTranslationTable{
  ["variation"] = "应变",

  ["ice__slash"] = "冰杀",
  ["ice_damage_skill"] = "冰杀",
	[":ice__slash"] = "基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：攻击范围内的一名角色<br /><b>效果</b>：对目标角色造成1点冰冻伤害。（一名角色造成不为连环伤害的冰冻伤害时，若受到此伤害的角色有牌，来源可防止此伤害，然后依次弃置其两张牌）。",
  ["five_elements_fan"] = "五行鹤翎扇",
  ["five_elements_fan_skill"] = "五行扇",
  [":five_elements_fan"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：你可以将属性【杀】当任意其他属性【杀】使用。",
  ["black_chain"] = "乌铁锁链",
  ["black_chain_skill"] = "乌铁锁链",
  [":black_chain"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：当你使用【杀】指定目标后，你可以横置目标角色武将牌。",
  ["drowning"] = "水淹七军",
  ["drowning_skill"] = "水淹七军",
  ["#drowning-discard"] = "水淹七军：“确定”弃置装备区所有牌，或点“取消” %dest 对你造成1点雷电伤害",
  [":drowning"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：目标角色选择一项：1.弃置装备区所有牌（至少一张）；2.你对其造成1点雷电伤害。",
  ["unexpectation"] = "出其不意",
  ["unexpectation_skill"] = "出其不意",
  [":unexpectation"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名有手牌的其他角色<br /><b>效果</b>：你展示目标角色的一张手牌，若该牌与此【出其不意】花色不同，你对其造成1点伤害。",
  ["adaptation"] = "随机应变",
  ["foresight"] = "洞烛先机",
  ["foresight_skill"] = "洞烛先机",
  [":foresight"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：目标角色卜算2（观看牌堆顶的两张牌，将其中任意张以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底），然后摸两张牌。",
  ["chasing_near"] = "逐近弃远",
  ["chasing_near_skill"] = "逐近弃远",
  [":chasing_near"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名区域里有牌的其他角色<br /><b>效果</b>：若你与目标角色距离为1，你获得其区域里一张牌；若你与目标角色距离大于1，你弃置其区域里一张牌。",
}

return extension
