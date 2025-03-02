-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("ol_derived", Package.CardPack)
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_derived/skills")

Fk:loadTranslationTable{
  ["ol_derived"] = "OL衍生牌",
}

local honey_trap = fk.CreateCard{
  name = "&honey_trap",
  type = Card.TypeTrick,
  skill = "honey_trap_skill",
  is_damage_card = true,
}
extension:addCardSpec("honey_trap")
Fk:loadTranslationTable{
  ["honey_trap"] = "美人计",
  [":honey_trap"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他男性角色<br/><b>效果</b>：所有女性角色获得"..
  "目标角色的一张手牌并交给你一张手牌，然后你与目标中手牌数少的角色对手牌数多的角色造成1点伤害。",
}

local daggar_in_smile = fk.CreateCard{
  name = "&daggar_in_smile",
  type = Card.TypeTrick,
  skill = "daggar_in_smile_skill",
  is_damage_card = true,
}
extension:addCardSpec("daggar_in_smile")
Fk:loadTranslationTable{
  ["daggar_in_smile"] = "笑里藏刀",
  [":daggar_in_smile"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：目标角色摸X张牌（X为其已损失体力值"..
  "且至多为5），然后你对其造成1点伤害。",
}

local shangyang_reform = fk.CreateCard{
  name = "&shangyang_reform",
  type = Card.TypeTrick,
  skill = "shangyang_reform_skill",
  is_damage_card = true,
}
extension:addCardSpec("shangyang_reform", Card.Spade, 5)
extension:addCardSpec("shangyang_reform", Card.Spade, 7)
extension:addCardSpec("shangyang_reform", Card.Spade, 9)
Fk:loadTranslationTable{
  ["shangyang_reform"] = "商鞅变法",
  [":shangyang_reform"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：你对目标角色造成随机1~2点伤害，"..
  "若其因此伤害进入濒死状态，你判定，若为黑色，除其以外的角色不能对其使用【桃】直到濒死结算结束。",
}

local qin_dragon_sword = fk.CreateCard{
  name = "&qin_dragon_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#qin_dragon_sword_skill",
}
extension:addCardSpec("qin_dragon_sword", Card.Heart, 2)
Fk:loadTranslationTable{
  ["qin_dragon_sword"] = "真龙长剑",
  [":qin_dragon_sword"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：锁定技，你每回合使用的第一张普通锦囊牌不能被抵消。",
}

local qin_seal = fk.CreateCard{
  name = "&qin_seal",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#qin_seal_skill",
}
extension:addCardSpec("qin_seal", Card.Heart, 7)
Fk:loadTranslationTable{
  ["qin_seal"] = "传国玉玺",
  [":qin_seal"] = "装备牌·宝物<br/><b>宝物技能</b>：出牌阶段开始时，你可以视为使用【南蛮入侵】、【万箭齐发】、【桃园结义】或【五谷丰登】。",
}

local qin_crossbow = fk.CreateCard{
  name = "&qin_crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#qin_crossbow_skill",
}
extension:addCardSpec("qin_crossbow", Card.Club, 1)
Fk:loadTranslationTable{
  ["qin_crossbow"] = "秦弩",
  [":qin_crossbow"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/><b>武器技能</b>：锁定技，出牌阶段，你使用【杀】的次数+1；"..
  "当你使用【杀】指定一名目标后，你令其防具无效直到此【杀】结算完毕。",
}

local grain_cart = fk.CreateCard{
  name = "&grain_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#grain_cart_skill",
}
extension:addCardSpec("grain_cart", Card.Heart, 5)
Fk:loadTranslationTable{
  ["grain_cart"] = "四乘粮舆",
  [":grain_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：一名角色的回合结束时，若你的手牌数小于体力值，你可以摸两张牌，然后弃置此牌。",
}

local caltrop_cart = fk.CreateCard{
  name = "&caltrop_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#caltrop_cart_skill",
}
extension:addCardSpec("caltrop_cart", Card.Club, 5)
Fk:loadTranslationTable{
  ["caltrop_cart"] = "铁蒺玄舆",
  [":caltrop_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：其他角色的回合结束时，若其本回合未造成过伤害，你可以令其弃置两张牌，然后弃置此牌。",
}

local wheel_cart = fk.CreateCard{
  name = "&wheel_cart",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#wheel_cart_skill",
}
extension:addCardSpec("wheel_cart", Card.Spade, 5)
Fk:loadTranslationTable{
  ["wheel_cart"] = "飞轮战舆",
  [":wheel_cart"] = "装备牌·宝物<br/><b>宝物技能</b>：其他角色的回合结束时，若其本回合使用过非基本牌，你可以令其交给你一张牌，然后弃置此牌。",
}

local jade_comb = fk.CreateCard{
  name = "&jade_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#jade_comb_skill",
}
extension:addCardSpec("jade_comb", Card.Spade, 12)
Fk:loadTranslationTable{
  ["jade_comb"] = "琼梳",
  [":jade_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：当你受到伤害时，你可以弃置X张牌（X为伤害值），防止此伤害。",
}

local rhino_comb = fk.CreateCard{
  name = "&rhino_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#rhino_comb_skill",
}
extension:addCardSpec("rhino_comb", Card.Club, 12)
Fk:loadTranslationTable{
  ["rhino_comb"] = "犀梳",
  [":rhino_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：判定阶段开始前，你可选择：1.跳过此阶段；2.跳过此回合的弃牌阶段。",
}

local golden_comb = fk.CreateCard{
  name = "&golden_comb",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#golden_comb_skill",
}
extension:addCardSpec("golden_comb", Card.Heart, 12)
Fk:loadTranslationTable{
  ["golden_comb"] = "金梳",
  [":golden_comb"] = "装备牌·宝物<br/><b>宝物技能</b>：锁定技，出牌阶段结束时，你将手牌补至X张（X为你的手牌上限且至多为5）。",
}

local halberd = fk.CreateCard{
  name = "&py_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#py_halberd_skill",
}
extension:addCardSpec("py_halberd", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["py_halberd"] = "无双方天戟",
  [":py_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：你使用【杀】对目标角色造成伤害后，你可以摸一张牌或弃置其一张牌。",
}

local blade = fk.CreateCard{
  name = "&py_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#py_blade_skill",
}
extension:addCardSpec("py_blade", Card.Spade, 5)
Fk:loadTranslationTable{
  ["py_blade"] = "鬼龙斩月刀",
  [":py_blade"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你使用红色【杀】不能被响应。",
}

extension:loadCardSkels {
  honey_trap,
  daggar_in_smile,

  shangyang_reform,
  qin_dragon_sword,
  qin_seal,
  qin_crossbow,

  grain_cart,
  caltrop_cart,
  wheel_cart,

  jade_comb,
  rhino_comb,
  golden_comb,

  halberd,
  blade,
}

return extension
