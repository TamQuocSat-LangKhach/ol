local extension = Package:new("ol_sp_pack")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_sp/skills")

Fk:loadTranslationTable{
  ["ol_sp_pack"] = "OL-SP",
  ["ol_sp"] = "OLSP",
}

General:new(extension, "ol_sp__machao", "qun", 4):addSkills { "ol__zhuiji", "ol__shichou" }
Fk:loadTranslationTable{
  ["ol_sp__machao"] = "马超",
  ["#ol_sp__machao"] = "西凉的猛狮",
  ["illustrator:ol_sp__machao"] = "凝聚永恒",

  ["~ol_sp__machao"] = "父亲！父亲！！",
}

General:new(extension, "ol_sp__caoren", "wei", 4):addSkills { "weikui", "lizhan" }
Fk:loadTranslationTable{
  ["ol_sp__caoren"] = "曹仁",
  ["#ol_sp__caoren"] = "鬼神之勇",
  ["illustrator:ol_sp__caoren"] = "张华",

  ["~ol_sp__caoren"] = "城在人在，城破人亡。",
}

General:new(extension, "wanglang", "wei", 3):addSkills { "gushe", "jici" }
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["#wanglang"] = "凤鹛",
  ["designer:wanglang"] = "千幻",
  ["illustrator:wanglang"] = "銘zmy",

  ["~wanglang"] = "你，你！……哇啊……啊……",
}

General:new(extension, "ol_sp__zhanghe", "qun", 4):addSkills { "zhouxuanz" }
Fk:loadTranslationTable{
  ["ol_sp__zhanghe"] = "张郃",
  ["#ol_sp__zhanghe"] = "倾柱覆州",
  ["designer:ol_sp__zhanghe"] = "七哀",
  ["illustrator:ol_sp__zhanghe"] = "君桓文化",

  ["~ol_sp__zhanghe"] = "我终究是看不透这人心。",
}

local huangyueying = General:new(extension, "ol_sp__huangyueying", "qun", 3, 3, General.Female)
huangyueying:addSkills { "ol__jiqiao", "ol__linglong" }
huangyueying:addRelatedSkill("qicai")
Fk:loadTranslationTable{
  ["ol_sp__huangyueying"] = "黄月英",
  ["#ol_sp__huangyueying"] = "闺中璞玉",
  ["illustrator:ol_sp__huangyueying"] = "杨杨和夏季",

  ["~ol_sp__huangyueying"] = "世人难容有才之女……",
}

General:new(extension, "ol_sp__zhangliao", "qun", 4):addSkills { "mubing", "ziqu", "diaoling" }
Fk:loadTranslationTable{
  ["ol_sp__zhangliao"] = "张辽",
  ["#ol_sp__zhangliao"] = "功果显名",
  ["illustrator:ol_sp__zhangliao"] = "君桓文化",

  ["~ol_sp__zhangliao"] = "孤军难鸣，进退维谷。",
}

local menghuo = General:new(extension, "ol_sp__menghuo", "qun", 4)
menghuo:addSkills { "manwang" }
menghuo:addRelatedSkill("panqin")
Fk:loadTranslationTable{
  ["ol_sp__menghuo"] = "孟获",
  ["#ol_sp__menghuo"] = "夷汉并服",
  ["designer:ol_sp__menghuo"] = "玄蝶既白",
  ["illustrator:ol_sp__menghuo"] = "君桓文化",

  ["~ol_sp__menghuo"] = "有材而得生，无材而得纵……",
}

General:new(extension, "ol__puyuan", "shu", 4):addSkills { "shengong", "qisi" }
Fk:loadTranslationTable{
  ["ol__puyuan"] = "蒲元",
  ["#ol__puyuan"] = "鬼斧神工",
  ["illustrator:ol__puyuan"] = "君桓文化",

  ["~ol__puyuan"] = "锻兵万千，不及造屋二三……",
}

local zhouqun = General:new(extension, "ol__zhouqun", "shu", 4)
zhouqun:addSkills { "tianhou", "chenshuo" }
zhouqun:addRelatedSkills { "tianhou_hot", "tianhou_fog", "tianhou_rain", "tianhou_frost"}
Fk:loadTranslationTable{
  ["ol__zhouqun"] = "周群",
  ["#ol__zhouqun"] = "后圣",
  ["illustrator:ol__zhouqun"] = "鬼画府",

  ["~ol__zhouqun"] = "知万物而不知己命，大谬也……",
}

General:new(extension, "ol_sp__sunce", "qun", 4):addSkills { "liantao" }
Fk:loadTranslationTable{
  ["ol_sp__sunce"] = "孙策",
  ["#ol_sp__sunce"] = "壮武命世",
  ["illustrator:ol_sp__sunce"] = "君桓文化",
  ["designer:ol_sp__sunce"] = "韩旭",

  ["~ol_sp__sunce"] = "身受百创，力难从心……",
}

local caocao = General:new(extension, "ol_sp__caocao", "qun", 4)
caocao:addSkills { "xixiang", "aige" }
caocao:addRelatedSkill("zhubei")
Fk:loadTranslationTable{
  ["ol_sp__caocao"] = "曹操",
  ["#ol_sp__caocao"] = "踌躇的孤雁",

  ["~ol_sp__caocao"] = "尔等，算什么大汉忠臣！",
}

General:new(extension, "ol_sp__liubei", "qun", 4):addSkills { "xudai", "zhujiu", "jinglei" }
Fk:loadTranslationTable{
  ["ol_sp__liubei"] = "刘备",
  ["#ol_sp__liubei"] = "潜龙勿用",

  ["~ol_sp__liubei"] = "一介凡夫俗子，不识龙为何物。",
}

--General:new(extension, "ol__nanhualaoxian", "qun", 3):addSkills { "qingshu", "ol__shoushu", "hedao" }
Fk:loadTranslationTable{
  ["ol__nanhualaoxian"] = "南华老仙",
  ["#ol__nanhualaoxian"] = "逍遥仙游",

  ["~ol__nanhualaoxian"] = "尔生异心，必获恶报！",
}

return extension
