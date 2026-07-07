import html
import json
import pathlib
import re
import time
import urllib.parse
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "lord-of-mysteries-potions-characteristics-artifacts.md"
API_TITLE = "Module:Sequence/standard"
API_URL = (
    "https://lordofthemysteries.fandom.com/api.php?action=query&prop=revisions"
    "&rvprop=content&rvslots=main&titles="
    + urllib.parse.quote(API_TITLE)
    + "&format=json"
)


PATH_ORDER = [
    ("Fool Pathway", "愚者/占卜家途径"),
    ("Error Pathway", "错误/偷盗者途径"),
    ("Door Pathway", "门/学徒途径"),
    ("Visionary Pathway", "空想家/观众途径"),
    ("Sun Pathway", "太阳途径"),
    ("Tyrant Pathway", "暴君/水手途径"),
    ("White Tower Pathway", "白塔/阅读者途径"),
    ("Hanged Man Pathway", "倒吊人/秘祈人途径"),
    ("Darkness Pathway", "黑夜/不眠者途径"),
    ("Death Pathway", "死神/收尸人途径"),
    ("Twilight Giant Pathway", "黄昏巨人/战士途径"),
    ("Demoness Pathway", "魔女/刺客途径"),
    ("Red Priest Pathway", "红祭司/猎人途径"),
    ("Hermit Pathway", "隐者/窥秘人途径"),
    ("Paragon Pathway", "完美者/通识者途径"),
    ("Wheel of Fortune Pathway", "命运之轮/怪物途径"),
    ("Mother Pathway", "母亲/耕种者途径"),
    ("Moon Pathway", "月亮/药师途径"),
    ("Abyss Pathway", "深渊/罪犯途径"),
    ("Chained Pathway", "被缚者/囚犯途径"),
    ("Black Emperor Pathway", "黑皇帝/律师途径"),
    ("Justiciar Pathway", "审判者/仲裁人途径"),
]


