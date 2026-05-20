import { promptAction } from '@kit.ArkUI'
import { money } from '../common/Formatters'
import { CategoryBudget, EXPENSE_CATEGORIES } from '../model/RecordModel'
import { appStore } from '../store/GlobalStore'

interface BudgetUsageItem {
  category: string
  amount: number
  used: number
}

@Component
export struct BudgetView {
  @Link @Watch('handleRefreshTickChange') refreshTick: number
  @State budgetText: string = '0'
  @State selectedCategory: string = ''
  @State categoryBudgetText: string = ''
  @State monthBudgetValue: number = 0
  @State monthExpenseValue: number = 0
  @State categoryBudgetList: BudgetUsageItem[] = []
  @State viewVersion: number = 0

  aboutToAppear(): void {
    if (this.selectedCategory.length === 0 && EXPENSE_CATEGORIES.length > 0) {
      this.selectedCategory = EXPENSE_CATEGORIES[0]
    }
    this.syncBudgetState()
  }

  private handleRefreshTickChange(): void {
    this.syncBudgetState()
    this.viewVersion = appStore.dataVersion
  }

  private async reloadBudgetState(): Promise<void> {
    this.syncBudgetState()
    this.refreshTick += 1
    this.viewVersion = appStore.dataVersion
  }

  private syncBudgetState(): void {
    const list: BudgetUsageItem[] = []
    appStore.budget.categoryBudgets.forEach((item: CategoryBudget) => {
      const budgetItem: BudgetUsageItem = {
        category: item.category,
        amount: item.amount,
        used: appStore.categoryExpense(item.category)
      }
      list.push(budgetItem)
    })

    this.monthBudgetValue = appStore.budget.monthBudget
    this.monthExpenseValue = appStore.summary('month').expense
    this.categoryBudgetList = list
    this.budgetText = `${this.monthBudgetValue}`
    const selectedBudget = appStore.categoryBudgetValue(this.selectedCategory)
    this.categoryBudgetText = selectedBudget > 0 ? `${selectedBudget}` : ''
  }

