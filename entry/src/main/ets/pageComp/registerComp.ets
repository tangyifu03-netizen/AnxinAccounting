import { promptAction } from '@kit.ArkUI'
import { appStore } from '../store/GlobalStore'

@Component
export struct registerComp {
  @State account: string = ''
  @State password: string = ''
  @State errorText: string = ''
  @State panelOpacity: number = 1
  @State panelOffsetX: number = 0
  @Link showRegister: boolean
  @Link loginAccount: string

  build() {
    Column() {
      Text('创建账号')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .width('100%')
        .margin({ bottom: 8 })
      Text('注册成功后返回登录')
        .fontSize(14)
        .fontColor('#59636F')
        .width('100%')
        .margin({ bottom: 32 })
      TextInput({ placeholder: '账号：4-20 位字母、数字或下划线', text: this.account })
        .height(48)
        .onChange((value: string) => this.account = value)
        .margin({ bottom: 12 })
      TextInput({ placeholder: '密码：6-20 位且包含字母和数字', text: this.password })
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
      Button('注册')
        .width('100%')
        .height(46)
        .fontSize(17)
        .fontColor(Color.White)
        .backgroundColor('#0A59F7')
        .borderRadius(23)
        .onClick(() => this.register())
      Row() {
        Image($r('app.media.back'))
          .width(18)
          .height(18)
          .fillColor('#0A59F7')
        Text('登录')
          .fontSize(15)
          .fontColor('#0A59F7')
          .margin({ left: 4 })
      }
        .margin({ top: 16 })
        .onClick(() => {
          this.closeRegister()
        })
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F7F8FA')
    .opacity(this.panelOpacity)
    .translate({ x: this.panelOffsetX })
  }

  closeRegister(): void {
    animateTo({ duration: 200, curve: Curve.EaseIn }, () => {
      this.panelOpacity = 0
      this.panelOffsetX = 64
    })
    setTimeout(() => {
      this.showRegister = false
      this.panelOpacity = 1
      this.panelOffsetX = 0
    }, 200)
  }

  async register(): Promise<void> {
    const accountError = appStore.userRepo.validateAccount(this.account)
    const passwordError = appStore.userRepo.validatePassword(this.password)
    if (accountError || passwordError) {
      this.errorText = accountError || passwordError
      return
    }
    try {
      await appStore.register(this.account, this.password)
      promptAction.openToast({ message: '注册成功，请登录', duration: 1500 })
      AppStorage.setOrCreate('isLogin', false)
      this.loginAccount = this.account
      this.account = ''
      this.password = ''
      this.errorText = ''
      this.closeRegister()
    } catch (error) {
      this.errorText = `${error.message}`
    }
  }
}
