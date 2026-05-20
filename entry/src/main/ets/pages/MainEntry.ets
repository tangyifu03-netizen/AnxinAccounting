import { LoginView } from '../pageComp/loginView'
import { Index } from '../pageComp/Index'
import { appStore } from '../store/GlobalStore'

@Entry
@Component
struct MainEntry {
  @StorageLink('isLogin') @Watch('handleLoginStateChange') isLogin: boolean = false
  @State isReady: boolean = false
  @State pageOpacity: number = 1
  @State pageOffsetX: number = 0
  @State lastLoginState: boolean = false

  async aboutToAppear(): Promise<void> {
    await appStore.init()
    AppStorage.setOrCreate('isLogin', appStore.isLoggedIn)
    this.lastLoginState = appStore.isLoggedIn
    this.isReady = true
  }

  build() {
    Column() {
      // if (!this.isReady) {
      //   Column() {
      //     LoadingProgress().width(50).height(50).color('#0A59F7')
      //     Text('正在加载本地数据').fontSize(15).fontColor('#59636F').margin({ top: 16 })
      //   }
      //   .width('100%')
      //   .height('100%')
      //   .justifyContent(FlexAlign.Center)
      // } else if (!this.isLogin) {
      //   LoginView()
      // } else {
        Index()
      // }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
    .opacity(this.pageOpacity)
    .translate({ x: this.pageOffsetX })
  }

  handleLoginStateChange(): void {
    if (!this.isReady || this.lastLoginState === this.isLogin) {
      return
    }
    const direction = this.isLogin ? 1 : -1
    this.lastLoginState = this.isLogin
    this.pageOpacity = 0
    this.pageOffsetX = 36 * direction
    setTimeout(() => {
      animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.pageOpacity = 1
        this.pageOffsetX = 0
      })
    }, 20)
  }
}
