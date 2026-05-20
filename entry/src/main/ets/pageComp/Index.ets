import { AiChatView } from '../views/AiChatView'
import { BudgetView } from '../views/BudgetView'
import { HomeView } from '../views/HomeView'
import { ProfileView } from '../views/ProfileView'
import { ReportView } from '../views/ReportView'
import { appStore } from '../store/GlobalStore'

@Component
export struct Index {
  @State currentIndex: number = 0
  @State refreshTick: number = 0
  @State @Watch('handleRequestedTabChange') requestedIndex: number = 0
  @State pageOpacity: number = 1
  @State pageOffsetX: number = 0
  @State isSwitching: boolean = false
  @State aiVisible: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.currentIndex === 0) {
          HomeView({ refreshTick: $refreshTick, currentIndex: $requestedIndex })
        } else if (this.currentIndex === 1) {
          ReportView({ refreshTick: $refreshTick })
        } else if (this.currentIndex === 2) {
          BudgetView({ refreshTick: $refreshTick })
        } else {
          ProfileView({ refreshTick: $refreshTick })
        }
      }
      .width('100%')
      .height('100%')
      .opacity(this.pageOpacity)
      .translate({ x: this.pageOffsetX })

      Row() {
        this.TabItem('首页', 0, $r('app.media.HOME'), $r('app.media.HOME_active'))
        this.TabItem('报表', 1, $r('app.media.REPORT'), $r('app.media.REPORT_active'))
        Column().width('20%')
        this.TabItem('预算', 2, $r('app.media.MONEY'), $r('app.media.MONEY_active'))
        this.TabItem('我的', 3, $r('app.media.mine'), $r('app.media.mine_active'))
      }
      .width('100%')
      .height(66)
      .padding({ left: 10, right: 10 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#EDF0F5' })

      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.AI'))
          .width(30)
          .height(30)
          .fillColor(Color.White)
      }
        .width(58)
        .height(58)
        .backgroundColor('#5A98D2')
        .borderRadius(29)
        .shadow({ radius: 12, color: '#2298F24D', offsetY: 6 })
        .margin({ bottom: 34 })
        .onClick(() => {
          this.openAiChat()
        })
      if (this.aiVisible) {
        AiChatView({ visible: $aiVisible, refreshTick: $refreshTick })
          .zIndex(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  @Builder
  TabItem(title: string, index: number, icon: Resource, activeIcon: Resource) {
    Column({ space: 2 }) {
      Image(this.currentIndex === index ? activeIcon : icon)
        .width(24)
        .height(24)
      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? '#2298F2' : '#7B8794')
    }
    .width('20%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.switchTab(index)
    })
  }

  switchTab(index: number): void {
    if (this.isSwitching || index === this.currentIndex) {
      this.requestedIndex = index
      return
    }
    this.isSwitching = true
    const direction = index > this.currentIndex ? 1 : -1
    animateTo({ duration: 130, curve: Curve.EaseIn }, () => {
      this.pageOpacity = 0
      this.pageOffsetX = -28 * direction
    })
    setTimeout(() => {
      appStore.reloadLedger().then(() => {
        this.currentIndex = index
        this.requestedIndex = index
        this.refreshTick += 1
        this.pageOffsetX = 28 * direction
        setTimeout(() => {
          animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
            this.pageOpacity = 1
            this.pageOffsetX = 0
          })
        }, 20)
        setTimeout(() => {
          this.isSwitching = false
          if (this.requestedIndex !== this.currentIndex) {
            this.switchTab(this.requestedIndex)
          }
        }, 220)
      })
    }, 130)
  }

  handleRequestedTabChange(): void {
    if (this.requestedIndex !== this.currentIndex) {
      this.switchTab(this.requestedIndex)
    }
  }

  openAiChat(): void {
    this.aiVisible = true
  }
}
