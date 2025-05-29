local extension = Package:new("ol_menfa")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/menfa/skills")

Fk:loadTranslationTable{
  ["ol_menfa"] = "OL-门阀士族",
  ["olz"] = "宗族",
}

--颍川荀氏：荀淑 荀谌 荀采 荀粲 荀攸
General:new(extension, "olz__xunshu", "qun", 3):addSkills { "shenjun", "balong", "daojie" }
Fk:loadTranslationTable{
  ["olz__xunshu"] = "族荀淑",
  ["#olz__xunshu"] = "长儒赡宗",
  ["designer:olz__xunshu"] = "玄蝶既白",
  ["illustrator:olz__xunshu"] = "凡果",

  ["$daojie_olz__xunshu1"] = "荀人如玉，向节而生。",
  ["$daojie_olz__xunshu2"] = "竹有其节，焚之不改。",
  ["~olz__xunshu"] = "天下陆沉，荀氏难支……",
}

General:new(extension, "olz__xunchen", "qun", 3):addSkills { "sankuang", "beishi", "daojie" }
Fk:loadTranslationTable{
  ["olz__xunchen"] = "族荀谌",
  ["#olz__xunchen"] = "挈怯恇恇",
  ["designer:olz__xunchen"] = "玄蝶既白",
  ["illustrator:olz__xunchen"] = "凡果",

  ["$daojie_olz__xunchen1"] = "此生所重者，慷慨之节也。",
  ["$daojie_olz__xunchen2"] = "愿以此身，全清尚之节。",
  ["~olz__xunchen"] = "行二臣之为，羞见列祖……",
}

General:new(extension, "olz__xuncai", "qun", 3, 3, General.Female):addSkills { "lieshi", "dianzhan", "huanyin", "daojie" }
Fk:loadTranslationTable{
  ["olz__xuncai"] = "族荀采",
  ["#olz__xuncai"] = "怀刃自誓",
  ["designer:olz__xuncai"] = "玄蝶既白",
  ["illustrator:olz__xuncai"] = "凡果",

  ["$daojie_olz__xuncai1"] = "女子有节，宁死蹈之。",
  ["$daojie_olz__xuncai2"] = "荀氏三纲，死不贰嫁。",
  ["~olz__xuncai"] = "苦难已过，世间大好……",
}

General:new(extension, "olz__xuncan", "wei", 3):addSkills { "yushen", "shangshen", "fenchai", "daojie" }
Fk:loadTranslationTable{
  ["olz__xuncan"] = "族荀粲",
  ["#olz__xuncan"] = "分钗断带",
  ["designer:olz__xuncan"] = "玄蝶既白",
  ["illustrator:olz__xuncan"] = "凡果",

  ["$daojie_olz__xuncan1"] = "君子持节，何移情乎？",
  ["$daojie_olz__xuncan2"] = "我心慕鸳，从一而终。",
  ["~olz__xuncan"] = "此钗，今日可合乎？",
}

local xunyou = General:new(extension, "olz__xunyou", "wei", 3)
xunyou:addSkills { "baichu", "daojie" }
xunyou:addRelatedSkill("qice")
Fk:loadTranslationTable{
  ["olz__xunyou"] = "族荀攸",
  ["#olz__xunyou"] = "慨然入幕",
  ["designer:olz__xunyou"] = "玄蝶既白",
  ["illustrator:olz__xunyou"] = "错落宇宙",

  ["$daojie_olz__xunyou1"] = "秉忠正之心，可抚宁内外。",
  ["$daojie_olz__xunyou2"] = "贤者，温良恭俭让以得之。",
  ["$qice_olz__xunyou1"] = "二袁相争，此曹公得利之时。",
  ["$qice_olz__xunyou2"] = "穷寇宜追，需防死蛇之不僵。",
  ["~olz__xunyou"] = "吾知命之寿，明知命之节……",
}

