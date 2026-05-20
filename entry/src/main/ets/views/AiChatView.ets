import { promptAction } from '@kit.ArkUI'
import { createId, dayText, money } from '../common/Formatters'
import { AiChatMessage, AiRole, LedgerOperation } from '../model/AiModel'
import { LedgerRecord, RecordType } from '../model/RecordModel'
import { aiService } from '../service/AiService'
import { appStore } from '../store/GlobalStore'

@Component
export struct AiChatView {
  @Link visible: boolean
  @Link refreshTick: number
  @State apiKey: string = ''
  @State apiKeyInput: string = ''
  @State inputText: string = ''
  @State messages: AiChatMessage[] = []
  @State sending: boolean = false
  @State thinkingDots: string = '...'
  @State thinkingAnimating: boolean = false
  @State pageOpacity: number = 0
  @State pageOffsetY: number = 60
  @State keyDialogVisible: boolean = false
  @State keyDialogOpacity: number = 0
  @State keyDialogScale: number = 0.92
  @State pendingOperationVisible: boolean = false
  @State pendingOperation: LedgerOperation = {
    action: 'add_record',
    targetId: '',
    type: RecordType.Expense,
    amount: 0,
    category: '餐饮',
    remark: '',
    time: Date.now(),
    reply: ''
  }