  build() {
    Scroll() {
      Column() {
        this.AlertCard()
        this.SettingCard()
        this.CategorySettingCard()
        this.CategoryBudget()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  @Builder
  AlertCard() {
    Column() {
      Text(this.monthBudgetValue > 0 && this.monthExpenseValue / this.monthBudgetValue >= 1 ? '预算已超额' : '预算使用情况')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.monthBudgetValue > 0 && this.monthExpenseValue / this.monthBudgetValue >= 1 ? '#E84026' : '#20242A')
        .width('100%')
      Text(`本月支出 ${money(this.monthExpenseValue + this.refreshTick * 0 + this.viewVersion * 0)}`)
        .fontSize(15)
        .fontColor('#59636F')
        .width('100%')
        .margin({ top: 8 })
      Progress({
        value: this.monthBudgetValue > 0 ? Math.min(this.monthExpenseValue / this.monthBudgetValue * 100, 100) : 0,
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(12)
        .color(this.monthBudgetValue > 0 && this.monthExpenseValue / this.monthBudgetValue >= 1 ? '#E84026' : '#2298F2')
        .margin({ top: 16, bottom: 10 })
      Text(`${money(this.monthExpenseValue + this.viewVersion * 0)} / ${money(this.monthBudgetValue + this.viewVersion * 0)}`)
        .fontSize(14)
        .fontColor('#6E7783')
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.monthBudgetValue > 0 && this.monthExpenseValue / this.monthBudgetValue >= 1 ? '#FFF1F0' : Color.White)
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  SettingCard() {
    Column() {
      Text('设置月预算')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
        .width('100%')
        .margin({ bottom: 12 })
      Row() {
        TextInput({ placeholder: '请输入月预算', text: this.budgetText })
          .layoutWeight(1)
          .height(42)
          .type(InputType.Number)
          .onFocus(() => {
            if (this.budgetText === '0') {
              this.budgetText = ''
            }
          })
          .onChange((value: string) => {
            this.budgetText = this.normalizeBudgetInput(value)
          })
        Button('保存')
          .width(78)
          .height(42)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor('#2298F2')
          .borderRadius(21)
          .margin({ left: 10 })
          .onClick(() => this.saveBudget())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  CategorySettingCard() {
    Column() {
      Text('设置分类预算')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
        .width('100%')
        .margin({ bottom: 12 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(EXPENSE_CATEGORIES, (category: string) => {
        Button(category)
          .height(32)
          .fontSize(13)
          .backgroundColor(this.selectedCategory === category ? '#2298F2' : '#EEF1F5')
          .fontColor(this.selectedCategory === category ? Color.White : '#20242A')
          .borderRadius(16)
          .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.selectedCategory = category
              const categoryBudget = appStore.categoryBudgetValue(category)
              this.categoryBudgetText = categoryBudget > 0 ? `${categoryBudget}` : ''
              this.viewVersion += 1
            })
        }, (category: string) => category)
      }
      Row() {
        TextInput({ placeholder: '请输入分类预算', text: this.categoryBudgetText })
          .layoutWeight(1)
          .height(42)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.categoryBudgetText = value
          })
        Button('保存')
          .width(78)
          .height(42)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor('#2298F2')
          .borderRadius(21)
          .margin({ left: 10 })
          .onClick(() => this.saveCategoryBudget())
      }
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  CategoryBudget() {
    Column() {
      Text('分类预算')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
        .width('100%')
        .margin({ bottom: 12 })
      this.TotalBudgetRow()
      if (this.categoryBudgetList.length + this.viewVersion * 0 === 0) {
        Text('暂无分类预算，请先设置')
          .fontSize(14)
          .fontColor('#7B8794')
          .padding(16)
      } else {
        ForEach(this.categoryBudgetList, (item: BudgetUsageItem) => {
          this.BudgetRow(item.category, item.used, item.amount, item.used > item.amount ? '#E84026' : '#F6B90C')
        }, (item: BudgetUsageItem) => `${item.category}_${this.viewVersion}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

  @Builder
  TotalBudgetRow() {
    Column() {
      Row() {
        Text('总预算').fontSize(15).fontColor('#20242A')
        Blank()
        Text(`${money(this.monthExpenseValue + this.refreshTick * 0 + this.viewVersion * 0)}/${money(this.monthBudgetValue + this.viewVersion * 0)}`)
          .fontSize(13)
          .fontColor('#6E7783')
      }
      .width('100%')
      Progress({
        value: this.monthBudgetValue > 0 ? Math.min(this.monthExpenseValue / this.monthBudgetValue * 100, 100) : 0,
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(8)
        .color('#2298F2')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F6F7F9')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  @Builder
  BudgetRow(title: string, used: number, total: number, color: string) {
    Column() {
      Row() {
        Text(title).fontSize(15).fontColor('#20242A')
        Blank()
        Text(`${money(used)}/${money(total)}`).fontSize(13).fontColor('#6E7783')
        Button('删除')
          .height(28)
          .width(58)
          .fontSize(12)
          .fontColor('#E84026')
          .backgroundColor('#FFF1F0')
          .borderRadius(14)
          .margin({ left: 8 })
          .onClick(() => this.deleteCategoryBudget(title))
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

  async saveBudget(): Promise<void> {
    const budget = this.budgetText.length === 0 ? 0 : Number(this.budgetText)
    if (!Number.isFinite(budget) || budget < 0) {
      promptAction.openToast({ message: '请输入有效预算', duration: 1500 })
      return
    }

    await appStore.updateBudget(budget)
    await this.reloadBudgetState()
    this.budgetText = ''
    promptAction.openToast({ message: '预算已更新', duration: 1500 })
  }

  private normalizeBudgetInput(value: string): string {
    if (value.length <= 1) {
      return value
    }
    let nextValue = value
    while (nextValue.length > 1 && nextValue.startsWith('0')) {
      nextValue = nextValue.substring(1)
    }
    return nextValue
  }

  async saveCategoryBudget(): Promise<void> {
    const budget = Number(this.categoryBudgetText)
    if (!Number.isFinite(budget) || budget < 0) {
      promptAction.openToast({ message: '请输入有效分类预算', duration: 1500 })
      return
    }

    await appStore.updateCategoryBudget(this.selectedCategory, budget)
    await this.reloadBudgetState()
    promptAction.openToast({ message: '分类预算已更新', duration: 1500 })
  }

  async deleteCategoryBudget(category: string): Promise<void> {
    await appStore.updateCategoryBudget(category, 0)
    if (this.selectedCategory === category) {
      this.categoryBudgetText = ''
    }
    await this.reloadBudgetState()
    promptAction.openToast({ message: '分类预算已删除', duration: 1500 })
  }
}