General:new(extension, "olz__xunshuang", "qun", 3):addSkills { "yangji", "dandao", "qingli", "daojie" }
Fk:loadTranslationTable{
  ["olz__xunshuang"] = "族荀爽",
  --["#olz__xunshuang"] = "",

  ["~olz__xunshuang"] = "",
}

--陈留吴氏：吴苋 吴班 吴匡 吴乔
General:new(extension, "olz__wuxian", "shu", 3, 3, General.Female):addSkills { "yirong", "guixiang", "muyin" }
Fk:loadTranslationTable{
  ["olz__wuxian"] = "族吴苋",
  ["#olz__wuxian"] = "庄姝晏晏",
  ["designer:olz__wuxian"] = "玄蝶既白",
  ["illustrator:olz__wuxian"] = "君桓文化",

  ["$muyin_olz__wuxian1"] = "吴门隆盛，闻钟而鼎食。",
  ["$muyin_olz__wuxian2"] = "吴氏一族，感明君青睐。",
  ["~olz__wuxian"] = "玄德东征，何日归还？",
}

General:new(extension, "olz__wuban", "shu", 4):addSkills { "zhanding", "muyin" }
Fk:loadTranslationTable{
  ["olz__wuban"] = "族吴班",
  ["#olz__wuban"] = "豪侠督进",
  ["designer:olz__wuban"] = "大宝",
  ["illustrator:olz__wuban"] = "匠人绘",

  ["$muyin_olz__wuban1"] = "世代佐忠义，子孙何绝焉？",
  ["$muyin_olz__wuban2"] = "祖训秉心，其荫何能薄也？",
  ["~olz__wuban"] = "无胆鼠辈，安敢暗箭伤人……",
}

General:new(extension, "olz__wukuang", "qun", 4):addSkills { "lianzhuw", "muyin" }
Fk:loadTranslationTable{
  ["olz__wukuang"] = "族吴匡",
  ["#olz__wukuang"] = "诛绝宦竖",
  ["designer:olz__wukuang"] = "玄蝶既白",
  ["illustrator:olz__wukuang"] = "匠人绘",

  ["$muyin_olz__wukuang1"] = "家有贵女，其德泽三代。",
  ["$muyin_olz__wukuang2"] = "吾家当以此女而兴之。",
  ["~olz__wukuang"] = "孟德何在？本初何在？",
}

General:new(extension, "olz__wuqiao", "qun", 4):addSkills { "qiajue", "muyin" }
Fk:loadTranslationTable{
  ["olz__wuqiao"] = "族吴乔",
  ["#olz__wuqiao"] = "孤节卅岁",
  ["designer:olz__wuqiao"] = "玄蝶既白",
  ["illustrator:olz__wuqiao"] = "君桓文化",

  ["$muyin_olz__wuqiao1"] = "生继汉泽于身，死效忠义于行。",
  ["$muyin_olz__wuqiao2"] = "吾祖彰汉室之荣，今子孙未敢忘。",
  ["~olz__wuqiao"] = "蜀川万里，孤身伶仃……",
}

--颍川韩氏：韩韶 韩融
General:new(extension, "olz__hanshao", "qun", 3):addSkills { "fangzhen", "liuju", "xumin" }
Fk:loadTranslationTable{
  ["olz__hanshao"] = "族韩韶",
  ["#olz__hanshao"] = "分投急所",
  ["designer:olz__hanshao"] = "玄蝶既白",
  ["illustrator:olz__hanshao"] = "鬼画府",

  ["$xumin_olz__hanshao1"] = "民者，居野而多艰，不可不恤。",
  ["$xumin_olz__hanshao2"] = "天下之本，上为君，下为民。",
  ["~olz__hanshao"] = "天地不仁，万物何辜……",
}