SEALED_ARTIFACTS = [
    ("0-08", "阿勒苏霍德之笔 / Quill of Alzuhod", "羽毛笔", "写下具备可能性的事件后，通过巧合推动其发生；知晓者越了解它，它也越了解知晓者。", "会反噬并试图杀死使用者；廷根悲剧幕后核心。", "鲁恩王国、廷根终局、因斯线。"),
    ("0-05", "魔法许愿神灯 / Magic Wishing Lamp", "金色神灯", "可实现愿望。", "愿望会被扭曲实现，越往后越危险。", "高阶剧情和旧日层级参考。"),
    ("0-02", "特伦索斯特黄铜书 / Trunsoest Brass Book", "黄铜书", "制定法律，违者遭受规则惩罚。", "会不断写入新法律，使用者也可能受困。", "黑皇帝/审判者相关规则道具。"),
    ("0-62", "星之杖 / Staff of the Stars", "镶宝石黑杖", "定位并降临目的地，可重现脑中对应人物或能力。", "无人持有且未封印时会引发不可预测异常。", "门途径、星空、空间副本。"),
    ("0-61", "旧日之盒 / Box of the Great Old Ones", "三层珠宝盒", "可替换空间、随机传送到危险区域，并封存更高危事物。", "持有者可能随机消失、死亡或被替换。", "高阶异常容器。"),
    ("0-17", "隐秘天使 / Angel of Concealment", "黑眼女性形象", "抹除目标，可作为黑夜途径神降容器。", "能力波动且不可控。", "黑夜教会高阶封印物。"),
    ("1 级", "安提哥努斯家族笔记 / Antigonus Family's Notebook", "黑色硬皮书", "记录安提哥努斯家族遗产和高危知识。", "阅读者会被隐秘腐蚀。", "廷根篇核心物品。"),
    ("1-42", "狂战士铠甲 / Berserker's Armor", "银色全身甲", "给予强大力量、防御和追踪能力。", "久用会受冰冷银化侵蚀。", "高危战斗装备。"),
    ("1-63", "古老镀银镜", "银镜", "形成只针对非凡者的镜中世界。", "负面效果待核对。", "镜像副本。"),
    ("1-82", "乌洛琉斯雕像 / Ullamos Statue", "乳白石像", "引诱附近生物沉迷，传播疾病并制造痛苦梦魇环境。", "强污染环境。", "高阶污染场景。"),
    ("2-049", "安提哥努斯家族木偶 / Antigonus Family Puppet", "红黄小丑脸木偶", "让附近人员身体和思维变迟缓。", "影响所有人，包括使用者。", "廷根篇规则战核心。"),
    ("2-037", "永恒之梦 / Dream of Eternity", "黑暗心脏", "将多人拉入同一梦境。", "大范围使用会留下严重精神创伤。", "梦境副本。"),
    ("2-247", "傲慢铠甲 / Pride Armor", "银白全身甲", "赋予黎明骑士类能力。", "会攻击背后/隐匿目标，带来背叛和反噬。", "黄昏巨人装备。"),
    ("2-078", "死亡之门 / Door of Death", "伪装木门", "穿过者死亡。", "会逃离并伪装成普通门。", "地图陷阱。"),
    ("2-081", "钻石戒指", "镶小钻戒指", "模仿见过的非凡能力，识别能力和物品。", "过度使用损伤大脑。", "临时复制能力。"),
    ("2-105", "血管窃贼 / Blood Vessel Thief", "僵硬粗血管", "短暂偷取目标能力。", "消耗使用者寿命。", "偷盗者玩法。"),
    ("无编号", "海神权杖 / Word of the Sea", "黑色镶银手杖", "闪电、风、水、酸雨、水下呼吸、飞行等海洋/风暴能力。", "会唱危险歌曲、攻击使用者并吸引雷击。", "五海、拜亚姆、海神线。"),
    ("无编号", "蠕动的饥饿 / Creeping Hunger", "人皮薄手套", "使用储存灵魂的非凡能力，藏入阴影，制造血肉炸弹。", "每 24 小时吞噬一人的血肉与灵魂，并赞美真实造物主。", "格尔曼线重要装备。"),
    ("无编号", "死亡丧钟 / Death Knell", "铁黑左轮", "自动瞄准弱点，提升伤害，具霰弹效果。", "使用者获得随机恐惧症并持续口渴。", "海上冒险武器。"),
    ("无编号", "莱曼诺旅行笔记 / Leymano's Travels", "铜绿色硬壳笔记本", "复制见过的非凡能力，之后一次性使用。", "使用者容易迷路。", "技能卡/卷轴系统。"),
    ("3-1328", "水晶之眼 / Eye of Crystal", "单片眼镜", "直接看见灵体、幽魂、阴影。", "吸引怨灵和阴影，久戴损伤视力。", "早期灵视装备。"),
    ("3-0782", "变异太阳圣徽 / Mutated Sun Sacred Emblem", "暗金太阳徽章", "净化范围内有意识生物。", "久用会转为太阳崇拜的愚钝者。", "低阶净化物。"),
    ("3-0625", "厄运布偶 / Misfortune Cloth Puppet", "穿王袍布偶", "给附近人员带来厄运。", "使用者也受影响。", "命运/概率道具。"),
    ("无编号", "万能钥匙 / Master Key", "黄铜钥匙", "穿墙，打开非神秘保护锁。", "容易迷路，满月会听见门先生呼喊。", "探索道具。"),
]


def fetch_module() -> str:
    last_error = None
    for attempt in range(8):
        try:
            req = urllib.request.Request(
                API_URL,
                headers={
                    "User-Agent": "Mozilla/5.0",
                    "Accept-Encoding": "identity",
                    "Connection": "close",
                },
            )
            raw = urllib.request.urlopen(req, timeout=90).read()
            data = json.loads(raw.decode("utf-8"))
            return next(iter(data["query"]["pages"].values()))["revisions"][0]["slots"]["main"]["*"]
        except Exception as exc:
            last_error = exc
            print(f"fetch attempt {attempt + 1} failed: {exc!r}")
            time.sleep(1.5)
    raise RuntimeError(f"failed to fetch sequence module: {last_error!r}")


