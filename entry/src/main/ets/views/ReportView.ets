import { money } from '../common/Formatters'
import { CategorySummary, LedgerSummary, RecordType, TrendPoint } from '../model/RecordModel'
import { appStore } from '../store/GlobalStore'

function createEmptyLedgerSummary(): LedgerSummary {
  const summary: LedgerSummary = {
    income: 0,
    expense: 0,
    balance: 0
  }
  return summary
}

@Component
export struct ReportView {
  @Link @Watch('handleRefreshTickChange') refreshTick: number
  @State daySummary: LedgerSummary = createEmptyLedgerSummary()
  @State weekSummary: LedgerSummary = createEmptyLedgerSummary()
  @State monthSummary: LedgerSummary = createEmptyLedgerSummary()
  @State categoryList: CategorySummary[] = []
  @State trendList: TrendPoint[] = []
  @State viewVersion: number = 0

  aboutToAppear(): void {
    this.syncReportState()
  }

  private handleRefreshTickChange(): void {
    this.syncReportState()
  }

  private syncReportState(): void {
    const day = appStore.summary('day')
    const week = appStore.summary('week')
    const month = appStore.summary('month')
    const categories: CategorySummary[] = []
    const trends: TrendPoint[] = []

    appStore.categorySummary(RecordType.Expense).forEach((item: CategorySummary) => {
      const next: CategorySummary = {
        category: item.category,
        amount: item.amount,
        percent: item.percent
      }
      categories.push(next)
    })
    appStore.trend().forEach((point: TrendPoint) => {
      const next: TrendPoint = {
        label: point.label,
        income: point.income,
        expense: point.expense
      }
      trends.push(next)
    })

    const dayNext: LedgerSummary = { income: day.income, expense: day.expense, balance: day.balance }
    const weekNext: LedgerSummary = { income: week.income, expense: week.expense, balance: week.balance }
    const monthNext: LedgerSummary = { income: month.income, expense: month.expense, balance: month.balance }
    this.daySummary = dayNext
    this.weekSummary = weekNext
    this.monthSummary = monthNext
    this.categoryList = categories
    this.trendList = trends
    this.viewVersion = appStore.dataVersion
  }

  private trendMaxValue(): number {
    let maxValue = 0
    this.trendList.forEach((point: TrendPoint) => {
      maxValue = Math.max(maxValue, point.income)
      maxValue = Math.max(maxValue, point.expense)
    })
    return maxValue > 0 ? maxValue : 1
  }

  private trendBarHeight(value: number): number {
    const chartHeight = 104
    const minHeight = value > 0 ? 6 : 0
    const height = value / this.trendMaxValue() * chartHeight
    return Math.max(minHeight, Math.min(chartHeight, height))
  }

  build() {
    Scroll() {
      Column() {
        this.ReportHeader()
        this.PeriodSummary()
        this.CategoryChart()
        this.TrendChart()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  @Builder
  ReportHeader() {
    Column() {
      Text('收支报表')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#20242A')
        .width('100%')
      Text(`本月收入 ${money(this.monthSummary.income + this.viewVersion * 0)}，支出 ${money(this.monthSummary.expense + this.viewVersion * 0)}`)
        .fontSize(14)
        .fontColor('#59636F')
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  PeriodSummary() {
    Row() {
      this.PeriodItem('今日', this.daySummary)
      this.PeriodItem('本周', this.weekSummary)
      this.PeriodItem('本月', this.monthSummary)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 16 })
  }

  @Builder
  PeriodItem(title: string, summary: LedgerSummary) {
    Column() {
      Text(title).fontSize(13).fontColor('#59636F')
      Text(money(summary.income)).fontSize(13).fontColor('#00A870').margin({ top: 6 })
      Text(money(summary.expense)).fontSize(13).fontColor('#E84026').margin({ top: 4 })
    }
    .width('31%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CategoryChart() {
    Column() {
      Text(`分类占比 ${this.viewVersion >= 0 ? '' : ''}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 10 })
      ForEach(this.categoryList, (item: CategorySummary) => {
        Row() {
          Text(item.category).width(72).fontSize(13).fontColor('#182431')
          Progress({ value: item.percent * 100, total: 100, type: ProgressType.Linear })
            .layoutWeight(1)
            .height(9)
            .color('#2298F2')
          Text(`${Math.round(item.percent * 100)}%`)
            .width(42)
            .fontSize(12)
            .fontColor('#59636F')
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 8 })
      }, (item: CategorySummary) => `${item.category}_${this.viewVersion}`)
      if (this.categoryList.length === 0) {
        Text('暂无支出数据').fontSize(14).fontColor('#7B8794').padding(18)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  TrendChart() {
    Column() {
      Row() {
        Text('近七日趋势')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#20242A')
        Blank()
        Row() {
          Column().width(8).height(8).backgroundColor('#00A870').borderRadius(4)
          Text('收入').fontSize(11).fontColor('#7B8794').margin({ left: 4, right: 10 })
          Column().width(8).height(8).backgroundColor('#E84026').borderRadius(4)
          Text('支出').fontSize(11).fontColor('#7B8794').margin({ left: 4 })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })
      Row() {
        ForEach(this.trendList, (point: TrendPoint) => {
          Column() {
            Row({ space: 4 }) {
              Column()
                .width(10)
                .height(this.trendBarHeight(point.income))
                .backgroundColor('#00A870')
                .borderRadius(5)
              Column()
                .width(10)
                .height(this.trendBarHeight(point.expense))
                .backgroundColor('#E84026')
                .borderRadius(5)
            }
            .height(110)
            .alignItems(VerticalAlign.Bottom)
            .justifyContent(FlexAlign.Center)
            Text(point.label).fontSize(10).fontColor('#7B8794').margin({ top: 8 })
          }
          .layoutWeight(1)
          .height(132)
          .justifyContent(FlexAlign.End)
        }, (point: TrendPoint) => `${point.label}_${this.viewVersion}`)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

}