General:new(extension, "olz__hanrong", "qun", 3):addSkills { "lianhe", "huanjia", "xumin" }
Fk:loadTranslationTable{
  ["olz__hanrong"] = "族韩融",
  ["#olz__hanrong"] = "虎口扳渡",
  ["designer:olz__hanrong"] = "玄蝶既白",
  ["illustrator:olz__hanrong"] = "鬼画府",

  ["$xumin_olz__hanrong1"] = "江海陆沉，皆为黎庶之泪。",
  ["$xumin_olz__hanrong2"] = "天下汹汹，百姓何辜？",
  ["~olz__hanrong"] = "天下兴亡，皆苦百姓……",
}

--颍川钟氏：钟琰 钟毓 钟会 钟繇
General:new(extension, "olz__zhongyan", "jin", 3, 3, General.Female):addSkills { "guangu", "xiaoyong", "baozu" }
Fk:loadTranslationTable{
  ["olz__zhongyan"] = "族钟琰",
  ["#olz__zhongyan"] = "紫闼飞莺",
  ["designer:olz__zhongyan"] = "玄蝶既白",
  ["illustrator:olz__zhongyan"] = "凡果",

  ["$baozu_olz__zhongyan1"] = "好女宜家，可度大厄。",
  ["$baozu_olz__zhongyan2"] = "宗族有难，当施以援手。",
  ["~olz__zhongyan"] = "此间天下人，皆分一斗之才……",
}

General:new(extension, "olz__zhongyu", "wei", 3):addSkills { "jiejian", "huanghan", "baozu" }
Fk:loadTranslationTable{
  ["olz__zhongyu"] = "族钟毓",
  ["#olz__zhongyu"] = "础润殷忧",
  ["designer:olz__zhongyu"] = "玄蝶既白",
  ["illustrator:olz__zhongyu"] = "匠人绘",

  ["$baozu_olz__zhongyu1"] = "弟会腹有恶谋，不可不防。",
  ["$baozu_olz__zhongyu2"] = "会期大祸将至，请晋公恕之。",
  ["~olz__zhongyu"] = "百年钟氏，一朝为尘矣……",
}

General:new(extension, "olz__zhonghui", "wei", 3, 4):addSkills { "yuzhi", "xieshu", "baozu" }
Fk:loadTranslationTable{
  ["olz__zhonghui"] = "族钟会",
  ["#olz__zhonghui"] = "百巧惎",
  ["designer:olz__zhonghui"] = "玄蝶既白",
  ["illustrator:olz__zhonghui"] = "黯荧岛",

  ["$baozu_olz__zhonghui1"] = "不为刀下脍，且做俎上刀。",
  ["$baozu_olz__zhonghui2"] = "吾族恒大，谁敢欺之？",
  ["$baozu_olz__zhonghui3"] = "动我钟家的人，哼，你长了几个脑袋？",
  ["$baozu_olz__zhonghui4"] = "有我在一日，谁也动不得吾族分毫。",
  ["$baozu_olz__zhonghui5"] = "钟门欲屹万年，当先居万人之上。",
  ["$baozu_olz__zhonghui6"] = "诸位同门，随我钟会赌一遭如何？",
  ["~olz__zhonghui"] = "谋事在人，成事在天……",
}

General:new(extension, "olz__zhongyao", "wei", 3):addSkills { "chengqi", "jieli", "baozu" }
Fk:loadTranslationTable{
  ["olz__zhongyao"] = "族钟繇",
  ["#olz__zhongyao"] = "开达理干",
  ["designer:olz__zhongyao"] = "张浩",
  ["illustrator:olz__zhongyao"] = "alien",

  ["$baozu_olz__zhongyao1"] = "立规定矩，教习钟门之材。",
  ["$baozu_olz__zhongyao2"] = "放任纨绔，于族是祸非福。",
  ["~olz__zhongyao"] = "幼子得宠而无忌，恐生无妄之祸……",
}

