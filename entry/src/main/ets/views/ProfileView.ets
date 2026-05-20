import { promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { dayText, money } from '../common/Formatters'
import { appStore } from '../store/GlobalStore'

interface AvatarOption {
  key: string
  label: string
  color: string
}

const AVATAR_OPTIONS: AvatarOption[] = [
  { key: 'default', label: '默认', color: '#2298F2' },
  { key: 'blue', label: '蓝', color: '#1E7BFF' },
  { key: 'green', label: '绿', color: '#00A870' },
  { key: 'orange', label: '橙', color: '#F6B90C' },
  { key: 'red', label: '红', color: '#E84026' }
]

@Component
export struct ProfileView {
  @Link @Watch('handleRefreshTickChange') refreshTick: number
  @State nickname: string = '用户'
  @State account: string = ''
  @State avatarKey: string = 'default'
  @State recordCount: number = 0
  @State monthIncome: number = 0
  @State monthExpense: number = 0
  @State monthBudget: number = 0
  @State monthIncomeText: string = '0.00元'
  @State monthExpenseText: string = '0.00元'
  @State monthBudgetText: string = '0.00元'
  @State recordCountText: string = '0 笔'
  @State lastLoginText: string = ''
  @State createdText: string = ''
  @State settingVisible: boolean = false
  @State settingOpacity: number = 1
  @State settingOffsetX: number = 0
  @State profileOpacity: number = 1
  @State profileOffsetX: number = 0
  @State aboutVisible: boolean = false
  @State nameDialogVisible: boolean = false
  @State aboutDialogOpacity: number = 0
  @State aboutDialogScale: number = 0.92
  @State nameDialogOpacity: number = 0
  @State nameDialogScale: number = 0.92
  @State editNickname: string = ''
  @State editAvatarKey: string = 'default'
  @State viewVersion: number = 0

  aboutToAppear(): void {
    this.syncProfileState()
  }

  private handleRefreshTickChange(): void {
    this.syncProfileState()
  }

  private syncProfileState(): void {
    const profile = appStore.profile
    const month = appStore.summary('month')
    this.nickname = profile?.nickname || '用户'
    this.account = profile?.account || ''
    this.avatarKey = profile?.avatarKey || 'default'
    this.editNickname = this.nickname
    this.editAvatarKey = this.avatarKey
    this.recordCount = appStore.records.length
    this.monthIncome = month.income
    this.monthExpense = month.expense
    this.monthBudget = appStore.budget.monthBudget
    this.monthIncomeText = money(this.monthIncome)
    this.monthExpenseText = money(this.monthExpense)
    this.monthBudgetText = money(this.monthBudget)
    this.recordCountText = `${this.recordCount} 笔`
    this.lastLoginText = profile ? dayText(profile.lastLoginAt) : ''
    this.createdText = profile ? dayText(profile.createdAt) : ''
    this.viewVersion += 1
  }

  build() {
    Stack() {
      if (this.settingVisible) {
        Column() {
          this.SettingPage()
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 104 })
        .backgroundColor('#F7F8FA')
        .opacity(this.settingOpacity)
        .translate({ x: this.settingOffsetX })
      } else {
        Scroll() {
          Column() {
            this.UserCard()
            this.StatsGrid()
            this.SettingEntrySection()
            this.DataSection()
            this.AboutSection()
          }
          .padding({ left: 16, right: 16, top: 20, bottom: 104 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F7F8FA')
        .opacity(this.profileOpacity)
        .translate({ x: this.profileOffsetX })
      }
      this.AboutDialog()
      this.NameDialog()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UserCard() {
    Column() {
      Row() {
        this.AvatarView(74)
        Column() {
          Text(this.nickname)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text(`账号：${this.account}`)
            .fontSize(13)
            .fontColor('#59636F')
            .margin({ top: 6 })
          Text(`加入时间：${this.createdText}`)
            .fontSize(12)
            .fontColor('#7B8794')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .margin({ bottom: 14 })
  }

  @Builder
  AvatarView(size: number) {
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
        Column() {
          Text(this.nickname.substring(0, 1).toUpperCase())
            .fontSize(size > 60 ? 30 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(size)
        .height(size)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.avatarColor(this.avatarKey))
        .borderRadius(size / 2)
      }
    }
    .width(size)
    .height(size)
    .margin({ right: 14 })
  }

  @Builder
  StatsGrid() {
    Grid() {
      GridItem() {
        Column() {
          Text('本月收入').fontSize(13).fontColor('#7B8794')
          Text(this.monthIncomeText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00A870')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
      GridItem() {
        Column() {
          Text('本月支出').fontSize(13).fontColor('#7B8794')
          Text(this.monthExpenseText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E84026')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
      GridItem() {
        Column() {
          Text('预算额度').fontSize(13).fontColor('#7B8794')
          Text(this.monthBudgetText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2298F2')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
      GridItem() {
        Column() {
          Text('账单数量').fontSize(13).fontColor('#7B8794')
          Text(this.recordCountText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#7B61FF')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  SettingEntrySection() {
    Column() {
      Row() {
        Text('设置')
          .fontColor('#2298F2')
          .fontSize(18)
      }
      .width('100%')
      .height(48)
      .onClick(() => this.openSettingPage())
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 14 })
  }

  @Builder
  SettingPage() {
    Column() {
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .fillColor('#2298F2')
          .onClick(() => this.closeSettingPage())
        Blank()
        Text('设置')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
        Blank()
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .opacity(0)
      }
      .width('100%')
      .margin({ bottom: 14 })

      Column() {
        Row() {
          Text('头像')
            .fontSize(16)
            .fontColor('#182431')
          Blank()
          this.AvatarEditView(42)
          Text('›')
            .fontSize(20)
            .fontColor('#B7C0CC')
            .margin({ left: 8 })
        }
        .width('100%')
        .height(58)
        .onClick(() => this.pickAvatar())

        Row() {
          Text('名字')
            .fontSize(16)
            .fontColor('#182431')
          Blank()
          Text(this.nickname)
            .fontSize(15)
            .fontColor('#59636F')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('›')
            .fontSize(20)
            .fontColor('#B7C0CC')
            .margin({ left: 8 })
        }
        .width('100%')
        .height(58)
        .border({ width: { top: 1 }, color: '#EDF0F5' })
        .onClick(() => this.openNameDialog())

        Row() {
          Text('退出登录')
            .fontSize(16)
            .fontColor('#E84026')
          Blank()
          Text('›')
            .fontSize(20)
            .fontColor('#B7C0CC')
        }
        .width('100%')
        .height(58)
        .border({ width: { top: 1 }, color: '#EDF0F5' })
        .onClick(() => this.logout())
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .borderRadius(14)

      Column() {
        Text(`账号：${this.account}`)
          .fontSize(13)
          .fontColor('#7B8794')
          .width('100%')
        Text(`最近登录：${this.lastLoginText}`)
          .fontSize(13)
          .fontColor('#7B8794')
          .width('100%')
          .margin({ top: 6 })
      }
      .width('100%')
      .padding({ left: 4, right: 4 })
      .margin({ top: 12 })
    }
    .width('100%')
  }

  @Builder
  AvatarEditView(size: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (this.editAvatarKey === 'default') {
        Image($r('app.media.icon_avatar'))
          .width(size)
          .height(size)
          .borderRadius(size / 2)
          .objectFit(ImageFit.Cover)
      } else if (this.editAvatarKey.startsWith('file://') || this.editAvatarKey.startsWith('datashare://') || this.editAvatarKey.startsWith('media://')) {
        Image(this.editAvatarKey)
          .width(size)
          .height(size)
          .borderRadius(size / 2)
          .objectFit(ImageFit.Cover)
      } else {
        Text(this.editNickname.length > 0 ? this.editNickname.substring(0, 1).toUpperCase() : '账')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(size)
          .height(size)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.avatarColor(this.editAvatarKey))
          .borderRadius(size / 2)
      }
    }
    .width(size)
    .height(size)
  }

  @Builder
  DataSection() {
    Column() {
      this.SectionTitle('数据管理')
      Row() {
        this.ActionContent('导出本地数据', '#2298F2')
      }
      .width('100%')
      .height(44)
      .onClick(() => this.exportData())
      Row() {
        this.ActionContent('清空账单数据', '#E84026')
      }
      .width('100%')
      .height(44)
      .onClick(() => this.clearLedgerData())
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 14 })
  }

  @Builder
  AboutSection() {
    Column() {
      Row() {
        Text('关于')
          .fontColor('#2298F2')
          .fontSize(18)
      }
      .width('100%')
      .height(48)
      .onClick(() => this.openAboutDialog())
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 14 })
  }

  @Builder
  AboutDialog() {
    if (this.aboutVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.aboutDialogOpacity)
          .onClick(() => this.closeAboutDialog())
        Column() {
          Text('关于项目')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .width('100%')
          Text('这是一款面向日常生活场景的本地记账应用，围绕快速记账、预算管理、收支报表和个人数据管理进行设计。项目基于 OpenHarmony 5.1 API 19 开发，使用 ArkTS、ArkUI 和 Preferences 本地持久化能力完成数据存储与页面状态管理。')
            .fontSize(14)
            .fontColor('#59636F')
            .lineHeight(22)
            .width('100%')
            .margin({ top: 14 })
          Text('应用支持收入与支出录入、分类统计、预算预警、数据导出、头像昵称设置和安全退出。所有账单数据保存在本地，不依赖远程服务器。')
            .fontSize(14)
            .fontColor('#59636F')
            .lineHeight(22)
            .width('100%')
            .margin({ top: 10 })
          Button('我知道了')
            .height(42)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor('#2298F2')
            .borderRadius(22)
            .margin({ top: 18 })
            .onClick(() => this.closeAboutDialog())
        }
        .width('86%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .opacity(this.aboutDialogOpacity)
        .scale({ x: this.aboutDialogScale, y: this.aboutDialogScale })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  NameDialog() {
    if (this.nameDialogVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.nameDialogOpacity)
          .onClick(() => this.closeNameDialog())
        Column() {
          Text('修改名字')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .width('100%')
          TextInput({ placeholder: '请输入名字', text: this.editNickname })
            .height(44)
            .margin({ top: 16 })
            .onChange((value: string) => {
              this.editNickname = value
            })
          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontColor('#20242A')
              .backgroundColor('#F1F4F8')
              .borderRadius(22)
              .onClick(() => this.closeNameDialog())
            Button('保存')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontColor(Color.White)
              .backgroundColor('#2298F2')
              .borderRadius(22)
              .margin({ left: 10 })
              .onClick(() => this.saveName())
          }
          .margin({ top: 18 })
        }
        .width('86%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .opacity(this.nameDialogOpacity)
        .scale({ x: this.nameDialogScale, y: this.nameDialogScale })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#182431')
      .width('100%')
      .margin({ bottom: 8 })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor('#59636F')
      Blank()
      Text(value).fontSize(14).fontColor('#182431')
    }
    .width('100%')
    .height(38)
  }

  @Builder
  ActionContent(title: string, color: string) {
    Text(title).fontSize(15).fontColor(color)
    Blank()
    Text('›').fontSize(20).fontColor('#B7C0CC')
  }

  async logout(): Promise<void> {
    await appStore.logout()
    promptAction.openToast({ message: '已退出登录', duration: 1200 })
    AppStorage.setOrCreate('isLogin', false)
  }

  async exportData(): Promise<void> {
    try {
      const uri = await appStore.persistExportData()
      promptAction.openToast({ message: '已导出账单 JSON 文件', duration: 1500 })
      console.info(`Ledger data exported to: ${uri}`)
    } catch (error) {
      promptAction.openToast({ message: `${error}`, duration: 1500 })
    }
  }

  async clearLedgerData(): Promise<void> {
    await appStore.clearData()
    this.recordCount = 0
    this.monthIncome = 0
    this.monthExpense = 0
    this.monthIncomeText = '0.00元'
    this.monthExpenseText = '0.00元'
    this.recordCountText = '0 笔'
    this.syncProfileState()
    this.refreshTick += 1
    promptAction.openToast({ message: '账单已清空', duration: 1500 })
  }

  openSettingPage(): void {
    this.editNickname = this.nickname
    this.editAvatarKey = this.avatarKey
    animateTo({ duration: 120, curve: Curve.EaseIn }, () => {
      this.profileOpacity = 0
      this.profileOffsetX = -32
    })
    this.settingOpacity = 0
    this.settingOffsetX = 64
    this.settingVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.settingOpacity = 1
        this.settingOffsetX = 0
      })
    }, 20)
  }

  closeSettingPage(): void {
    this.profileOpacity = 0
    this.profileOffsetX = -32
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.settingOpacity = 0
      this.settingOffsetX = 64
    })
    setTimeout(() => {
      this.settingVisible = false
      this.editNickname = this.nickname
      this.editAvatarKey = this.avatarKey
      this.profileOpacity = 0
      this.profileOffsetX = -32
      setTimeout(() => {
        animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
          this.profileOpacity = 1
          this.profileOffsetX = 0
        })
      }, 20)
    }, 180)
  }

  openAboutDialog(): void {
    this.aboutDialogOpacity = 0
    this.aboutDialogScale = 0.92
    this.aboutVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.aboutDialogOpacity = 1
        this.aboutDialogScale = 1
      })
    }, 20)
  }

  closeAboutDialog(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.aboutDialogOpacity = 0
      this.aboutDialogScale = 0.94
    })
    setTimeout(() => {
      this.aboutVisible = false
    }, 180)
  }

  openNameDialog(): void {
    this.editNickname = this.nickname
    this.nameDialogOpacity = 0
    this.nameDialogScale = 0.92
    this.nameDialogVisible = true
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.nameDialogOpacity = 1
        this.nameDialogScale = 1
      })
    }, 20)
  }

  closeNameDialog(): void {
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.nameDialogOpacity = 0
      this.nameDialogScale = 0.94
    })
    setTimeout(() => {
      this.nameDialogVisible = false
      this.editNickname = this.nickname
    }, 180)
  }

  async pickAvatar(): Promise<void> {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const options = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1
      const result = await photoPicker.select(options)
      if (result.photoUris.length > 0) {
        const nextAvatar = result.photoUris[0]
        this.editAvatarKey = nextAvatar
        await appStore.updateProfile(this.nickname, nextAvatar)
        this.syncProfileState()
        this.refreshTick += 1
        this.viewVersion += 1
        promptAction.openToast({ message: '头像已更新', duration: 1200 })
      }
    } catch (error) {
      promptAction.openToast({ message: '头像选择失败', duration: 1500 })
    }
  }

  async saveName(): Promise<void> {
    const nextNickname = this.editNickname.trim()
    if (nextNickname.length === 0) {
      promptAction.openToast({ message: '请输入昵称', duration: 1500 })
      return
    }
    await appStore.updateProfile(nextNickname, this.avatarKey)
    this.syncProfileState()
    this.closeNameDialog()
    this.refreshTick += 1
    promptAction.openToast({ message: '名字已更新', duration: 1200 })
  }

  private avatarColor(key: string): string {
    let color = '#2298F2'
    AVATAR_OPTIONS.forEach((item: AvatarOption) => {
      if (item.key === key) {
        color = item.color
      }
    })
    return color
  }

}
