local extension = Package:new("ol_wende")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/wende/skills")

Fk:appendKingdomMap("god", {"jin"})

Fk:loadTranslationTable{
  ["ol_wende"] = "OL-文德武备",
  ["jin"] = "晋",
}

--理：司马懿 张春华 李肃 司马伷 彻里吉 华歆
General:new(extension, "ol__simayi", "jin", 3):addSkills { "yingshis", "xiongzhi", "quanbian" }  --"buchen"
Fk:loadTranslationTable{
  ["ol__simayi"] = "司马懿",
  ["#ol__simayi"] = "通权达变",
  ["illustrator:ol__simayi"] = "六道目",

  ["~ol__simayi"] = "虎入骷冢，司马难兴。",
}

General:new(extension, "ol__zhangchunhua", "jin", 3, 3, General.Female):addSkills { "ol__huishi", "qingleng" }  --"xuanmu"
Fk:loadTranslationTable{
  ["ol__zhangchunhua"] = "张春华",
  ["#ol__zhangchunhua"] = "宣穆皇后",
  ["illustrator:ol__zhangchunhua"] = "六道目",

  ["~ol__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

General:new(extension, "ol__lisu", "qun", 3):addSkills { "qiaoyan", "ol__xianzhu" }
Fk:loadTranslationTable{
  ["ol__lisu"] = "李肃",
  ["#ol__lisu"] = "巧言令色",
  ["illustrator:ol__lisu"] = "君桓文化",

  ["~ol__lisu"] = "忘恩负义之徒！",
}

General:new(extension, "simazhou", "jin", 4):addSkills { "caiwang", "naxiang" }
Fk:loadTranslationTable{
  ["simazhou"] = "司马伷",
  ["#simazhou"] = "琅琊武王",
  ["illustrator:simazhou"] = "凝聚永恒",

  ["~simazhou"] = "恩赐重物，病身难消受……",
}

General:new(extension, "cheliji", "qun", 4):addSkills { "chexuan", "qiangshou" }
Fk:loadTranslationTable{
  ["cheliji"] = "彻里吉",
  ["#cheliji"] = "高凉铁骨",
  ["illustrator:cheliji"] = "YanBai",

  ["~cheliji"] = "元气已伤，不如归去……",
}

General:new(extension, "ol__huaxin", "wei", 3):addSkills { "caozhaoh", "ol__xibing" }
Fk:loadTranslationTable{
  ["ol__huaxin"] = "华歆",
  ["#ol__huaxin"] = "渊清玉洁",
  ["illustrator:ol__huaxin"] = "猎枭",

  ["~ol__huaxin"] = "死国，甚无谓也！",
}

--备：成济成倅 张虎乐綝 夏侯徽 司马师 羊徽瑜 石苞
General:new(extension, "chengjichengcui", "jin", 6):addSkills { "tousui", "chuming" }
Fk:loadTranslationTable{
  ["chengjichengcui"] = "成济成倅",
  ["#chengjichengcui"] = "袒忿半瓦",
  ["designer:chengjichengcui"] = "玄蝶既白",
  ["illustrator:chengjichengcui"] = "君桓文化",

  ["~chengjichengcui"] = "今为贼子贾充所害！",
}

local zhanghuyuechen = General:new(extension, "zhanghuyuechen", "jin", 4)
zhanghuyuechen:addSkills { "xijue" }
zhanghuyuechen:addRelatedSkills { "ex__tuxi", "xiaoguo" }
Fk:loadTranslationTable{
  ["zhanghuyuechen"] = "张虎乐綝",
  ["#zhanghuyuechen"] = "不辱门庭",
  ["designer:zhanghuyuechen"] = "张浩",
  ["illustrator:zhanghuyuechen"] = "凝聚永恒",

  ["$ex__tuxi_zhanghuyuechen1"] = "动如霹雳，威震宵小！",
  ["$ex__tuxi_zhanghuyuechen2"] = "行略如风，摧枯拉朽！",
  ["$xiaoguo_zhanghuyuechen1"] = "大丈夫生于世，当沙场效忠！",
  ["$xiaoguo_zhanghuyuechen2"] = "骁勇善战，刚毅果断！",
  ["~zhanghuyuechen"] = "儿有辱……父亲威名……",
}

--果：宣公主 司马昭 王元姬 杜预 卫瓘
General:new(extension, "xuangongzhu", "jin", 3, 3, General.Female):addSkills { "qimei", "zhuijix" }  --"gaoling"
Fk:loadTranslationTable{
  ["xuangongzhu"] = "宣公主",
  ["#xuangongzhu"] = "高陵公主",
  ["designer:xuangongzhu"] = "世外高v狼",
  ["illustrator:xuangongzhu"] = "凡果",

  ["~xuangongzhu"] = "元凯，我去也……",
}

General:new(extension, "ol__simazhao", "jin", 3):addSkills { "choufa", "zhaoran", "chengwu" }  --"tuishi"
Fk:loadTranslationTable{
  ["ol__simazhao"] = "司马昭",
  ["#ol__simazhao"] = "晋文帝",
  ["illustrator:ol__simazhao"] = "君桓文化",

  ["~ol__simazhao"] = "司马三代，一梦成空……",
}

General:new(extension, "ol__wangyuanji", "jin", 3, 3, General.Female):addSkills { "yanxi" }  --"shiren"
Fk:loadTranslationTable{
  ["ol__wangyuanji"] = "王元姬",
  ["#ol__wangyuanji"] = "文明皇后",
  ["illustrator:ol__wangyuanji"] = "六道目",

  ["~ol__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

local duyu = General:new(extension, "ol__duyu", "jin", 4)
duyu:addSkills { "sanchen", "zhaotao" }
duyu:addRelatedSkill("pozhu")
Fk:loadTranslationTable{
  ["ol__duyu"] = "杜预",
  ["#ol__duyu"] = "文成武德",
  ["designer:ol__duyu"] = "张浩",
  ["illustrator:ol__duyu"] = "君桓文化",

  ["~ol__duyu"] = "金瓯尚缺，死难瞑目……",
}

General:new(extension, "weiguan", "jin", 3):addSkills { "zhongyun", "shenpin" }
Fk:loadTranslationTable{
  ["weiguan"] = "卫瓘",
  ["#weiguan"] = "兰陵郡公",
  ["illustrator:weiguan"] = "Karneval",

  ["~weiguan"] = "辞荣善终，不可求……",
}

--戒：钟琰 辛敞 贾充 王祥
General:new(extension, "zhongyan", "jin", 3, 3, General.Female):addSkills { "bolan", "yifa" }
Fk:loadTranslationTable{
  ["zhongyan"] = "钟琰",
  ["#zhongyan"] = "聪慧弘雅",
  ["illustrator:zhongyan"] = "明暗交界",

  ["~zhongyan"] = "嗟尔姜任，邈不我留。",
}

General:new(extension, "xinchang", "jin", 3):addSkills { "canmou", "congjianx" }
Fk:loadTranslationTable{
  ["xinchang"] = "辛敞",
  ["#xinchang"] = "英鉴中铭",
  ["illustrator:xinchang"] = "君桓文化",

  ["~xinchang"] = "宪英，救我！",
}

General:new(extension, "ol__jiachong", "jin", 3):addSkills { "xiongshu", "jianhui" }
Fk:loadTranslationTable{
  ["ol__jiachong"] = "贾充",
  ["#ol__jiachong"] = "鲁郡公",
  ["illustrator:ol__jiachong"] = "游漫美绘",

  ["~ol__jiachong"] = "任元褒，吾与汝势不两立！",
}

General:new(extension, "wangxiang", "jin", 3):addSkills { "bingxin" }
Fk:loadTranslationTable{
  ["wangxiang"] = "王祥",
  ["#wangxiang"] = "沂川跃鲤",
  ["illustrator:wangxiang"] = "KY",

  ["~wangxiang"] = "夫生之有死，自然之理也。",
}

--约：杨艳 杨芷
General:new(extension, "yangyan", "jin", 3, 3, General.Female):addSkills { "xuanbei", "xianwan" }
Fk:loadTranslationTable{
  ["yangyan"] = "杨艳",
  ["#yangyan"] = "武元皇后",
  ["illustrator:yangyan"] = "游漫美绘",

  ["~yangyan"] = "一旦殂损，痛悼伤怀……",
}

General:new(extension, "yangzhi", "jin", 3, 3, General.Female):addSkills { "wanyi", "maihuo" }
Fk:loadTranslationTable{
  ["yangzhi"] = "杨芷",
  ["#yangzhi"] = "武悼皇后",
  ["illustrator:yangzhi"] = "游漫美绘",

  ["~yangzhi"] = "贾氏……构陷……",
}

--牢衍

return extension