--太原王氏：王允 王淩 王昶 王浑 王沦 王沈
General:new(extension, "olz__wangyun", "qun", 3):addSkills { "jiexuan", "mingjiew", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangyun"] = "族王允",
  ["#olz__wangyun"] = "曷丧偕亡",
  ["designer:olz__wangyun"] = "玄蝶既白",
  ["illustrator:olz__wangyun"] = "君桓文化",

  ["$zhongliu_olz__wangyun1"] = "国朝汹汹如涌，当如柱石镇之。",
  ["$zhongliu_olz__wangyun2"] = "砥中流之柱，其舍我复谁？",
  ["~olz__wangyun"] = "获罪于君，当伏大辟以谢天下……",
}

General:new(extension, "olz__wangling", "wei", 4):addSkills { "bolong", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangling"] = "族王淩",
  ["#olz__wangling"] = "荧惑守斗",
  ["designer:olz__wangling"] = "玄蝶既白",
  ["illustrator:olz__wangling"] = "君桓文化",

  ["$zhongliu_olz__wangling1"] = "王门世代骨鲠，皆为国之柱石。",
  ["$zhongliu_olz__wangling2"] = "行舟至中流而遇浪，大风起兮。",
  ["~olz__wangling"] = "淩忠心可鉴，死亦未悔……",
}

General:new(extension, "olz__wangchang", "wei", 4):addSkills { "ol__kaiji", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangchang"] = "族王昶",
  ["#olz__wangchang"] = "治论识度",
  ["designer:olz__wangchang"] = "玄蝶既白",
  ["illustrator:olz__wangchang"] = "游漫美绘",

  ["$zhongliu_olz__wangchang1"] = "吾族以国为重，故可为之中流。",
  ["$zhongliu_olz__wangchang2"] = "柱国之重担，击水之中流。",
  ["~olz__wangchang"] = "大任未继，如何长眠九泉……",
}

General:new(extension, "olz__wanghun", "jin", 3):addSkills { "fuxun", "chenya", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wanghun"] = "族王浑",
  ["#olz__wanghun"] = "献捷横江",
  ["designer:olz__wanghun"] = "扬林",
  ["illustrator:olz__wanghun"] = "匠人绘",

  ["$zhongliu_olz__wanghun1"] = "国潮汹涌，当为中流之砥柱。",
  ["$zhongliu_olz__wanghun2"] = "执剑斩巨浪，息风波者出我辈。",
  ["~olz__wanghun"] = "灭国之功本属我，奈何枉作他人衣……",
}

local wanglun = General:new(extension, "olz__wanglun", "wei", 3)
wanglun.subkingdom = "jin"
wanglun:addSkills { "qiuxin", "jianyuan", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wanglun"] = "族王沦",
  ["#olz__wanglun"] = "半缘修道",
  ["designer:olz__wanglun"] = "玄蝶既白",
  ["illustrator:olz__wanglun"] = "君桓文化",

  ["$zhongliu_olz__wanglun1"] = "上善若水，中流而引全局。",
  ["$zhongliu_olz__wanglun2"] = "泽物无声，此真名士风流。",
  ["~olz__wanglun"] = "人间多锦绣，奈何我云不喜……",
}

General:new(extension, "olz__wangshen", "wei", 3):addSkills { "anran", "gaobian", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangshen"] = "族王沈",
  ["#olz__wangshen"] = "崇虎田光",
  ["designer:olz__wangshen"] = "食茸",

  ["$zhongliu_olz__wangshen1"] = "活水驱沧海，天下大势不可违！",
  ["$zhongliu_olz__wangshen2"] = "志随中流之水，可济沧海之云帆！",
  ["~olz__wangshen"] = "我有从龙之志，何惧万世骂名！",
}

General:new(extension, "olz__wangguang", "wei", 3):addSkills { "lilun", "jianjiw", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangguang"] = "族王广",
  ["#olz__wangguang"] = "才性离异",
  ["designer:olz__wangguang"] = "廷玉",
  --["illustrator:olz__wangguang"] = "",

  ["$zhongliu_olz__wangguang1"] = "",
  ["$zhongliu_olz__wangguang2"] = "",
  ["~olz__wangguang"] = "",
}

