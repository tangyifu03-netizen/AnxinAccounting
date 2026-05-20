import { promptAction } from '@kit.ArkUI'
import { dayText, money } from '../common/Formatters'
import { CategoryBudget, EXPENSE_CATEGORIES, INCOME_CATEGORIES, LedgerRecord, RecordType } from '../model/RecordModel'
import { appStore } from '../store/GlobalStore'

@Component
export struct HomeView {
  @Link @Watch('handleRefreshTickChange') refreshTick: number
  @Link currentIndex: number
  @State recordType: RecordType = RecordType.Expense
  @State amountText: string = ''
  @State remark: string = ''
  @State selectedCategory: string = '餐饮'
  @State selectedTime: number = Date.now()
  @State displayMonth: number = new Date().getFullYear() * 12 + new Date().getMonth()
  @State monthPickerVisible: boolean = false
  @State monthPickerYear: number = new Date().getFullYear()
  @State monthPickerMonth: number = new Date().getMonth() + 1
  @State monthPickerOpacity: number = 0
  @State monthPickerOffsetY: number = 80
  @State datePickerVisible: boolean = false
  @State datePickerTarget: string = 'quick'
  @State datePickerYear: number = new Date().getFullYear()
  @State datePickerMonth: number = new Date().getMonth() + 1
  @State datePickerDay: number = new Date().getDate()
  @State datePickerOpacity: number = 0
  @State datePickerOffsetY: number = 80
  @State monthOptions: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  @State detailDialogVisible: boolean = false
  @State detailDate: number = Date.now()
  @State detailRecordList: LedgerRecord[] = []
  @State detailIncome: number = 0
  @State detailExpense: number = 0
  @State detailDialogOpacity: number = 0
  @State detailDialogScale: number = 0.92
  @State editDialogVisible: boolean = false
  @State editDialogOpacity: number = 0
  @State editDialogScale: number = 0.92
  @State editId: string = ''
  @State editType: RecordType = RecordType.Expense
  @State editAmountText: string = ''
  @State editRemark: string = ''
  @State editCategory: string = '餐饮'
  @State editTime: number = Date.now()
  @State nickname: string = '用户'
  @State avatarKey: string = 'default'
  @State monthIncome: number = 0
  @State monthExpense: number = 0
  @State monthBalance: number = 0
  @State monthBudget: number = 0
  @State monthIncomeText: string = '0.00元'
  @State monthExpenseText: string = '0.00元'
  @State monthBalanceText: string = '0.00元'
  @State monthIncomeCardText: string = '0.00元'
  @State monthExpenseCardText: string = '0.00元'
  @State monthBalanceCardText: string = '0.00元'
  @State monthIncomeCardSize: number = 20
  @State monthExpenseCardSize: number = 20
  @State monthBalanceCardSize: number = 20
  @State monthBudgetText: string = '0.00元'
  @State monthBudgetProgress: number = 0
  @State primaryBudgetTitle: string = ''
  @State primaryBudgetUsed: number = 0
  @State primaryBudgetTotal: number = 0
  @State primaryBudgetUsedText: string = '0.00元'
  @State primaryBudgetTotalText: string = '0.00元'
  @State primaryBudgetProgress: number = 0
  @State allRecordList: LedgerRecord[] = []
  @State recordList: LedgerRecord[] = []
  @State viewVersion: number = 0
  @State lastStoreVersion: number = -1

  aboutToAppear(): void {
    this.syncHomeState()
  }

  private async reloadHomeState(): Promise<void> {
    await appStore.reloadLedger()
    this.syncHomeState()
    this.lastStoreVersion = appStore.dataVersion
    this.viewVersion += 1
    this.refreshTick += 1
  }

  private syncHomeState(): void {
    const allRecords: LedgerRecord[] = []
    const records: LedgerRecord[] = []
    let income = 0
    let expense = 0
    const monthStart = this.monthStartTime(this.displayMonth)
    const nextMonthStart = this.monthStartTime(this.displayMonth + 1)
    appStore.records.forEach((item: LedgerRecord) => {
      const record: LedgerRecord = {
        id: item.id,
        type: item.type,
        amount: item.amount,
        category: item.category,
        remark: item.remark,
        time: item.time,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt
      }
      allRecords.push(record)
      if (record.time >= monthStart && record.time < nextMonthStart) {
        records.push(record)
        if (record.type === RecordType.Income) {
          income += record.amount
        } else {
          expense += record.amount
        }
      }
    })

    this.nickname = appStore.profile?.nickname || '用户'
    this.avatarKey = appStore.profile?.avatarKey || 'default'
    this.monthIncome = income
    this.monthExpense = expense
    this.monthBalance = income - expense
    this.monthBudget = appStore.budget.monthBudget
    this.allRecordList = allRecords
    this.recordList = records
    this.syncDetailRecords()
    this.syncPrimaryBudget()
    this.syncDisplayState()
    this.viewVersion += 1
    this.lastStoreVersion = appStore.dataVersion
  }

