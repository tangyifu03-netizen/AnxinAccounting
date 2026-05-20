from pathlib import Path
from zipfile import ZipFile

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


PROJECT_DIR = Path(r"E:\DevEcoStudioProjects\universityCompetition")
DESKTOP_DIR = Path(r"E:\Desktop")
OUTPUT_FILE = DESKTOP_DIR / "安心记账_产品操作手册.docx"
SCREENSHOT_FILE = PROJECT_DIR / "screenshots" / "screen_current.jpeg"


def set_font(style, size: float | None = None) -> None:
    style.font.name = "宋体"
    style._element.rPr.rFonts.set(qn("w:eastAsia"), "宋体")
    if size is not None:
      style.font.size = Pt(size)


def add_page_number(paragraph) -> None:
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), "PAGE")
    run._r.append(field)


def add_heading(doc: Document, text: str, level: int = 1) -> None:
    paragraph = doc.add_heading(text, level=level)
    paragraph.paragraph_format.space_before = Pt(8)
    paragraph.paragraph_format.space_after = Pt(6)


def add_paragraph(doc: Document, text: str) -> None:
    paragraph = doc.add_paragraph(text)
    paragraph.paragraph_format.line_spacing = 1.25
    paragraph.paragraph_format.space_after = Pt(4)


def add_number(doc: Document, text: str) -> None:
    paragraph = doc.add_paragraph(text, style="List Number")
    paragraph.paragraph_format.line_spacing = 1.2
    paragraph.paragraph_format.space_after = Pt(2)


def add_bullet(doc: Document, text: str) -> None:
    paragraph = doc.add_paragraph(text, style="List Bullet")
    paragraph.paragraph_format.line_spacing = 1.2
    paragraph.paragraph_format.space_after = Pt(2)


def add_cover(doc: Document) -> None:
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run("安心记账")
    run.bold = True
    run.font.size = Pt(28)
    run.font.color.rgb = RGBColor(34, 152, 242)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("产品操作手册")
    run.bold = True
    run.font.size = Pt(24)

    for line in [
        "适用版本：OpenHarmony 5.0（API 19）",
        "适用对象：应用使用者、评审人员、项目验收人员",
        "文档日期：2026年5月13日",
    ]:
        paragraph = doc.add_paragraph()
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = paragraph.add_run(line)
        run.font.size = Pt(12)

    if SCREENSHOT_FILE.exists():
        doc.add_paragraph()
        image = doc.add_paragraph()
        image.alignment = WD_ALIGN_PARAGRAPH.CENTER
        image.add_run().add_picture(str(SCREENSHOT_FILE), width=Inches(2.5))
        caption = doc.add_paragraph("应用运行界面示例")
        caption.alignment = WD_ALIGN_PARAGRAPH.CENTER

    doc.add_page_break()