General:new(extension, "olz__wangmingshan", "wei", 3):addSkills { "tanque", "shengmo", "zhongliu" }
Fk:loadTranslationTable{
  ["olz__wangmingshan"] = "族王明山",
  ["#olz__wangmingshan"] = "擅书多艺",
  ["designer:olz__wangmingshan"] = "那个背影",
  --["illustrator:olz__wangmingshan"] = "",

  ["$zhongliu_olz__wangmingshan1"] = "",
  ["$zhongliu_olz__wangmingshan2"] = "",
  ["~olz__wangmingshan"] = "",
}

Fk:loadTranslationTable{
  ["olz__wangjiw"] = "族王机",
  ["#olz__wangjiw"] = "寒花疏寂",
}

--弘农杨氏：杨赐 杨修 杨众 杨彪
General:new(extension, "olz__yangci", "qun", 3):addSkills { "qieyi", "jianzhi", "quhuo" }
Fk:loadTranslationTable{
  ["olz__yangci"] = "族杨赐",
  ["#olz__yangci"] = "固世笃忠贞",
  --["illustrator:olz__yangci"] = "",

  ["$quhuo_olz__yangci1"] = "为师为父，所在授业解惑。",
  ["$quhuo_olz__yangci2"] = "荧惑守心，宋景退殿，唯德可祛蛇变。",
  ["~olz__yangci"] = "泰山颓，梁木坏，哲人菱。",
}

General:new(extension, "olz__yangxiu", "wei", 3):addSkills { "jiewu", "gaoshi", "quhuo" }
Fk:loadTranslationTable{
  ["olz__yangxiu"] = "族杨修",
  ["#olz__yangxiu"] = "皓首邀终始",
  --["illustrator:olz__yangxiu"] = "",

  ["$quhuo_olz__yangxiu1"] = "非鱼非我，惟知君侯心意而已。",
  ["$quhuo_olz__yangxiu2"] = "依我所教，答记方能无有疑惑。",
  ["~olz__yangxiu"] = "空晓事而未见老，枉少作而愧对君……",
}

General:new(extension, "olz__yangzhongh", "qun", 4):addSkills { "juetu", "kudu", "quhuo" }
Fk:loadTranslationTable{
  ["olz__yangzhongh"] = "族杨众",
  --["#olz__yangzhongh"] = "",
  --["illustrator:olz__yangzhongh"] = "",

  ["$quhuo_olz__yangzhongh1"] = "",
  ["$quhuo_olz__yangzhongh2"] = "",
  ["~olz__yangzhongh"] = "",
}

General:new(extension, "olz__yangbiao", "qun", 3):addSkills { "jiannan", "yichi", "quhuo" }
Fk:loadTranslationTable{
  ["olz__yangbiao"] = "族杨彪",
  --["#olz__yangbiao"] = "",
  --["illustrator:olz__yangbiao"] = "",

  ["$quhuo_olz__yangbiao1"] = "",
  ["$quhuo_olz__yangbiao2"] = "",
  ["~olz__yangbiao"] = "",
}

--吴郡陆氏：
General:new(extension, "olz__lujing", "wu", 4):addSkills { "ol__tanfeng", "juewei", "zelie" }
Fk:loadTranslationTable{
  ["olz__lujing"] = "族陆景",
  --["#olz__lujing"] = "",
  --["illustrator:olz__lujing"] = "",

  ["$zelie_olz__lujing1"] = "",
  ["$zelie_olz__lujing2"] = "",
  ["~olz__lujing"] = "",
}

General:new(extension, "olz__luji", "wu", 3):addSkills { "gailan", "fennu", "zelie" }
Fk:loadTranslationTable{
  ["olz__luji"] = "族陆绩",
  --["#olz__luji"] = "",
  --["illustrator:olz__luji"] = "",

  ["$zelie_olz__luji1"] = "",
  ["$zelie_olz__luji2"] = "",
  ["~olz__luji"] = "",
}

return extension