  private syncDisplayState(): void {
    this.monthIncomeText = money(this.monthIncome)
    this.monthExpenseText = money(this.monthExpense)
    this.monthBalanceText = money(this.monthBalance)
    this.monthIncomeCardText = this.monthCardMoney(this.monthIncome)
    this.monthExpenseCardText = this.monthCardMoney(this.monthExpense)
    this.monthBalanceCardText = this.monthCardMoney(this.monthBalance)
    this.monthIncomeCardSize = this.monthCardMoneySize(this.monthIncomeCardText)
    this.monthExpenseCardSize = this.monthCardMoneySize(this.monthExpenseCardText)
    this.monthBalanceCardSize = this.monthCardMoneySize(this.monthBalanceCardText)
    this.monthBudgetText = money(this.monthBudget)
    this.monthBudgetProgress = this.monthBudget > 0 ? Math.min(this.monthExpense / this.monthBudget * 100, 100) : 0
    this.primaryBudgetUsedText = money(this.primaryBudgetUsed)
    this.primaryBudgetTotalText = money(this.primaryBudgetTotal)
    this.primaryBudgetProgress = this.primaryBudgetTotal > 0 ? Math.min(this.primaryBudgetUsed / this.primaryBudgetTotal * 100, 100) : 0
  }

  private appendLocalRecord(record: LedgerRecord): void {
    const copiedRecord: LedgerRecord = {
      id: record.id,
      type: record.type,
      amount: record.amount,
      category: record.category,
      remark: record.remark,
      time: record.time,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt
    }
    this.allRecordList = [copiedRecord].concat(this.allRecordList)
    if (this.monthValueOf(copiedRecord.time) === this.displayMonth) {
      this.recordList = [copiedRecord].concat(this.recordList)
      if (copiedRecord.type === RecordType.Income) {
        this.monthIncome += copiedRecord.amount
      } else {
        this.monthExpense += copiedRecord.amount
      }
      this.monthBalance = this.monthIncome - this.monthExpense
    }
    this.syncDetailRecords()
    this.syncPrimaryBudget()
    this.syncDisplayState()
    this.viewVersion += 1
    this.refreshTick += 1
  }

  private monthStartTime(monthValue: number): number {
    const year = Math.floor(monthValue / 12)
    const month = monthValue % 12
    return new Date(year, month, 1).getTime()
  }

  private monthValueOf(time: number): number {
    const date = new Date(time)
    return date.getFullYear() * 12 + date.getMonth()
  }

  private currentMonthValue(): number {
    const now = new Date()
    return now.getFullYear() * 12 + now.getMonth()
  }

  private isFutureMonth(year: number, month: number): boolean {
    return year * 12 + month - 1 > this.currentMonthValue()
  }

  private notifyFutureMonth(): void {
    promptAction.openToast({ message: '不能选择未来月份', duration: 1200 })
  }

  private clampMonthPickerToCurrent(): void {
    if (!this.isFutureMonth(this.monthPickerYear, this.monthPickerMonth)) {
      return
    }
    const now = new Date()
    this.monthPickerYear = now.getFullYear()
    this.monthPickerMonth = now.getMonth() + 1
  }

  private monthTitle(): string {
    const year = Math.floor(this.displayMonth / 12)
    const month = `${this.displayMonth % 12 + 1}`.padStart(2, '0')
    return `${year}年-${month}月账单`
  }

  private monthCardMoney(value: number): string {
    const absValue = Math.abs(value)
    if (absValue >= 100000000) {
      return `${(value / 100000000).toFixed(2)}亿元`
    }
    if (absValue >= 100000) {
      return `${(value / 10000).toFixed(2)}万元`
    }
    return money(value)
  }

  private monthCardMoneySize(value: string): number {
    const length = value.length
    if (length <= 8) {
      return 20
    }
    if (length <= 10) {
      return 18
    }
    if (length <= 12) {
      return 16
    }
    return 14
  }

  private shiftMonth(offset: number): void {
    const nextMonth = this.displayMonth + offset
    if (nextMonth > this.currentMonthValue()) {
      this.notifyFutureMonth()
      return
    }
    this.displayMonth = nextMonth
    this.syncHomeState()
    this.viewVersion += 1
    this.refreshTick += 1
  }