def build_manual() -> Document:
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.75)
    section.left_margin = Inches(0.85)
    section.right_margin = Inches(0.85)

    set_font(doc.styles["Normal"], 10.5)
    set_font(doc.styles["Title"], 24)
    set_font(doc.styles["Heading 1"], 16)
    set_font(doc.styles["Heading 2"], 13)
    set_font(doc.styles["Heading 3"], 11)

    add_cover(doc)

    add_heading(doc, "一、产品概述")
    add_paragraph(doc, "安心记账是一款面向日常生活场景的本地记账应用，提供账号登录注册、快捷记账、预算管理、收支报表、个人中心、数据导出和 AI 自然语言记账等功能。应用数据主要保存在设备本地，适合个人用户进行日常收支管理和预算控制。")
    add_paragraph(doc, "产品设计重点围绕“快速录入、实时刷新、清晰统计、预算提醒、数据可控”展开，用户可以在首页完成高频记账操作，在报表页查看消费结构，在预算页设置月预算和分类预算，在个人中心完成资料设置和数据管理。")

    add_heading(doc, "二、运行环境")
    for item in [
        "系统平台：OpenHarmony 5.0，API 19。",
        "开发工具：DevEco Studio 5.1.1。",
        "应用名称：安心记账。",
        "主要能力：ArkTS、ArkUI、本地持久化、状态管理、文件导出、AI 接口调用。",
    ]:
        add_bullet(doc, item)

    add_heading(doc, "三、登录与注册")
    add_heading(doc, "3.1 登录账号", 2)
    for item in [
        "打开应用后进入登录页面。",
        "输入已注册的账号和密码。",
        "点击“登录”按钮。登录成功后，系统显示成功提示，并进入应用首页。",
        "若账号或密码为空、格式错误或密码不正确，页面会给出对应提示。",
    ]:
        add_number(doc, item)

    add_heading(doc, "3.2 注册账号", 2)
    for item in [
        "在登录页面点击“没有账号，去注册”。",
        "进入创建账号页面后，输入账号、密码和确认密码。",
        "点击“注册”按钮。注册成功后，页面返回登录流程，用户需要使用新账号重新登录。",
        "点击页面中的“登录”文字，可返回登录页面。",
    ]:
        add_number(doc, item)

    add_heading(doc, "四、首页记账")
    add_heading(doc, "4.1 查看月度概览", 2)
    add_paragraph(doc, "首页顶部展示当前月份账单，包括本月收入、本月支出和本月结余。数据会根据用户新增、修改、删除账单后自动刷新。")
    add_heading(doc, "4.2 快速记账", 2)
    for item in [
        "在首页“快速记账”区域选择账单类型，可选择“支出”或“收入”。",
        "选择账单分类，例如餐饮、交通、购物、工资、奖金等。",
        "输入金额和备注。",
        "确认记账日期，默认使用当前日期，也可以点击日期选择入口进行调整。",
        "点击“保存”按钮完成记账。保存成功后，首页统计、预算进度和最近记录会同步刷新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "4.3 详细记账与日期查看", 2)
    for item in [
        "点击首页“详细记账”，打开当日账单弹窗。",
        "弹窗中可查看所选日期当天的全部账单记录。",
        "点击日期选择入口，可选择具体日期；日期不能超过当前时间。",
        "点击月份选择入口，可切换查看月份；月份不能超过当前月份。",
        "关闭弹窗后返回首页。",
    ]:
        add_number(doc, item)

    add_heading(doc, "4.4 最近记录管理", 2)
    for item in [
        "首页“最近记录”展示近期账单。",
        "点击“编辑”可打开编辑弹窗，修改类型、分类、金额、备注和日期。",
        "点击“删除”可删除对应账单。",
        "编辑或删除完成后，首页、预算和报表数据会实时刷新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "五、预算管理")
    add_heading(doc, "5.1 设置月预算", 2)
    for item in [
        "进入“预算”页面。",
        "在“设置月预算”区域输入预算金额。",
        "点击“保存”按钮。保存成功后，预算页面会立即刷新总预算、已使用金额和进度条。",
    ]:
        add_number(doc, item)

    add_heading(doc, "5.2 设置分类预算", 2)
    for item in [
        "在“设置分类预算”区域选择分类，例如餐饮、交通、购物等。",
        "输入该分类的预算金额。",
        "点击“保存”按钮。",
        "分类预算会显示在预算列表中，并根据本月该分类支出自动计算使用进度。",
    ]:
        add_number(doc, item)

    add_heading(doc, "5.3 删除分类预算", 2)
    for item in [
        "在分类预算列表中找到需要删除的分类预算。",
        "点击“删除”按钮。",
        "删除成功后，预算页面立即刷新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "5.4 预算预警", 2)
    add_paragraph(doc, "当本月支出达到或超过预算额度时，页面会以醒目的提示和进度状态提醒用户预算已超额，帮助用户及时控制消费。")

    add_heading(doc, "六、收支报表")
    add_heading(doc, "6.1 总览统计", 2)
    add_paragraph(doc, "报表页面展示今日、本周、本月的收入和支出统计，帮助用户快速了解不同时间范围的收支情况。")
    add_heading(doc, "6.2 分类占比", 2)
    add_paragraph(doc, "“分类占比”区域按照账单分类展示本月支出结构，通过进度条和百分比显示各分类占总支出的比例。")
    add_heading(doc, "6.3 近七日趋势", 2)
    add_paragraph(doc, "“近七日趋势”使用柱状图展示最近七天收入与支出的变化。绿色表示收入，红色表示支出。柱状图高度会根据最大金额进行比例计算，避免图形超出显示区域。")

    add_heading(doc, "七、AI 记账助手")
    add_heading(doc, "7.1 配置 API Key", 2)
    for item in [
        "点击底部中间 AI 图标进入“AI 记账助手”。",
        "点击右上角“API Key”或“设置 Key”按钮。",
        "在弹窗中输入 DeepSeek API Key。",
        "点击“保存”。保存后，Key 存储在本地持久化中，不写入源码。",
    ]:
        add_number(doc, item)

    add_heading(doc, "7.2 AI 自然语言新增账单", 2)
    for item in [
        "在输入框中输入自然语言，例如“记一笔午饭18元”。",
        "AI 会识别账单类型、金额、分类、备注和日期，并生成确认卡片。",
        "用户确认无误后点击“确认添加”。",
        "账单写入本地后，首页、预算、报表会同步刷新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "7.3 AI 修改账单", 2)
    for item in [
        "输入修改指令，例如“把刚刚那笔午饭改成20元”。",
        "AI 会从最近账单中识别目标账单，并生成修改确认卡片。",
        "点击“确认修改”后，本地账单数据会更新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "7.4 AI 删除账单", 2)
    for item in [
        "输入删除指令，例如“删除刚刚那笔账单”。",
        "AI 会识别需要删除的账单，并生成删除确认卡片。",
        "点击“确认删除”后，该账单从本地数据中移除。",
    ]:
        add_number(doc, item)

    add_heading(doc, "7.5 AI 查询与分析", 2)
    add_paragraph(doc, "用户可以询问“本月花了多少”“餐饮支出最多吗”“给我预算建议”等问题。AI 会结合当前登录用户信息、账单摘要和预算情况进行回答。")
    if SCREENSHOT_FILE.exists():
        image = doc.add_paragraph()
        image.alignment = WD_ALIGN_PARAGRAPH.CENTER
        image.add_run().add_picture(str(SCREENSHOT_FILE), width=Inches(2.7))
        caption = doc.add_paragraph("图：AI 记账助手界面示例")
        caption.alignment = WD_ALIGN_PARAGRAPH.CENTER

    add_heading(doc, "八、个人中心与设置")
    add_heading(doc, "8.1 查看个人信息", 2)
    add_paragraph(doc, "“我的”页面展示用户头像、昵称、账号、加入时间、本月收入、本月支出、预算额度和账单数量等信息。")
    add_heading(doc, "8.2 设置头像和昵称", 2)
    for item in [
        "进入“我的”页面，点击“设置”。",
        "设置页面包含头像、名字和退出登录三个入口。",
        "点击“头像”可更换用户头像；新用户未设置头像时使用默认头像。",
        "点击“名字”可修改昵称。保存成功后，首页右上角头像和个人中心信息会同步更新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "8.3 退出登录", 2)
    for item in [
        "进入设置页面。",
        "点击“退出登录”。",
        "系统清除当前登录态并返回登录页面。",
    ]:
        add_number(doc, item)

    add_heading(doc, "九、数据管理")
    add_heading(doc, "9.1 清空账单数据", 2)
    for item in [
        "进入“我的”页面的数据管理区域。",
        "点击“清空账单数据”。",
        "确认后，本地账单数据会被清空，首页、报表、预算和个人中心统计同步刷新。",
    ]:
        add_number(doc, item)

    add_heading(doc, "9.2 导出本地数据", 2)
    for item in [
        "进入“我的”页面的数据管理区域。",
        "点击“导出本地数据”。",
        "系统调用文件保存能力，由用户选择保存位置。",
        "导出内容包含当前用户资料、预算配置和账单记录，格式为 JSON，便于备份和检查。",
    ]:
        add_number(doc, item)

    add_heading(doc, "十、使用注意事项")
    for item in [
        "请妥善保管账号密码和 API Key，不要将 API Key 泄露给他人。",
        "AI 记账涉及新增、修改、删除时，均需要用户在确认卡片中二次确认后才会执行。",
        "日期和月份选择不能超过当前时间，避免生成未来账单统计异常。",
        "清空账单数据属于不可逆操作，执行前请确认是否已经完成导出备份。",
        "本应用以本地数据管理为主，卸载应用或清除应用数据可能导致本地账单丢失。",
    ]:
        add_bullet(doc, item)

    add_heading(doc, "十一、常见问题")
    for title, answer in [
        ("11.1 登录后为什么看不到历史数据？", "请确认当前登录的是原账号。若执行过清空数据或清除应用数据，历史账单可能已被删除。"),
        ("11.2 AI 提示请求失败怎么办？", "请检查网络连接和 DeepSeek API Key 是否正确。如果 API Key 为空、无效或额度不足，AI 请求会失败。"),
        ("11.3 为什么 AI 修改或删除账单前需要确认？", "修改和删除会直接影响本地账单数据。为了避免误操作，应用会先展示确认卡片，用户确认后才执行。"),
        ("11.4 导出文件在哪里？", "导出时由系统文件保存界面决定保存位置。用户需要在弹出的保存界面中选择目录并确认保存，因此文件位置以用户选择的位置为准。"),
    ]:
        add_heading(doc, title, 2)
        add_paragraph(doc, answer)

    for section in doc.sections:
        add_page_number(section.footer.paragraphs[0])

    return doc


def validate_docx(path: Path) -> None:
    with ZipFile(path) as archive:
        xml = archive.read("word/document.xml").decode("utf-8")
    question_count = xml.count("?")
    if question_count > 10:
        raise RuntimeError(f"文档疑似编码异常，问号数量：{question_count}")


def main() -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    document = build_manual()
    document.save(OUTPUT_FILE)
    validate_docx(OUTPUT_FILE)
    print(OUTPUT_FILE)


if __name__ == "__main__":
    main()
