import { promptAction } from '@kit.ArkUI'
import { registerComp } from './registerComp'
import { appStore } from '../store/GlobalStore'

@Component
export struct LoginView {
  @State account: string = ''
  @State password: string = ''
  @State errorText: string = ''
  @State @Watch('handleRegisterVisibleChange') showRegister: boolean = false
  @State authPanelOffsetX: number = 0
  @State authPanelOpacity: number = 1

  build() {
    Stack() {
      Column() {
        Text('欢迎回来')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .width('100%')
          .margin({ bottom: 8 })
        Text('安心记账')
          .fontSize(16)
          .fontColor('#59636F')
          .width('100%')
          .margin({ bottom: 36 })
        TextInput({ placeholder: '请输入账号', text: this.account })
          .height(48)
          .onChange((value: string) => this.account = value)
          .margin({ bottom: 12 })
        TextInput({ placeholder: '请输入密码', text: this.password })
          .height(48)
          .type(InputType.Password)
          .onChange((value: string) => this.password = value)
          .margin({ bottom: 12 })
        if (this.errorText.length > 0) {
          Text(this.errorText)
            .fontSize(13)
            .fontColor('#E84026')
            .width('100%')
            .margin({ bottom: 12 })
        }
        Button('登录')
          .width('100%')
          .height(46)
          .fontSize(17)
          .fontColor(Color.White)
          .backgroundColor('#0A59F7')
          .borderRadius(23)
          .onClick(() => this.login())
        Text('没有账号，去注册')
          .fontSize(15)
          .fontColor('#0A59F7')
          .margin({ top: 16 })
          .onClick(() => {
            this.openRegister()
          })
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F7F8FA')
      .opacity(this.showRegister ? 0 : this.authPanelOpacity)
      .translate({ x: this.showRegister ? -64 : this.authPanelOffsetX })

      if (this.showRegister) {
        registerComp({ showRegister: $showRegister, loginAccount: $account })
          .opacity(this.authPanelOpacity)
          .translate({ x: this.authPanelOffsetX })
      }
    }
    .width('100%')
    .height('100%')
  }

  openRegister(): void {
    this.authPanelOpacity = 0
    this.authPanelOffsetX = 64
    this.showRegister = true
    setTimeout(() => {
      animateTo({ duration: 240, curve: Curve.EaseOut }, () => {
        this.authPanelOpacity = 1
        this.authPanelOffsetX = 0
      })
    }, 20)
  }

  handleRegisterVisibleChange(): void {
    if (this.showRegister) {
      return
    }
    this.authPanelOpacity = 0
    this.authPanelOffsetX = -64
    setTimeout(() => {
      animateTo({ duration: 240, curve: Curve.EaseOut }, () => {
        this.authPanelOpacity = 1
        this.authPanelOffsetX = 0
      })
    }, 20)
  }

  async login(): Promise<void> {
    const accountError = appStore.userRepo.validateAccount(this.account)
    const passwordError = appStore.userRepo.validatePassword(this.password)
    if (accountError || passwordError) {
      this.errorText = accountError || passwordError
      return
    }
    try {
      await appStore.login(this.account, this.password)
      promptAction.openToast({ message: '登录成功', duration: 1200 })
      AppStorage.setOrCreate('isLogin', true)
    } catch (error) {
      this.errorText = `${error.message}`
    }
  }
}