  private openMonthPicker(): void {
    if (this.displayMonth > this.currentMonthValue()) {
      this.displayMonth = this.currentMonthValue()
    }
    this.monthPickerYear = Math.floor(this.displayMonth / 12)
    this.monthPickerMonth = this.displayMonth % 12 + 1
    this.clampMonthPickerToCurrent()
    this.monthPickerOpacity = 0
    this.monthPickerOffsetY = 80
    this.monthPickerVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.monthPickerOpacity = 1
        this.monthPickerOffsetY = 0
      })
    }, 20)
  }

  private applyMonthPicker(): void {
    if (this.isFutureMonth(this.monthPickerYear, this.monthPickerMonth)) {
      this.notifyFutureMonth()
      this.clampMonthPickerToCurrent()
      return
    }
    this.displayMonth = this.monthPickerYear * 12 + this.monthPickerMonth - 1
    this.closeMonthPicker()
    this.syncHomeState()
    this.viewVersion += 1
    this.refreshTick += 1
  }

  private adjustMonthPickerYear(offset: number): void {
    const nextYear = this.monthPickerYear + offset
    if (this.isFutureMonth(nextYear, this.monthPickerMonth)) {
      this.notifyFutureMonth()
      this.clampMonthPickerToCurrent()
      return
    }
    this.monthPickerYear = nextYear
  }

  private selectMonthPickerMonth(month: number): void {
    if (this.isFutureMonth(this.monthPickerYear, month)) {
      this.notifyFutureMonth()
      return
    }
    this.monthPickerMonth = month
  }

  private closeMonthPicker(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.monthPickerOpacity = 0
      this.monthPickerOffsetY = 80
    })
    setTimeout(() => {
      this.monthPickerVisible = false
    }, 180)
  }

  private syncDetailRecords(): void {
    const start = this.dayStartTime(this.detailDate)
    const end = start + 24 * 60 * 60 * 1000
    const list: LedgerRecord[] = []
    let income = 0
    let expense = 0
    this.allRecordList.forEach((item: LedgerRecord) => {
      if (item.time >= start && item.time < end) {
        list.push(item)
        if (item.type === RecordType.Income) {
          income += item.amount
        } else {
          expense += item.amount
        }
      }
    })
    this.detailRecordList = list
    this.detailIncome = income
    this.detailExpense = expense
  }

  private dayStartTime(time: number): number {
    const date = new Date(time)
    date.setHours(0, 0, 0, 0)
    return date.getTime()
  }

  private todayStartTime(): number {
    return this.dayStartTime(Date.now())
  }

  private isFutureDate(year: number, month: number, day: number): boolean {
    return this.dayStartTime(new Date(year, month - 1, day).getTime()) > this.todayStartTime()
  }

  private notifyFutureDate(): void {
    promptAction.openToast({ message: '不能选择未来日期', duration: 1200 })
  }

  private clampDatePickerToToday(): void {
    const maxDay = this.daysInMonth(this.datePickerYear, this.datePickerMonth)
    if (this.datePickerDay > maxDay) {
      this.datePickerDay = maxDay
    }
    if (!this.isFutureDate(this.datePickerYear, this.datePickerMonth, this.datePickerDay)) {
      return
    }
    const now = new Date()
    this.datePickerYear = now.getFullYear()
    this.datePickerMonth = now.getMonth() + 1
    this.datePickerDay = now.getDate()
  }

  private syncPrimaryBudget(): void {
    if (appStore.budget.categoryBudgets.length > 0) {
      const firstBudget: CategoryBudget = appStore.budget.categoryBudgets[0]
      this.primaryBudgetTitle = firstBudget.category
      this.primaryBudgetUsed = this.categoryExpenseInDisplayMonth(firstBudget.category)
      this.primaryBudgetTotal = firstBudget.amount
    } else {
      this.primaryBudgetTitle = ''
      this.primaryBudgetUsed = 0
      this.primaryBudgetTotal = 0
    }
  }

  private categoryExpenseInDisplayMonth(category: string): number {
    let amount = 0
    const monthStart = this.monthStartTime(this.displayMonth)
    const nextMonthStart = this.monthStartTime(this.displayMonth + 1)
    this.allRecordList.forEach((item: LedgerRecord) => {
      if (item.type === RecordType.Expense && item.category === category && item.time >= monthStart && item.time < nextMonthStart) {
        amount += item.amount
      }
    })
    return amount
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          this.TopTitle()
          this.MonthCard()
          this.QuickGrid()
          this.BudgetPanel()
          this.RecentList()
        }
        .padding({ left: 16, right: 16, top: 18, bottom: 104 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')
      this.DetailDialog()
      this.MonthPickerDialog()
      this.DatePickerDialog()
      this.EditDialog()
    }
    .width('100%')
    .height('100%')
  }

  private handleRefreshTickChange(): void {
    if (this.lastStoreVersion !== appStore.dataVersion) {
      this.syncHomeState()
    }
  }

  @Builder
  TopTitle() {
    Row() {
      Column() {
        Text(`你好，${this.nickname}`)
          .fontSize(15)
          .fontColor('#7B8794')
        Text(this.monthTitle())
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#20242A')
          .margin({ top: 3 })
          .onClick(() => this.openMonthPicker())
        .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      this.HeaderAvatar(54)
    }
    .width('100%')
    .margin({ bottom: 18 })
  }

  @Builder
  HeaderAvatar(size: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (this.avatarKey === 'default') {
        Image($r('app.media.icon_avatar'))
          .width(size)
          .height(size)
          .borderRadius(size / 2)
          .objectFit(ImageFit.Cover)
      } else if (this.avatarKey.startsWith('file://') || this.avatarKey.startsWith('datashare://') || this.avatarKey.startsWith('media://')) {
        Image(this.avatarKey)
          .width(size)
          .height(size)
          .borderRadius(size / 2)
          .objectFit(ImageFit.Cover)
      } else {
        Text(this.nickname.length > 0 ? this.nickname.substring(0, 1).toUpperCase() : '账')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(size)
          .height(size)
          .textAlign(TextAlign.Center)
          .backgroundColor('#2298F2')
          .borderRadius(size / 2)
      }
    }
    .width(size)
    .height(size)
    .borderRadius(size / 2)
    .border({ width: 2, color: Color.White })
    .shadow({ radius: 10, color: '#1824311A', offsetY: 4 })
  }

  @Builder
  MonthCard() {
    Row() {
      this.MonthIncomeItem()
      this.MonthExpenseItem()
      this.MonthBalanceItem()
    }
    .width('100%')
    .height(98)
    .padding({ left: 14, right: 14 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('#269DF3')
    .borderRadius(12)
    .margin({ bottom: 22 })
  }

  @Builder
  MonthIncomeItem() {
    Column() {
      Text('收入')
        .fontSize(14)
        .fontColor('#BFE8FF')
        .width('100%')
        .textAlign(TextAlign.Center)
      Text(`${this.monthIncomeCardText}${this.viewVersion * 0 > 0 ? '' : ''}`)
        .fontSize(this.monthIncomeCardSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: 2, right: 2 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MonthExpenseItem() {
    Column() {
      Text('支出')
        .fontSize(14)
        .fontColor('#BFE8FF')
        .width('100%')
        .textAlign(TextAlign.Center)
      Text(`${this.monthExpenseCardText}${this.viewVersion * 0 > 0 ? '' : ''}`)
        .fontSize(this.monthExpenseCardSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: 2, right: 2 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MonthBalanceItem() {
    Column() {
      Text('结余')
        .fontSize(14)
        .fontColor('#BFE8FF')
        .width('100%')
        .textAlign(TextAlign.Center)
      Text(`${this.monthBalanceCardText}${this.viewVersion * 0 > 0 ? '' : ''}`)
        .fontSize(this.monthBalanceCardSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: 2, right: 2 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  QuickGrid() {
    Column() {
      Row() {
        Text('快速记账')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#20242A')
        Blank()
        Text('详细记账')
          .fontSize(14)
          .fontColor('#2298F2')
          .onClick(() => this.openDetailDialog())
      }
      .width('100%')
      .margin({ bottom: 14 })
      Row() {
        this.TypeButton('支出', RecordType.Expense, '#E84026')
        this.TypeButton('收入', RecordType.Income, '#00A870')
      }
      .margin({ bottom: 12 })
      Grid() {
        if (this.recordType === RecordType.Expense) {
          this.QuickItem('餐饮', $r('app.media.ic_food'), '#FF6267')
          this.QuickItem('交通', $r('app.media.ic_transport'), '#42C9BE')
          this.QuickItem('购物', $r('app.media.ic_shopping'), '#FFE46D')
          this.QuickItem('娱乐', $r('app.media.ic_game'), '#73D2C6')
          this.QuickItem('居住', $r('app.media.ic_home_life'), '#FF7474')
          this.QuickItem('医疗', $r('app.media.ic_medical'), '#9D83D9')
          this.QuickItem('学习', $r('app.media.ic_study'), '#6557DB')
          this.QuickItem('其他', $r('app.media.ic_other'), '#58A9F5')
        } else {
          this.QuickItem('工资', $r('app.media.ic_salary'), '#00A870')
          this.QuickItem('奖金', $r('app.media.ic_bonus'), '#42C9BE')
          this.QuickItem('理财', $r('app.media.ic_finance'), '#FFE46D')
          this.QuickItem('兼职', $r('app.media.ic_part_time'), '#73D2C6')
          this.QuickItem('红包', $r('app.media.ic_red_packet'), '#FF7474')
          this.QuickItem('其他', $r('app.media.ic_other'), '#9D83D9')
        }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(14)
      .rowsGap(12)
      .width('100%')

      Row() {
        TextInput({ placeholder: '金额', text: this.amountText })
          .layoutWeight(1)
          .height(42)
          .type(InputType.Number)
          .onChange((value: string) => this.amountText = value)
        Button('保存')
          .width(76)
          .height(42)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#2298F2')
          .borderRadius(21)
          .margin({ left: 10 })
          .onClick(() => this.saveRecord())
      }
      .margin({ top: 14 })
      TextInput({ placeholder: '备注', text: this.remark })
        .height(42)
        .margin({ top: 8 })
        .onChange((value: string) => this.remark = value)
      Row() {
        Text(`记账日期：${dayText(this.selectedTime)}`)
          .fontSize(13)
          .fontColor('#59636F')
          .onClick(() => this.openDatePicker('quick', this.selectedTime))
        Blank()
        Text('选择日期')
          .fontSize(13)
          .fontColor('#2298F2')
          .onClick(() => this.openDatePicker('quick', this.selectedTime))
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 18 })
  }

  @Builder
  TypeButton(label: string, type: RecordType, color: string) {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .backgroundColor(this.recordType === type ? color : '#EEF1F5')
      .fontColor(this.recordType === type ? Color.White : '#20242A')
      .margin({ left: type === RecordType.Income ? 8 : 0 })
      .onClick(() => {
        this.recordType = type
        this.selectedCategory = type === RecordType.Expense ? EXPENSE_CATEGORIES[0] : INCOME_CATEGORIES[0]
      })
  }

  @Builder
  QuickItem(category: string, icon: Resource, color: string) {
    GridItem() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Image(icon)
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
        }
        .width(42)
        .height(42)
        .backgroundColor(this.selectedCategory === category ? Color.Transparent : color)
        .borderRadius(21)
        Text(category)
          .fontSize(12)
          .fontWeight(this.selectedCategory === category ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.selectedCategory === category ? Color.White : '#59636F')
          .margin({ top: 8 })
      }
      .width('100%')
      .height(82)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.selectedCategory === category ? color : '#F1F4F8')
      .borderRadius(12)
      .border({ width: this.selectedCategory === category ? 2 : 1, color: this.selectedCategory === category ? '#FFFFFF' : '#E2E8F0' })
      .shadow({
        radius: this.selectedCategory === category ? 10 : 0,
        color: '#1A2298F2',
        offsetY: this.selectedCategory === category ? 4 : 0
      })
      .scale({ x: this.selectedCategory === category ? 1.04 : 1, y: this.selectedCategory === category ? 1.04 : 1 })
      .opacity(this.selectedCategory === category ? 1 : 0.72)
      .animation({ duration: 160, curve: Curve.EaseOut })
      .onClick(() => this.selectedCategory = category)
    }
  }

  @Builder
  BudgetPanel() {
    Column() {
      Row() {
        Text('预算进度')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#20242A')
        Blank()
        Text('设置预算')
          .fontSize(14)
          .fontColor('#2298F2')
          .onClick(() => {
            this.currentIndex = 2
            this.refreshTick += 1
          })
      }
      .width('100%')
      .margin({ bottom: 14 })
      Column() {
        Row() {
          Text('总预算').fontSize(15).fontColor('#20242A')
          Blank()
          Text(`${this.monthExpenseText}/${this.monthBudgetText}`)
            .fontSize(13)
            .fontColor('#6E7783')
        }
        .width('100%')
        Progress({
          value: this.monthBudgetProgress,
          total: 100,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(8)
          .color(this.monthBudgetProgress >= 100 ? '#E84026' : '#C8CDD4')
          .margin({ top: 10 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F6F7F9')
      .borderRadius(8)
      .margin({ bottom: 10 })
      if (this.primaryBudgetTitle.length > 0) {
        Column() {
          Row() {
            Text(this.primaryBudgetTitle).fontSize(15).fontColor('#20242A')
            Blank()
            Text(`${this.primaryBudgetUsedText}/${this.primaryBudgetTotalText}`)
              .fontSize(13)
              .fontColor('#6E7783')
          }
          .width('100%')
          Progress({
            value: this.primaryBudgetProgress,
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(8)
            .color(this.primaryBudgetProgress >= 100 ? '#E84026' : '#F6B90C')
            .margin({ top: 10 })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F6F7F9')
        .borderRadius(8)
        .margin({ bottom: 10 })
      } else {
        Text('暂无分类预算')
          .fontSize(14)
          .fontColor('#7B8794')
          .padding(12)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 18 })
  }

  @Builder
  BudgetRow(title: string, used: number, total: number, color: string) {
    Column() {
      Row() {
        Text(title).fontSize(15).fontColor('#20242A')
        Blank()
        Text(`${money(used)}/${money(total)}`).fontSize(13).fontColor('#6E7783')
      }
      .width('100%')
      Progress({ value: total > 0 ? Math.min(used / total * 100, 100) : 0, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(color)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F6F7F9')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  @Builder
  RecentList() {
    Column() {
      Row() {
        Text(`最近记录 ${this.viewVersion >= 0 ? '' : ''}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#20242A')
        Blank()
        Text('查看全部')
          .fontSize(14)
          .fontColor('#2298F2')
          .onClick(() => {
            this.currentIndex = 1
            this.refreshTick += 1
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      if (this.recordList.length === 0) {
        Text('暂无记录').fontSize(14).fontColor('#7B8794').padding(20)
      } else {
        ForEach(this.recordList, (record: LedgerRecord) => {
          this.RecordRow(record)
        }, (record: LedgerRecord) => `${record.id}_${this.viewVersion}`)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

  @Builder
  RecordRow(record: LedgerRecord) {
    Row() {
      Column() {
        Text(record.category).fontSize(15).fontColor('#20242A')
        Text(`${record.remark || '无备注'} - ${dayText(record.time)}`).fontSize(12).fontColor('#7B8794').margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(`${record.type === RecordType.Income ? '+' : '-'}${money(record.amount)}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(record.type === RecordType.Income ? '#00A870' : '#E84026')
        .width(82)
        .textAlign(TextAlign.End)
      Button('编辑')
        .height(28)
        .width(62)
        .fontSize(11)
        .fontColor('#2298F2')
        .backgroundColor('#EAF5FF')
        .borderRadius(14)
        .margin({ left: 8 })
        .onClick(() => this.startEdit(record))
      Button('删除')
        .height(28)
        .width(62)
        .fontSize(11)
        .fontColor('#E84026')
        .backgroundColor('#FFF1F0')
        .borderRadius(14)
        .margin({ left: 6 })
        .onClick(async () => {
          await appStore.removeRecord(record.id)
          await this.reloadHomeState()
          promptAction.openToast({ message: '已删除', duration: 1500 })
        })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  DetailDialog() {
    if (this.detailDialogVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.detailDialogOpacity)
          .onClick(() => this.closeDetailDialog())
        Column() {
          Row() {
            Text('当日账单')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#20242A')
            Blank()
            Text('关闭')
              .fontSize(14)
              .fontColor('#7B8794')
              .onClick(() => this.closeDetailDialog())
          }
          .width('100%')
          .margin({ bottom: 14 })

          Row() {
            Text(dayText(this.detailDate))
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2298F2')
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .onClick(() => this.openDatePicker('detail', this.detailDate))
          }
          .width('100%')

          Row() {
            this.DetailSummaryItem('收入', this.detailIncome, '#00A870')
            this.DetailSummaryItem('支出', this.detailExpense, '#E84026')
          }
          .width('100%')
          .margin({ top: 12, bottom: 10 })

          Button('设为快速记账日期')
            .width('100%')
            .height(42)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor('#2298F2')
            .borderRadius(21)
            .onClick(() => {
              this.selectedTime = this.detailDate
              promptAction.openToast({ message: '已设置记账日期', duration: 1200 })
            })

          Column() {
            if (this.detailRecordList.length === 0) {
              Text('当天暂无记录')
                .fontSize(14)
                .fontColor('#7B8794')
                .padding(24)
            } else {
              ForEach(this.detailRecordList, (record: LedgerRecord) => {
                this.DetailRecordRow(record)
              }, (record: LedgerRecord) => record.id)
            }
          }
          .width('100%')
          .height(260)
          .margin({ top: 12 })
        }
        .width('90%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .opacity(this.detailDialogOpacity)
        .scale({ x: this.detailDialogScale, y: this.detailDialogScale })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  MonthPickerDialog() {
    if (this.monthPickerVisible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.monthPickerOpacity)
          .onClick(() => this.closeMonthPicker())
        Column() {
          this.MonthSheetHeader()
          Row() {
            Button('上一年')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustMonthPickerYear(-1))
            Text(`${this.monthPickerYear}年`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Button('下一年')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustMonthPickerYear(1))
          }
          .width('100%')
          .margin({ bottom: 14 })
          Grid() {
            ForEach(this.monthOptions, (month: number) => {
              GridItem() {
                Text(`${month}月`)
                  .fontSize(14)
                  .fontColor(this.isFutureMonth(this.monthPickerYear, month) ? '#B8C0CC' :
                    (this.monthPickerMonth === month ? Color.White : '#182431'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .height(34)
                  .backgroundColor(this.isFutureMonth(this.monthPickerYear, month) ? '#F6F7F9' :
                    (this.monthPickerMonth === month ? '#2298F2' : '#F1F4F8'))
                  .borderRadius(10)
                  .opacity(this.isFutureMonth(this.monthPickerYear, month) ? 0.48 : 1)
                  .onClick(() => this.selectMonthPickerMonth(month))
              }
            }, (month: number) => `${month}`)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(10)
          .rowsGap(8)
          .width('100%')
          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(38)
              .fontSize(15)
              .fontColor('#20242A')
              .backgroundColor('#F1F4F8')
              .borderRadius(21)
              .onClick(() => this.closeMonthPicker())
            Button('确认')
              .layoutWeight(1)
              .height(38)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#2298F2')
              .borderRadius(21)
              .margin({ left: 10 })
              .onClick(() => this.applyMonthPicker())
          }
          .margin({ top: 18 })
        }
        .width('100%')
        .height('70%')
        .padding({ left: 18, right: 18, top: 12, bottom: 14 })
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 18, topRight: 18 })
        .opacity(this.monthPickerOpacity)
        .translate({ y: this.monthPickerOffsetY })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  DatePickerDialog() {
    if (this.datePickerVisible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.datePickerOpacity)
          .onClick(() => this.closeDatePicker())
        Column() {
          this.DateSheetHeader()
          Row() {
            Button('上年')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustDatePickerYear(-1))
            Text(`${this.datePickerYear}年`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Button('下年')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustDatePickerYear(1))
          }
          .width('100%')
          Row() {
            Button('上月')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustDatePickerMonth(-1))
            Text(`${this.datePickerMonth}月`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Button('下月')
              .width(64)
              .height(30)
              .fontSize(13)
              .fontColor('#2298F2')
              .backgroundColor('#EAF5FF')
              .borderRadius(16)
              .onClick(() => this.adjustDatePickerMonth(1))
          }
          .width('100%')
          .margin({ top: 8, bottom: 10 })
          Scroll() {
            Grid() {
              ForEach(this.datePickerDays(), (day: number) => {
                GridItem() {
                  Text(`${day}`)
                    .fontSize(14)
                    .fontColor(this.isFutureDate(this.datePickerYear, this.datePickerMonth, day) ? '#B8C0CC' :
                      (this.datePickerDay === day ? Color.White : '#182431'))
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .height(28)
                    .backgroundColor(this.isFutureDate(this.datePickerYear, this.datePickerMonth, day) ? '#F6F7F9' :
                      (this.datePickerDay === day ? '#2298F2' : '#F1F4F8'))
                    .borderRadius(9)
                    .opacity(this.isFutureDate(this.datePickerYear, this.datePickerMonth, day) ? 0.48 : 1)
                    .onClick(() => this.selectDatePickerDay(day))
                }
              }, (day: number) => `${day}`)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(6)
            .rowsGap(5)
            .width('100%')
          }
          .width('100%')
          .height(176)
          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(38)
              .fontSize(15)
              .fontColor('#20242A')
              .backgroundColor('#F1F4F8')
              .borderRadius(21)
              .onClick(() => this.closeDatePicker())
            Button('确认')
              .layoutWeight(1)
              .height(38)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#2298F2')
              .borderRadius(21)
              .margin({ left: 10 })
              .onClick(() => this.applyDatePicker())
          }
          .margin({ top: 12 })
        }
        .width('100%')
        .height('70%')
        .padding({ left: 14, right: 14, top: 10, bottom: 12 })
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 18, topRight: 18 })
        .opacity(this.datePickerOpacity)
        .translate({ y: this.datePickerOffsetY })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  DetailSummaryItem(label: string, value: number, color: string) {
    Column() {
      Text(label).fontSize(12).fontColor('#7B8794')
      Text(money(value)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(color).margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('#F6F7F9')
    .borderRadius(10)
    .margin({ right: label === '收入' ? 8 : 0 })
  }

  @Builder
  MonthSheetHeader() {
    Row() {
      Text('选择月份')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
      Blank()
      Text('关闭')
        .fontSize(14)
        .fontColor('#2298F2')
        .onClick(() => this.closeMonthPicker())
    }
    .width('100%')
    .height(32)
    .margin({ bottom: 8 })
  }

  @Builder
  DateSheetHeader() {
    Row() {
      Text('选择日期')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
      Blank()
      Text('关闭')
        .fontSize(14)
        .fontColor('#2298F2')
        .onClick(() => this.closeDatePicker())
    }
    .width('100%')
    .height(32)
    .margin({ bottom: 8 })
  }

  @Builder
  PrimaryButton(title: string) {
    Button(title)
      .height(42)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .backgroundColor('#2298F2')
      .borderRadius(21)
  }

  @Builder
  SecondaryButton(title: string) {
    Button(title)
      .height(42)
      .fontSize(15)
      .fontColor('#20242A')
      .backgroundColor('#F1F4F8')
      .borderRadius(21)
  }

  @Builder
  GhostButton(title: string) {
    Button(title)
      .width(64)
      .height(32)
      .fontSize(13)
      .fontColor('#2298F2')
      .backgroundColor('#EAF5FF')
      .borderRadius(16)
  }

  @Builder
  DetailRecordRow(record: LedgerRecord) {
    Row() {
      Column() {
        Text(record.category).fontSize(14).fontColor('#20242A')
        Text(record.remark || '无备注').fontSize(12).fontColor('#7B8794').margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(`${record.type === RecordType.Income ? '+' : '-'}${money(record.amount)}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(record.type === RecordType.Income ? '#00A870' : '#E84026')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#EDF0F5' })
  }

  @Builder
  EditDialog() {
    if (this.editDialogVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.editDialogOpacity)
          .onClick(() => this.closeEditDialog())
        Column() {
          Row() {
            Text('编辑记录')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#20242A')
            Blank()
            Text('关闭')
              .fontSize(14)
              .fontColor('#7B8794')
              .onClick(() => this.closeEditDialog())
          }
          .width('100%')
          .margin({ bottom: 14 })

          Row() {
            this.EditTypeButton('支出', RecordType.Expense, '#E84026')
            this.EditTypeButton('收入', RecordType.Income, '#00A870')
          }
          .margin({ bottom: 12 })

          Flex({ wrap: FlexWrap.Wrap }) {
            if (this.editType === RecordType.Expense) {
              ForEach(EXPENSE_CATEGORIES, (category: string) => {
                this.EditCategoryButton(category)
              }, (category: string) => category)
            } else {
              ForEach(INCOME_CATEGORIES, (category: string) => {
                this.EditCategoryButton(category)
              }, (category: string) => category)
            }
          }
          .width('100%')

          TextInput({ placeholder: '金额', text: this.editAmountText })
            .height(42)
            .type(InputType.Number)
            .margin({ top: 10 })
            .onChange((value: string) => {
              this.editAmountText = value
            })
          TextInput({ placeholder: '备注', text: this.editRemark })
            .height(42)
            .margin({ top: 8 })
            .onChange((value: string) => {
              this.editRemark = value
            })

          Text('记录日期')
            .fontSize(14)
            .fontColor('#59636F')
            .width('100%')
            .margin({ top: 10, bottom: 6 })
          Text(`当前日期：${dayText(this.editTime)}`)
            .fontSize(14)
            .fontColor('#2298F2')
            .width('100%')
            .margin({ top: 8 })
            .onClick(() => this.openDatePicker('edit', this.editTime))

          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontColor('#20242A')
              .backgroundColor('#F1F4F8')
              .borderRadius(21)
              .onClick(() => this.closeEditDialog())
            Button('保存修改')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#2298F2')
              .borderRadius(21)
              .margin({ left: 10 })
              .onClick(() => this.saveEditRecord())
          }
          .margin({ top: 16 })
        }
        .width('88%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .opacity(this.editDialogOpacity)
        .scale({ x: this.editDialogScale, y: this.editDialogScale })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  EditTypeButton(label: string, type: RecordType, color: string) {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .backgroundColor(this.editType === type ? color : '#EEF1F5')
      .fontColor(this.editType === type ? Color.White : '#20242A')
      .margin({ left: type === RecordType.Income ? 8 : 0 })
      .animation({ duration: 160, curve: Curve.EaseOut })
      .onClick(() => {
        this.editType = type
        this.editCategory = type === RecordType.Expense ? EXPENSE_CATEGORIES[0] : INCOME_CATEGORIES[0]
      })
  }

  @Builder
  EditCategoryButton(category: string) {
    Button(category)
      .height(32)
      .fontSize(13)
      .backgroundColor(this.editCategory === category ? '#2298F2' : '#EEF1F5')
      .fontColor(this.editCategory === category ? Color.White : '#20242A')
      .margin({ right: 8, bottom: 8 })
      .animation({ duration: 160, curve: Curve.EaseOut })
      .onClick(() => {
        this.editCategory = category
      })
  }

  async saveRecord(): Promise<void> {
    const amount = Number(this.amountText)
    if (!Number.isFinite(amount) || amount <= 0) {
      promptAction.openToast({ message: '请输入有效金额', duration: 1500 })
      return
    }
    const savedType = this.recordType
    const savedCategory = this.selectedCategory
    const savedTime = this.selectedTime
    this.displayMonth = this.monthValueOf(savedTime)
    const savedRecord = await appStore.addRecord(savedType, amount, savedCategory, this.remark, savedTime)
    this.appendLocalRecord(savedRecord)
    this.amountText = ''
    this.remark = ''
    await this.reloadHomeState()
    promptAction.openToast({ message: '已保存', duration: 1500 })
  }

  openDetailDialog(): void {
    this.detailDate = this.selectedTime
    this.syncDetailRecords()
    this.detailDialogOpacity = 0
    this.detailDialogScale = 0.92
    this.detailDialogVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.detailDialogOpacity = 1
        this.detailDialogScale = 1
      })
    }, 20)
  }

  closeDetailDialog(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.detailDialogOpacity = 0
      this.detailDialogScale = 0.94
    })
    setTimeout(() => {
      this.detailDialogVisible = false
    }, 180)
  }

  openDatePicker(target: string, time: number): void {
    const date = new Date(time)
    this.datePickerTarget = target
    this.datePickerYear = date.getFullYear()
    this.datePickerMonth = date.getMonth() + 1
    this.datePickerDay = date.getDate()
    this.clampDatePickerToToday()
    this.datePickerOpacity = 0
    this.datePickerOffsetY = 80
    this.datePickerVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.datePickerOpacity = 1
        this.datePickerOffsetY = 0
      })
    }, 20)
  }

  applyDatePicker(): void {
    if (this.isFutureDate(this.datePickerYear, this.datePickerMonth, this.datePickerDay)) {
      this.notifyFutureDate()
      this.clampDatePickerToToday()
      return
    }
    const picked = new Date(this.datePickerYear, this.datePickerMonth - 1, this.datePickerDay).getTime()
    if (this.datePickerTarget === 'detail') {
      this.detailDate = picked
      this.syncDetailRecords()
    } else if (this.datePickerTarget === 'edit') {
      this.editTime = picked
    } else {
      this.selectedTime = picked
    }
    this.closeDatePicker()
  }

  closeDatePicker(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.datePickerOpacity = 0
      this.datePickerOffsetY = 80
    })
    setTimeout(() => {
      this.datePickerVisible = false
    }, 180)
  }

  adjustDatePickerYear(offset: number): void {
    const nextYear = this.datePickerYear + offset
    if (this.isFutureDate(nextYear, this.datePickerMonth, this.datePickerDay)) {
      this.notifyFutureDate()
      this.clampDatePickerToToday()
      return
    }
    this.datePickerYear = nextYear
    const maxDay = this.daysInMonth(this.datePickerYear, this.datePickerMonth)
    if (this.datePickerDay > maxDay) {
      this.datePickerDay = maxDay
    }
  }

  adjustDatePickerMonth(offset: number): void {
    let year = this.datePickerYear
    let month = this.datePickerMonth + offset
    if (month < 1) {
      month = 12
      year -= 1
    } else if (month > 12) {
      month = 1
      year += 1
    }
    if (year * 12 + month - 1 > this.currentMonthValue()) {
      this.notifyFutureDate()
      this.clampDatePickerToToday()
      return
    }
    this.datePickerYear = year
    this.datePickerMonth = month
    const maxDay = this.daysInMonth(this.datePickerYear, this.datePickerMonth)
    if (this.datePickerDay > maxDay) {
      this.datePickerDay = maxDay
    }
    if (this.isFutureDate(this.datePickerYear, this.datePickerMonth, this.datePickerDay)) {
      this.notifyFutureDate()
      this.clampDatePickerToToday()
    }
  }

  selectDatePickerDay(day: number): void {
    if (this.isFutureDate(this.datePickerYear, this.datePickerMonth, day)) {
      this.notifyFutureDate()
      return
    }
    this.datePickerDay = day
  }

  datePickerDays(): number[] {
    const days: number[] = []
    const maxDay = this.daysInMonth(this.datePickerYear, this.datePickerMonth)
    for (let day = 1; day <= maxDay; day++) {
      days.push(day)
    }
    return days
  }

  private daysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate()
  }

  startEdit(record: LedgerRecord): void {
    this.editId = record.id
    this.editType = record.type
    this.editAmountText = `${record.amount}`
    this.editCategory = record.category
    this.editRemark = record.remark
    this.editTime = record.time
    this.editDialogOpacity = 0
    this.editDialogScale = 0.92
    this.editDialogVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.editDialogOpacity = 1
        this.editDialogScale = 1
      })
    }, 20)
  }

  closeEditDialog(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.editDialogOpacity = 0
      this.editDialogScale = 0.94
    })
    setTimeout(() => {
      this.editDialogVisible = false
      this.editId = ''
      this.editAmountText = ''
      this.editRemark = ''
      this.editCategory = EXPENSE_CATEGORIES[0]
      this.editType = RecordType.Expense
      this.editTime = Date.now()
    }, 180)
  }

  async saveEditRecord(): Promise<void> {
    const amount = Number(this.editAmountText)
    if (!Number.isFinite(amount) || amount <= 0) {
      promptAction.openToast({ message: '请输入有效金额', duration: 1500 })
      return
    }
    const old = this.recordList.find((item: LedgerRecord) => item.id === this.editId)
    if (!old) {
      promptAction.openToast({ message: '记录不存在', duration: 1500 })
      this.closeEditDialog()
      return
    }
    const updatedRecord: LedgerRecord = {
      id: old.id,
      type: this.editType,
      amount,
      category: this.editCategory,
      remark: this.editRemark,
      time: this.editTime,
      createdAt: old.createdAt,
      updatedAt: Date.now()
    }
    await appStore.updateRecord(updatedRecord)
    this.displayMonth = this.monthValueOf(this.editTime)
    this.closeEditDialog()
    await this.reloadHomeState()
    promptAction.openToast({ message: '已更新', duration: 1500 })
  }
}
