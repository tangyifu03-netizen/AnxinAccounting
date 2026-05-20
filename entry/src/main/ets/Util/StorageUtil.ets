import { preferences } from '@kit.ArkData'
import common from '@ohos.app.ability.common'

const defName: string = 'MY_APP_PF'

export default class StorageUtil {
  private static context: common.UIAbilityContext

  static init(ctx: common.UIAbilityContext): void {
    StorageUtil.context = ctx
  }

  private static async getPreferences(name: string): Promise<preferences.Preferences> {
    if (!StorageUtil.context) {
      throw new Error('StorageUtil has not been initialized')
    }
    return preferences.getPreferences(StorageUtil.context, name)
  }


  static async get(key: string, value: preferences.ValueType, name: string = defName): Promise<preferences.ValueType> {
    const store = await StorageUtil.getPreferences(name)
    return store.get(key, value)
  }

  static async put(key: string, value: preferences.ValueType, name: string = defName): Promise<void> {
    const store = await StorageUtil.getPreferences(name)
    await store.put(key, value)
    await store.flush()
  }

  static async delete(key: string, name: string = defName): Promise<void> {
    const store = await StorageUtil.getPreferences(name)
    await store.delete(key)
    await store.flush()
  }

  static async clear(name: string = defName): Promise<void> {
    const store = await StorageUtil.getPreferences(name)
    await store.clear()
    await store.flush()
  }
}