def find_blocks(text: str):
    blocks = []
    pat = re.compile(r"\n\s*\['([^']+)'\]\s*=\s*\{")
    for match in pat.finditer(text):
        start = match.end() - 1
        depth = 0
        i = start
        quote = None
        long_end = None
        escaped = False
        while i < len(text):
            if long_end:
                end_index = text.find(long_end, i)
                if end_index < 0:
                    break
                i = end_index + len(long_end)
                long_end = None
                continue
            if quote:
                if escaped:
                    escaped = False
                elif text[i] == "\\":
                    escaped = True
                elif text[i] == quote:
                    quote = None
                i += 1
                continue
            if text.startswith("[[", i):
                long_end = "]]"
                i += 2
                continue
            long_match = re.match(r"\[(=*)\[", text[i:])
            if long_match:
                long_end = "]" + long_match.group(1) + "]"
                i += len(long_match.group(0))
                continue
            char = text[i]
            if char in ("'", '"'):
                quote = char
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    block = text[start : i + 1]
                    if "['pathway']" in block and "['seq_rank']" in block:
                        blocks.append((match.group(1), block))
                    break
            i += 1
    return blocks


def parse_value(block: str, key: str) -> str:
    match = re.search(r"\['" + re.escape(key) + r"'\]\s*=\s*", block)
    if not match:
        return ""
    i = match.end()
    while i < len(block) and block[i].isspace():
        i += 1
    if block.startswith("[=[", i):
        end = block.find("]=]", i + 3)
        return block[i + 3 : end] if end >= 0 else ""
    long_match = re.match(r"\[(=*)\[", block[i:])
    if long_match:
        start = i + len(long_match.group(0))
        end_pat = "]" + long_match.group(1) + "]"
        end = block.find(end_pat, start)
        return block[start:end] if end >= 0 else ""
    if i < len(block) and block[i] in ("'", '"'):
        quote = block[i]
        i += 1
        out = []
        escaped = False
        while i < len(block):
            char = block[i]
            if escaped:
                out.append(char)
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                break
            else:
                out.append(char)
            i += 1
        return "".join(out)
    end = block.find(",", i)
    if end < 0:
        end = block.find("\n", i)
    return block[i:end].strip() if end >= 0 else block[i:].strip()


def clean_wiki(value: str) -> str:
    if not value:
        return "待补充/未公开"
    value = re.sub(r"<ref[^>/]*>.*?</ref>", "", value, flags=re.S)
    value = re.sub(r"<ref[^>]*/>", "", value)
    value = re.sub(r"\{\{Cite Book[^}]*\}\}", "", value)
    value = re.sub(r"\{\{(?:ingr|characteristic)\|([^}|]+)(?:\|[^}]*)?\}\}", r"\1", value)

    def replace_template(match: re.Match) -> str:
        body = match.group(1)
        parts = [part.strip() for part in body.split("|") if part.strip()]
        if len(parts) >= 2:
            return parts[-1]
        return parts[0] if parts else ""

    for _ in range(3):
        value = re.sub(r"\{\{([^{}]+)\}\}", replace_template, value)
    value = re.sub(r"\[\[([^\]|]+)\|([^\]]+)\]\]", r"\2", value)
    value = re.sub(r"\[\[([^\]]+)\]\]", r"\1", value)
    value = value.replace("</li>", "；")
    value = re.sub(r"<li[^>]*>", "", value)
    value = re.sub(r"</?(?:ul|ol|p|br|span|div|small|b|i)[^>]*>", " ", value)
    value = re.sub(r"<[^>]+>", " ", value)
    value = html.unescape(value)
    value = value.replace("\r", " ").replace("\n", " ")
    value = re.sub(r"\s*\uFF1B\s*", "；", value)
    value = re.sub(r"(?:\uFF1B){2,}", "；", value)
    value = re.sub(r"\s+", " ", value).strip(" ；")
    return value or "待补充/未公开"


