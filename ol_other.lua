local extension = Package("ol_other")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_other"] = "OL-其他",
}

local godzhenji = General(extension, "godzhenji", "god", 3, 3, General.Female)
local shenfu = fk.CreateTriggerSkill{
  name = "shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#shenfu-damage", self.name, true)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          room:damage{
            from = player,
            to = to,
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = self.name,
          }
          if not to.dead then return end
        else
          return
        end
      end
    else
      while true do
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
          return p:getMark("shenfu-turn") == 0 end), function(p) return p.id end),
          1, 1, "#shenfu-hand", self.name, true)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          room:addPlayerMark(to, "shenfu-turn", 1)
          if to:isKongcheng() then
            to:drawCards(1, self.name)
          else
            local choice = room:askForChoice(player, {"shenfu_draw", "shenfu_discard"}, self.name)
            if choice == "shenfu_draw" then
              to:drawCards(1, self.name)
            else
              local card = room:askForCardsChosen(player, to, 1, 1, "h", self.name)
              room:throwCard(card, self.name, to, player)
            end
            if #to.player_cards[Player.Hand] ~= to.hp then return end
          end
        else
          return
        end
      end
    end
  end,
}
local qixian = fk.CreateMaxCardsSkill{
  name = "qixian",
  fixed_func = function (self, player)
    if player:hasSkill(self.name) then
      return 7
    end
  end,
}
godzhenji:addSkill(shenfu)
godzhenji:addSkill(qixian)
Fk:loadTranslationTable{
  ["godzhenji"] = "神甄姬",
  ["shenfu"] = "神赋",
  [":shenfu"] = "结束阶段，如果你的手牌数量为：奇数，可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；偶数，可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。",
  ["qixian"] = "七弦",
  [":qixian"] = "锁定技，你的手牌上限为7。",
  ["#shenfu-damage"] = "神赋：你可以对一名其他角色造成1点雷电伤害",
  ["#shenfu-hand"] = "神赋：你可以令一名角色摸一张牌或你弃置其一张手牌",
  ["shenfu_draw"] = "其摸一张牌",
  ["shenfu_discard"] = "你弃置其一张手牌",
}

local godcaopi = General(extension, "godcaopi", "god", 5)
local chuyuan = fk.CreateTriggerSkill{
  name = "chuyuan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and #player:getPile("caopi_chu") < player.maxHp and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1)
    local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#chuyuan-card:"..player.id)
    player:addToPile("caopi_chu", card, false, self.name)
  end,
}
local dengji = fk.CreateTriggerSkill{
  name = "dengji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    room:handleAddLoseSkills(player, "ex__jianxiong|tianxing", nil)
  end,
}
local tianxing = fk.CreateTriggerSkill{
  name = "tianxing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    local choice = room:askForChoice(player, {"rende", "ex__zhiheng", "luanji"}, self.name, "#tianxing-choice")  --TODO:ex__rende, ex__luanji
    room:handleAddLoseSkills(player, choice.."|-chuyuan", nil)
  end,
}
godcaopi:addSkill(chuyuan)
godcaopi:addSkill(dengji)
godcaopi:addRelatedSkill("ex__jianxiong")
godcaopi:addRelatedSkill(tianxing)
godcaopi:addRelatedSkill("rende")
godcaopi:addRelatedSkill("ex__zhiheng")
godcaopi:addRelatedSkill("luanji")
Fk:loadTranslationTable{
  ["godcaopi"] = "神曹丕",
  ["chuyuan"] = "储元",
  [":chuyuan"] = "当一名角色受到伤害后，若你的“储”数小于你的体力上限，你可以令其摸一张牌，然后其将一张手牌置于你的武将牌上，称为“储”。",
  ["dengji"] = "登极",
  [":dengji"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，获得〖奸雄〗和〖天行〗。",
  ["tianxing"] = "天行",
  [":tianxing"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，失去〖储元〗，并获得下列技能中的一项：〖仁德〗、〖制衡〗、〖乱击〗。",
  ["caopi_chu"] = "储",
  ["#chuyuan-card"] = "储元：将一张手牌作为“储”置于 %src 武将牌上",
  ["#tianxing-choice"] = "天行：选择获得的技能",
}

--官渡群张郃 辛评 韩猛
return extension