  aboutToAppear(): void {
    this.loadApiKey()
    this.ensureWelcomeMessage()
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.pageOpacity = 1
        this.pageOffsetY = 0
      })
    }, 20)
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.QuickPrompts()
        Scroll() {
          Column() {
            ForEach(this.messages, (message: AiChatMessage) => {
              this.MessageBubble(message)
            }, (message: AiChatMessage) => message.id)
            if (this.pendingOperationVisible) {
              this.LedgerOperationCard()
            }
            if (this.sending) {
              this.LoadingBubble()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .width('100%')
        this.InputBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')
      .opacity(this.pageOpacity)
      .translate({ y: this.pageOffsetY })
      this.ApiKeyDialog()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .fillColor('#2298F2')
        .onClick(() => this.closePage())
      Blank()
      Column() {
        Text('AI 记账助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
        Text(this.apiKey.length > 0 ? 'DeepSeek 已配置' : '点击右侧按钮配置 Key')
          .fontSize(12)
          .fontColor('#7B8794')
          .margin({ top: 2 })
      }
      Blank()
      Button(this.apiKey.length > 0 ? 'API Key' : '设置 Key')
        .width(82)
        .height(32)
        .fontSize(10)
        .fontColor('#2298F2')
        .backgroundColor('#EAF5FF')
        .borderRadius(16)
        .onClick(() => this.openKeyDialog())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#EDF0F5' })
  }

  @Builder
  ApiKeyDialog() {
    if (this.keyDialogVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.keyDialogOpacity)
          .onClick(() => this.closeKeyDialog())
        Column() {
          Row() {
            Text('设置 DeepSeek API Key')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
            Blank()
            Text('关闭')
              .fontSize(14)
              .fontColor('#7B8794')
              .onClick(() => this.closeKeyDialog())
          }
          .width('100%')
          TextInput({ placeholder: '请输入 DeepSeek API Key', text: this.apiKeyInput })
            .height(44)
            .type(InputType.Password)
            .margin({ top: 16 })
            .onChange((value: string) => this.apiKeyInput = value)
          Text('使用 DeepSeek Chat Completions 接口。Key 仅保存在本机本地持久化中，不会写死到源码。')
            .fontSize(12)
            .fontColor('#7B8794')
            .lineHeight(18)
            .width('100%')
            .margin({ top: 10 })
          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(40)
              .fontSize(15)
              .fontColor('#20242A')
              .backgroundColor('#F1F4F8')
              .borderRadius(20)
              .onClick(() => this.closeKeyDialog())
            Button('保存')
              .layoutWeight(1)
              .height(40)
              .fontSize(15)
              .fontColor(Color.White)
              .backgroundColor('#2298F2')
              .borderRadius(20)
              .margin({ left: 10 })
              .onClick(() => this.saveApiKey())
          }
          .width('100%')
          .margin({ top: 18 })
        }
        .width('86%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .opacity(this.keyDialogOpacity)
        .scale({ x: this.keyDialogScale, y: this.keyDialogScale })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  QuickPrompts() {
    Scroll() {
      Row() {
        this.PromptChip('分析本月消费')
        this.PromptChip('记一笔午饭18元')
        this.PromptChip('把刚刚那笔午饭改成20元')
        this.PromptChip('删除刚刚那笔账单')
        this.PromptChip('发工资3000元')
        this.PromptChip('给我预算建议')
        this.PromptChip('最近花销哪里最多')
        this.PromptChip('怎么省钱')
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(48)
    .backgroundColor('#F7F8FA')
  }

  @Builder
  PromptChip(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#2298F2')
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor('#EAF5FF')
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => {
        this.inputText = text
        this.sendMessage()
      })
  }

  @Builder
  MessageBubble(message: AiChatMessage) {
    Row() {
      if (message.role === AiRole.User) {
        Blank()
        Column() {
          Text(message.content)
            .fontSize(14)
            .fontColor(Color.White)
            .lineHeight(21)
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#2298F2')
        .borderRadius(14)
        .constraintSize({ maxWidth: '78%' })
      } else {
        Column() {
          Text(message.content)
            .fontSize(14)
            .fontColor('#182431')
            .lineHeight(21)
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor(Color.White)
        .borderRadius(14)
        .constraintSize({ maxWidth: '78%' })
        .shadow({ radius: 8, color: '#18243112', offsetY: 3 })
        Blank()
      }
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  LedgerOperationCard() {
    Row() {
      Column() {
        Text(this.operationTitle())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .width('100%')
        Row() {
          Text(this.pendingOperation.type === RecordType.Income ? '收入' : '支出')
            .fontSize(12)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.pendingOperation.type === RecordType.Income ? '#00A870' : '#E84026')
            .borderRadius(12)
          Text(this.pendingOperation.category)
            .fontSize(13)
            .fontColor('#59636F')
            .margin({ left: 8 })
          Text(money(this.pendingOperation.amount))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 10 })
        Text(`日期：${dayText(this.pendingOperation.time)}`)
          .fontSize(12)
          .fontColor('#7B8794')
          .width('100%')
          .margin({ top: 8 })
        Text(`备注：${this.pendingOperation.remark.length > 0 ? this.pendingOperation.remark : '无备注'}`)
          .fontSize(12)
          .fontColor('#7B8794')
          .width('100%')
          .margin({ top: 4 })
        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .fontColor('#59636F')
            .backgroundColor('#F1F4F8')
            .borderRadius(18)
            .onClick(() => this.cancelLedgerOperation())
          Button(this.operationButtonText())
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(this.pendingOperation.action === 'delete_record' ? '#E84026' : '#2298F2')
            .borderRadius(18)
            .margin({ left: 10 })
            .onClick(() => this.confirmLedgerOperation())
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .width('78%')
      .padding(14)
      .backgroundColor(Color.White)
      .borderRadius(14)
      .shadow({ radius: 8, color: '#18243112', offsetY: 3 })
      Blank()
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  LoadingBubble() {
    Row() {
      Column() {
        Text(`正在思考${this.thinkingDots}`)
          .fontSize(14)
          .fontColor('#7B8794')
      }
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
      .borderRadius(14)
      .shadow({ radius: 8, color: '#18243112', offsetY: 3 })
      Blank()
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  InputBar() {
    Row() {
      TextInput({ placeholder: this.apiKey.length > 0 ? '问问本月账单、预算或消费建议' : '请先设置 API Key', text: this.inputText })
        .layoutWeight(1)
        .height(42)
        .backgroundColor('#F1F4F8')
        .borderRadius(21)
        .onChange((value: string) => this.inputText = value)
      Button(this.sending ? '发送中' : '发送')
        .width(74)
        .height(42)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(this.canSend() ? '#2298F2' : '#AEB8C4')
        .borderRadius(21)
        .margin({ left: 10 })
        .onClick(() => this.sendMessage())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 14 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#EDF0F5' })
  }

  private async loadApiKey(): Promise<void> {
    this.apiKey = await aiService.getApiKey()
    this.apiKeyInput = this.apiKey
  }

  private openKeyDialog(): void {
    this.apiKeyInput = this.apiKey
    this.keyDialogOpacity = 0
    this.keyDialogScale = 0.92
    this.keyDialogVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.keyDialogOpacity = 1
        this.keyDialogScale = 1
      })
    }, 20)
  }

  private closeKeyDialog(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.keyDialogOpacity = 0
      this.keyDialogScale = 0.94
    })
    setTimeout(() => {
      this.keyDialogVisible = false
      this.apiKeyInput = this.apiKey
    }, 180)
  }

  private ensureWelcomeMessage(): void {
    if (this.messages.length > 0) {
      return
    }
    const message: AiChatMessage = {
      id: createId('ai_welcome'),
      role: AiRole.Assistant,
      content: '你好，我是安心记账 AI 助手。你可以问我本月消费、预算建议，也可以直接说你的需求，例如“午饭花了18元”或“发工资3000元”，我会帮你识别并生成待确认账单。',
      createdAt: Date.now()
    }
    this.messages = [message]
  }

  private canSend(): boolean {
    return this.apiKey.length > 0 && this.inputText.trim().length > 0 && !this.sending
  }

  private async saveApiKey(): Promise<void> {
    const nextKey = this.apiKeyInput.trim()
    if (nextKey.length === 0) {
      promptAction.openToast({ message: '请输入 API Key', duration: 1500 })
      return
    }
    await aiService.saveApiKey(nextKey)
    this.apiKey = nextKey
    this.closeKeyDialog()
    promptAction.openToast({ message: 'DeepSeek API Key 已保存', duration: 1200 })
  }

  private async sendMessage(): Promise<void> {
    const content = this.inputText.trim()
    if (content.length === 0 || this.sending) {
      return
    }
    if (this.apiKey.length === 0) {
      promptAction.openToast({ message: '请先设置 API Key', duration: 1500 })
      this.openKeyDialog()
      return
    }
    const userMessage: AiChatMessage = {
      id: createId('ai_user'),
      role: AiRole.User,
      content,
      createdAt: Date.now()
    }
    const nextMessages: AiChatMessage[] = []
    this.messages.forEach((item: AiChatMessage) => nextMessages.push(item))
    nextMessages.push(userMessage)
    this.messages = nextMessages
    this.inputText = ''
    this.sending = true
    this.startThinkingAnimation()
    try {
      this.pendingOperationVisible = false
      const operation = await aiService.parseLedgerOperation(content)
      if (operation) {
        this.pendingOperation = operation
        this.pendingOperationVisible = true
        const assistantMessage: AiChatMessage = {
          id: createId('ai_operation'),
          role: AiRole.Assistant,
          content: this.operationAssistantText(),
          createdAt: Date.now()
        }
        const draftMessages: AiChatMessage[] = []
        this.messages.forEach((item: AiChatMessage) => draftMessages.push(item))
        draftMessages.push(assistantMessage)
        this.messages = draftMessages
        this.sending = false
        this.thinkingAnimating = false
        return
      }
      const reply = await aiService.chat(this.messages)
      const assistantMessage: AiChatMessage = {
        id: createId('ai_assistant'),
        role: AiRole.Assistant,
        content: reply,
        createdAt: Date.now()
      }
      const updated: AiChatMessage[] = []
      this.messages.forEach((item: AiChatMessage) => updated.push(item))
      updated.push(assistantMessage)
      this.messages = updated
    } catch (error) {
      promptAction.openToast({ message: this.formatErrorMessage(error), duration: 1800 })
    }
    this.sending = false
    this.thinkingAnimating = false
  }

  private async confirmLedgerOperation(): Promise<void> {
    if (!this.pendingOperationVisible || this.pendingOperation.amount <= 0) {
      return
    }
    if (this.pendingOperation.action === 'add_record') {
      await appStore.addRecord(
        this.pendingOperation.type,
        this.pendingOperation.amount,
        this.pendingOperation.category,
        this.pendingOperation.remark,
        this.pendingOperation.time
      )
    } else if (this.pendingOperation.action === 'update_record') {
      const oldRecord = this.findRecordById(this.pendingOperation.targetId)
      if (!oldRecord) {
        promptAction.openToast({ message: '未找到要修改的账单', duration: 1500 })
        return
      }
      const updatedRecord: LedgerRecord = {
        id: oldRecord.id,
        type: this.pendingOperation.type,
        amount: this.pendingOperation.amount,
        category: this.pendingOperation.category,
        remark: this.pendingOperation.remark,
        time: this.pendingOperation.time,
        createdAt: oldRecord.createdAt,
        updatedAt: Date.now()
      }
      await appStore.updateRecord(updatedRecord)
    } else if (this.pendingOperation.action === 'delete_record') {
      const oldRecord = this.findRecordById(this.pendingOperation.targetId)
      if (!oldRecord) {
        promptAction.openToast({ message: '未找到要删除的账单', duration: 1500 })
        return
      }
      await appStore.removeRecord(this.pendingOperation.targetId)
    }
    this.refreshTick += 1
    this.pendingOperationVisible = false
    const message: AiChatMessage = {
      id: createId('ai_record_saved'),
      role: AiRole.Assistant,
      content: this.operationDoneText(),
      createdAt: Date.now()
    }
    const updated: AiChatMessage[] = []
    this.messages.forEach((item: AiChatMessage) => updated.push(item))
    updated.push(message)
    this.messages = updated
    promptAction.openToast({ message: this.operationToastText(), duration: 1500 })
  }

  private cancelLedgerOperation(): void {
    this.pendingOperationVisible = false
    const message: AiChatMessage = {
      id: createId('ai_record_cancel'),
      role: AiRole.Assistant,
      content: '已取消这次账单操作。',
      createdAt: Date.now()
    }
    const updated: AiChatMessage[] = []
    this.messages.forEach((item: AiChatMessage) => updated.push(item))
    updated.push(message)
    this.messages = updated
  }

  private startThinkingAnimation(): void {
    if (this.thinkingAnimating) {
      return
    }
    this.thinkingAnimating = true
    let dotIndex = 0
    const dotList: string[] = ['', '.', '..', '...']
    const tick = () => {
      if (!this.sending) {
        this.thinkingDots = '...'
        this.thinkingAnimating = false
        return
      }
      this.thinkingDots = dotList[dotIndex % dotList.length]
      dotIndex += 1
      setTimeout(tick, 360)
    }
    tick()
  }

  private findRecordById(id: string): LedgerRecord | undefined {
    let record: LedgerRecord | undefined = undefined
    appStore.records.forEach((item: LedgerRecord) => {
      if (item.id === id) {
        record = item
      }
    })
    return record
  }

  private operationTitle(): string {
    if (this.pendingOperation.action === 'update_record') {
      return '确认修改账单'
    }
    if (this.pendingOperation.action === 'delete_record') {
      return '确认删除账单'
    }
    return '确认添加账单'
  }

  private operationButtonText(): string {
    if (this.pendingOperation.action === 'update_record') {
      return '确认修改'
    }
    if (this.pendingOperation.action === 'delete_record') {
      return '确认删除'
    }
    return '确认添加'
  }

  private operationAssistantText(): string {
    if (this.pendingOperation.reply.length > 0) {
      return this.pendingOperation.reply
    }
    if (this.pendingOperation.action === 'update_record') {
      return '我识别到一条修改账单指令，请确认下面的信息，确认后我再帮你更新本地账单。'
    }
    if (this.pendingOperation.action === 'delete_record') {
      return '我识别到一条删除账单指令，请确认下面的信息，确认后我再帮你删除本地账单。'
    }
    return '我识别到一笔新账单，请确认下面的信息，确认后我再帮你写入本地账单。'
  }

  private operationDoneText(): string {
    const typeText = this.pendingOperation.type === RecordType.Income ? '收入' : '支出'
    const recordText = `${typeText}-${this.pendingOperation.category}-${money(this.pendingOperation.amount)}`
    if (this.pendingOperation.action === 'update_record') {
      return `已修改：${recordText}。`
    }
    if (this.pendingOperation.action === 'delete_record') {
      return `已删除：${recordText}。`
    }
    return `已添加：${recordText}。`
  }

  private operationToastText(): string {
    if (this.pendingOperation.action === 'update_record') {
      return '账单已修改'
    }
    if (this.pendingOperation.action === 'delete_record') {
      return '账单已删除'
    }
    return '账单已添加'
  }

  private formatErrorMessage(error: Object): string {
    if (error instanceof Error && error.message.length > 0) {
      return error.message
    }
    const text = String(error)
    if (text.length > 0 && text !== '[object Object]') {
      return text
    }
    const jsonText = JSON.stringify(error)
    if (jsonText.length > 0 && jsonText !== '{}' && jsonText !== 'null') {
      return jsonText
    }
    return 'AI 请求失败，请检查网络或 API Key'
  }

  private closePage(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.pageOpacity = 0
      this.pageOffsetY = 60
    })
    setTimeout(() => {
      this.visible = false
    }, 180)
  }
}