def build_records(module_text: str):
    records = []
    for sequence_en, block in find_blocks(module_text):
        pathway = parse_value(block, "pathway")
        rank = parse_value(block, "seq_rank")
        if not pathway or not rank:
            continue
        ritual_raw = parse_value(block, "ritual")
        records.append(
            {
                "sequence_en": sequence_en,
                "pathway": pathway,
                "rank": int(rank),
                "name_cn": parse_value(block, "name_cn") or sequence_en,
                "main": clean_wiki(parse_value(block, "main_ingr")),
                "supp": clean_wiki(parse_value(block, "supp_ingr")),
                "ritual": clean_wiki(ritual_raw) if ritual_raw else "无或原资料未列出",
                "characteristic": clean_wiki(parse_value(block, "characteristic")),
            }
        )
    return records


def extract_manual_detail_section() -> str:
    if not DOC.exists():
        return ""
    text = DOC.read_text(encoding="utf-8-sig")
    start = text.find("## 10. 详细设定版扩写")
    if start < 0:
        return ""
    end = text.find("## 11. 参考来源", start)
    if end < 0:
        end = text.find("## 10. 参考来源", start)
    if end < 0:
        return text[start:].strip()
    return text[start:end].strip()


def build_document(records, manual_detail: str = "") -> str:
    by_path = {path: [] for path, _ in PATH_ORDER}
    for record in records:
        by_path.setdefault(record["pathway"], []).append(record)
    for path_records in by_path.values():
        path_records.sort(key=lambda item: item["rank"], reverse=True)

    lines = [
        "# 《诡秘之主》魔药、非凡特性与封印物资料档案",
        "",
        "> 用途：为本项目记录《诡秘之主》游戏改编中会用到的魔药配方、非凡特性规则、封印物/神奇物品资料。",
        "> 项目性质：个人学习与个人游玩用资料整理。",
        "> 整理日期：2026-07-06。",
        "> 数据状态：第二版资料库，已加入 22 条途径、220 个序列的配方/材料/非凡特性索引；材料名优先保留英文源名，避免翻译误差。",
        "",
        "## 1. 使用说明",
        "",
        "本档案分为三类资料：",
        "",
        "- 魔药配方：记录序列名、主材料、辅助材料、晋升仪式。",
        "- 非凡特性：记录世界观规则、析出/聚合/保存方式、已知外观样例。",
        "- 封印物品：记录封印物等级、能力、负面效果和游戏化备注。",
        "",
        "整理原则：",
        "",
        "- 全途径配方索引来自公开维基模块 `Module:Sequence/standard` 的结构化资料。",
        "- 序列中文名直接记录；材料名暂保留英文源名，后续可以逐条翻译成本项目统一中文。",
        "- 原资料未列出主材料、辅助材料或仪式的条目，标注为“待补充/未公开”。",
        "- 同序列非凡特性通常可作为核心材料替代来源，但使用特性晋升会带来更高精神烙印和失控风险。",
        "",
        "## 2. 魔药体系基础",
        "",
        "魔药是非凡者晋升的主要方式。一个标准魔药配方通常包含：",
        "",
        "- 主材料：承载对应序列力量的核心材料，很多时候可以用同序列的非凡特性替代。",
        "- 辅助材料：稳定状态、缓冲精神冲击、提高成功率，多数低序列辅助材料本身不一定有强灵性。",
        "- 晋升仪式：从序列 5 开始通常需要仪式。仪式本质上用于平衡污染、稳定人格、建立锚点或满足序列象征。",
        "- 扮演法：服食魔药后通过符合序列名称和象征的行为消化魔药，降低失控风险。",
        "",
        "游戏化建议：",
        "",
        "- 主材料可以作为任务核心奖励。",
        "- 辅助材料可以由黑市、值夜者仓库、采集、委托任务获得。",
        "- 非凡特性可以作为更危险但更直接的替代材料。",
        "- 晋升仪式应设计成剧情任务，而不是单纯点击升级。",
        "",
        "## 3. 全 22 途径魔药配方索引",
        "",
        "本节按 22 条途径记录序列 9 到序列 0。每个序列包含主材料、辅助材料、晋升仪式和已知非凡特性描述。",
        "",
    ]

    for index, (pathway_en, pathway_cn) in enumerate(PATH_ORDER, 1):
        lines.append(f"### 3.{index} {pathway_cn} `{pathway_en}`")
        lines.append("")
        for record in by_path.get(pathway_en, []):
            lines.append(f"#### 序列 {record['rank']}：{record['name_cn']} / {record['sequence_en']}")
            lines.append("")
            lines.append(f"- 主材料：{record['main']}")
            lines.append(f"- 辅助材料/核心要求：{record['supp']}")
            lines.append(f"- 晋升仪式：{record['ritual']}")
            lines.append(f"- 非凡特性外观/描述：{record['characteristic']}")
            lines.append("")

    lines.extend(
        [
            "## 4. 配方翻译与本地化待办",
            "",
            "- 将英文材料名逐条翻译成项目统一中文，并保留英文别名。",
            "- 为每种材料补充来源地图，例如鲁恩黑市、五海、神弃之地、南大陆陵寝等。",
            "- 为每种非凡特性补充游戏图标、颜色、污染等级和可否替代魔药主材料。",
            "- 高序列仪式应改写成可玩的剧情任务，不建议做成纯文本条件。",
            "",
            "## 5. 非凡特性规则",
            "",
            "### 5.1 基本定义",
            "",
            "非凡特性是非凡能力的核心来源，源头与最初造物主相关。非凡者、非凡生物、封印物、神奇物品都可能容纳非凡特性。非凡者死亡后，体内非凡特性会析出，并通常带有原拥有者的精神烙印。",
            "",
            "### 5.2 关键规律",
            "",
            "| 规律 | 说明 | 游戏化表达 |",
            "| --- | --- | --- |",
            "| 不灭定律 | 非凡特性不会真正消失，非凡者死亡后会析出。 | 击败非凡敌人后掉落“特性/材料”，但带污染。 |",
            "| 守恒定律 | 同一途径与序列的高层资源总量有限。 | 高序列晋升需要争夺唯一资源。 |",
            "| 聚合定律 | 同途径、相邻途径或兼容途径之间会互相吸引，常表现为命运层面的巧合。 | 玩家持有特性越多，越容易遭遇相关事件或敌人。 |",
            "| 精神烙印 | 死者残留意志会影响后来服食者。 | 使用特性晋升会增加失控风险，需扮演法/锚点压制。 |",
            "| 高序列神性 | 序列 4 起包含更强神性与疯狂风险。 | 半神以上晋升必须做仪式与锚点系统。 |",
            "| 特性活化 | 部分特性可拥有“活着”的性质，甚至形成有意识物品。 | 高级封印物可主动逃离、诱导、攻击或谈判。 |",
            "",
            "### 5.3 保存与处理",
            "",
            "- 生非凡特性比已经调配好的魔药更容易长期保存。",
            "- 若非凡特性缺少正确封印，长时间接触环境或物品，可能与其融合，形成神奇物品或封印物。",
            "- 特性存放环境需要定期更换；安全做法是 24 小时内更换一次，正确封印后可保存数月到数年。",
            "- 已调配魔药不仅人类能吸收，非生命物品也可能“喝掉”魔药并变成封印物。",
            "",
            "## 6. 封印物分级规则",
            "",
            "封印物是拥有强大效果和明显负面代价的超凡物品，通常由非凡特性与物体融合、非凡者失控死亡后遗留，或工匠途径高阶非凡者制作而成。",
            "",
            "| 等级 | 危险度 | 大致对应力量 | 使用限制 |",
            "| --- | --- | --- | --- |",
            "| 0 级 | 极度危险、最高机密 | 天使层级，约序列 1-2 | 不得询问、传播、描述或窥探；通常只封存在最高级地点。 |",
            "| 1 级 | 高度危险 | 圣者层级，约序列 3-4 | 只能有限使用，需要主教、执事等高权限。 |",
            "| 2 级 | 危险 | 中序列，约序列 5-7 | 可谨慎使用；一般需要队长/主教级权限。 |",
            "| 3 级 | 相当危险 | 低序列，约序列 8-9 | 正式成员在多人行动中可申请使用。 |",
            "| 未知级 | 未正式编号或资料不全 | 不定 | 按实际风险处理。 |",
            "",
            "## 7. 重要封印物与神奇物品清单",
            "",
            "| 编号/等级 | 名称 | 外观 | 能力概述 | 负面效果/状态 | 项目用途 |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
    )

    for code, name, appearance, ability, downside, use in SEALED_ARTIFACTS:
        lines.append(f"| {code} | {name} | {appearance} | {ability} | {downside} | {use} |")

    lines.extend(
        [
            "",
            "## 8. 数据化字段建议",
            "",
            "### 8.1 魔药配方字段",
            "",
            "```text",
            "id",
            "pathway",
            "sequence",
            "name_cn",
            "name_en",
            "main_ingredients",
            "replacement_characteristic",
            "supplementary_ingredients",
            "advancement_ritual",
            "acting_method",
            "known_user",
            "source_note",
            "game_stage",
            "```",
            "",
            "### 8.2 非凡特性字段",
            "",
            "```text",
            "id",
            "pathway",
            "sequence",
            "name_cn",
            "appearance",
            "mental_imprint_risk",
            "godhood_level",
            "storage_rule",
            "can_replace_formula",
            "related_artifacts",
            "```",
            "",
            "### 8.3 封印物字段",
            "",
            "```text",
            "id",
            "grade",
            "code",
            "name_cn",
            "name_en",
            "appearance",
            "abilities",
            "downsides",
            "containment_rule",
            "owner_or_status",
            "game_use",
            "```",
            "",
            "## 9. 地图章节优先实装清单",
            "",
            "- 鲁恩王国：占卜家、小丑、不眠者、梦魇、收尸人、通灵者、刺客、教唆者、秘祈人；安提哥努斯家族笔记、2-049、0-08。",
            "- 因蒂斯共和国：通识者/完美者、窥秘人/隐者、罗塞尔相关遗物、机械类封印物。",
            "- 弗萨克帝国：战士/黄昏巨人、猎人/红祭司、黑夜相关封印物、战争类神奇物品。",
            "- 费内波特王国：耕种者/母亲、药师/月亮、生命学派材料、自然仪式物。",
            "- 五海区域：水手/暴君、倒吊人、海神权杖、蠕动的饥饿、死亡丧钟、莱曼诺旅行笔记。",
            "- 南大陆：死神、被缚者、深渊、拜朗遗迹和死神陵寝相关材料。",
            "- 神弃之地：太阳、黄昏巨人、倒吊人、白银城材料、巨人王庭遗物。",
            "- 异空间：门、愚者、错误、空想家、历史迷雾相关高阶材料和唯一性。",
            "",
            "## 11. 参考来源" if manual_detail else "## 10. 参考来源",
            "",
            "- Lord of the Mysteries Wiki: Module:Sequence/standard。  ",
            "  https://lordofthemysteries.fandom.com/wiki/Module:Sequence/standard",
            "- Lord of the Mysteries Wiki: Pathways。  ",
            "  https://lordofthemysteries.fandom.com/wiki/Pathways",
            "- Lord of the Mysteries Wiki: Fool Pathway/Advancement。  ",
            "  https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement",
            "- Lord of the Mysteries Wiki: List of Mysticism Ingredients。  ",
            "  https://lordofthemysteries.fandom.com/wiki/List_of_Mysticism_Ingredients",
            "- Lord of the Mysteries Wiki: Beyonder Characteristics。  ",
            "  https://lordofthemysteries.fandom.com/wiki/Beyonder_Characteristics",
            "- Lord of the Mysteries Wiki: Sealed Artifact。  ",
            "  https://lordofthemysteries.fandom.com/wiki/Sealed_Artifact",
        ]
    )
    text = "\n".join(lines) + "\n"
    if not manual_detail:
        return text
    reference_heading = "## 11. 参考来源"
    return text.replace(reference_heading, manual_detail + "\n\n" + reference_heading, 1)


def main() -> None:
    manual_detail = extract_manual_detail_section()
    module_text = fetch_module()
    records = build_records(module_text)
    if len(records) != 220:
        raise RuntimeError(f"expected 220 records, got {len(records)}")
    DOC.write_text(build_document(records, manual_detail), encoding="utf-8-sig")
    print(f"wrote {DOC} with {len(records)} sequence records")


if __name__ == "__main__":
    main()
