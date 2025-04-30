local extension = Package:new("ol_mo")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_mo/skills")

Fk:loadTranslationTable{
  ["ol_mo"] = "OL-魔",
  ["ol_evil"] = "魔",
}

local simayi = General:new(extension, "ol_evil__simayi", "wei", 3)
simayi:addSkills { "guifu", "moubian" }
simayi:addRelatedSkills { "zhouxi" }
Fk:loadTranslationTable{
  ["ol_evil__simayi"] = "魔司马懿",
  ["#ol_evil__simayi"] = "无天的魔狼",

  ["~ol_evil__simayi"] = "哈哈哈哈哈哈，天数…我还是输给了天数？",
}

return extension
