local huirong = fk.CreateSkill{
  name = "huirong",
  tags = { Skill.Hidden, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huirong"] = "慧容",
  [":huirong"] = "隐匿技，锁定技，你登场时，令一名角色将手牌摸或弃至体力值（至多摸至五张）。",

  ["#huirong-choose"] = "慧容：令一名角色将手牌摸或弃至体力值（至多摸至五张）",

  ["$huirong1"] = "红尘洗练，慧容不改。",
  ["$huirong2"] = "花貌易改，福惠长存。",
}

local U = require "packages/utility/utility"

huirong:addEffect(U.GeneralAppeared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(huirong.name) and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() > p.hp or p:getHandcardNum() < math.min(p.hp, 5)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() > p.hp or p:getHandcardNum() < math.min(p.hp, 5)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = huirong.name,
      prompt = "#huirong-choose",
      cancelable = false,
    })[1]
    local n = to:getHandcardNum() - math.max(to.hp, 0)
    if n > 0 then
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = huirong.name,
        cancelable = false,
      })
    else
      n = math.min(5 - to:getHandcardNum(), -n)
      if n > 0 then
        to:drawCards(n, huirong.name)
      end
    end
  end,
})

return huirong
