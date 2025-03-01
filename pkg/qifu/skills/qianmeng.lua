local qianmeng = fk.CreateSkill{
  name = "qianmeng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qianmeng"] = "前盟",
  [":qianmeng"] = "锁定技，当一名角色的「灵杉」「玉树」数量变化后，若两者相等或一项为0，你摸一张牌。",

  ["$qianmeng1"] = "前盟已断，杉树长别。",
  ["$qianmeng2"] = "苍山有灵，杉树相依。",
}

local QianmengCheck = function(p)
  if p == nil then return false end
  local x = #p:getPile("huamu_lingshan")
  local y = #p:getPile("huamu_yushu")
  return x == 0 or y == 0 or x == y
end

qianmeng:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qianmeng.name) then
      local piles = {"huamu_lingshan", "huamu_yushu"}
      for _, move in ipairs(data) do
        if QianmengCheck(move.to) and move.toArea == Card.PlayerSpecial and table.contains(piles, move.specialName) then
          return true
        end
        if QianmengCheck(move.from) then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(piles, info.fromSpecialName) then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    local piles = {"huamu_lingshan", "huamu_yushu"}
    for _, move in ipairs(data) do
      if QianmengCheck(move.to) and move.toArea == Card.PlayerSpecial and table.contains(piles, move.specialName) then
        table.insert(targets, move.to)
      end
      if QianmengCheck(move.from) then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(piles, info.fromSpecialName) then
            table.insert(targets, move.from)
            break
          end
        end
      end
    end
    for _ = 1, #targets, 1 do
      if not player:hasSkill(qianmeng.name) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qianmeng.name)
  end,
})

return qianmeng
