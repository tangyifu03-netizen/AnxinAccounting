import { SessionState, UserProfile } from '../model/RecordModel'
import CryptoUtil from '../utils/CryptoUtil'
import StorageUtil from '../Util/StorageUtil'

const USER_KEY = 'ledger_user_profile'
const USER_LIST_KEY = 'ledger_user_list'
const SESSION_KEY = 'ledger_session_state'
const SESSION_TTL = 1000 * 60 * 60 * 24 * 7

export class UserRepository {
  validateAccount(account: string): string {
    if (!/^[A-Za-z0-9_]{4,20}$/.test(account)) {
      return '账号需为 4-20 位字母、数字或下划线'
    }
    return ''
  }

  validatePassword(password: string): string {
    if (!/^(?=.*[A-Za-z])(?=.*\d).{6,20}$/.test(password)) {
      return '密码需为 6-20 位，并同时包含字母和数字'
    }
    return ''
  }

  async getUser(): Promise<UserProfile | undefined> {
    const list = await this.getUsers()
    if (list.length > 0) {
      return list[0]
    }
    const raw = await StorageUtil.get(USER_KEY, '') as string
    if (!raw) {
      return undefined
    }
    try {
      return this.normalizeUser(JSON.parse(raw) as UserProfile)
    } catch (error) {
      await StorageUtil.delete(USER_KEY)
      return undefined
    }
  }

  async getUsers(): Promise<UserProfile[]> {
    const raw = await StorageUtil.get(USER_LIST_KEY, '[]') as string
    try {
      const users = JSON.parse(raw) as UserProfile[]
      const normalized: UserProfile[] = []
      users.forEach((item: UserProfile) => {
        normalized.push(this.normalizeUser(item))
      })
      return normalized
    } catch (error) {
      await StorageUtil.put(USER_LIST_KEY, '[]')
      return []
    }
  }

  async findUser(account: string): Promise<UserProfile | undefined> {
    const users = await this.getUsers()
    let result: UserProfile | undefined = undefined
    users.forEach((item: UserProfile) => {
      if (item.account === account) {
        result = item
      }
    })
    return result
  }

  async saveUsers(users: UserProfile[]): Promise<void> {
    await StorageUtil.put(USER_LIST_KEY, JSON.stringify(users))
  }

  async register(account: string, password: string): Promise<UserProfile> {
    const users = await this.getUsers()
    let exists: UserProfile | undefined = undefined
    users.forEach((item: UserProfile) => {
      if (item.account === account) {
        exists = item
      }
    })
    if (exists) {
      throw new Error('账号已存在')
    }
    const user: UserProfile = {
      account,
      nickname: account,
      passwordHash: CryptoUtil.hashPassword(account, password),
      avatarKey: 'default',
      createdAt: Date.now(),
      lastLoginAt: Date.now()
    }
    users.push(user)
    await this.saveUsers(users)
    await StorageUtil.put(USER_KEY, JSON.stringify(user))
    await StorageUtil.put('isLogin', false)
    AppStorage.setOrCreate('isLogin', false)
    return user
  }

  async login(account: string, password: string): Promise<UserProfile> {
    const user = await this.findUser(account)
    if (!user || user.account !== account || user.passwordHash !== CryptoUtil.hashPassword(account, password)) {
      throw new Error('账号或密码错误')
    }
    user.lastLoginAt = Date.now()
    const users = await this.getUsers()
    const updated: UserProfile[] = []
    users.forEach((item: UserProfile) => {
      if (item.account === user.account) {
        updated.push(user)
      } else {
        updated.push(item)
      }
    })
    await this.saveUsers(updated)
    await StorageUtil.put(USER_KEY, JSON.stringify(user))
    await this.createSession(account)
    return user
  }

  async restoreSession(): Promise<UserProfile | undefined> {
    const raw = await StorageUtil.get(SESSION_KEY, '') as string
    if (!raw) {
      return undefined
    }
    let session: SessionState
    try {
      session = JSON.parse(raw) as SessionState
    } catch (error) {
      await this.logout()
      return undefined
    }
    if (!session.loggedIn || session.expiresAt <= Date.now()) {
      await this.logout()
      return undefined
    }
    const user = await this.findUser(session.account)
    return user && user.account === session.account ? user : undefined
  }

  async updateAvatar(account: string, avatarKey: string): Promise<UserProfile | undefined> {
    const current = await this.findUser(account)
    return this.updateProfile(account, current?.nickname || account, avatarKey)
  }

  async updateProfile(account: string, nickname: string, avatarKey: string): Promise<UserProfile | undefined> {
    const users = await this.getUsers()
    let updatedUser: UserProfile | undefined = undefined
    const updated: UserProfile[] = []
    users.forEach((item: UserProfile) => {
      if (item.account === account) {
        const user: UserProfile = {
          account: item.account,
          nickname,
          passwordHash: item.passwordHash,
          avatarKey,
          createdAt: item.createdAt,
          lastLoginAt: item.lastLoginAt
        }
        updatedUser = user
        updated.push(user)
      } else {
        updated.push(item)
      }
    })
    if (!updatedUser) {
      const current = await this.getUser()
      if (current && current.account === account) {
        const user: UserProfile = {
          account: current.account,
          nickname,
          passwordHash: current.passwordHash,
          avatarKey,
          createdAt: current.createdAt,
          lastLoginAt: current.lastLoginAt
        }
        updatedUser = user
        updated.push(user)
      }
    }
    await this.saveUsers(updated)
    if (updatedUser) {
      await StorageUtil.put(USER_KEY, JSON.stringify(updatedUser))
    }
    return updatedUser
  }

  async logout(): Promise<void> {
    await StorageUtil.delete(SESSION_KEY)
    await StorageUtil.put('isLogin', false)
    AppStorage.setOrCreate('isLogin', false)
  }

  private async createSession(account: string): Promise<void> {
    const session: SessionState = {
      loggedIn: true,
      account,
      expiresAt: Date.now() + SESSION_TTL
    }
    await StorageUtil.put(SESSION_KEY, JSON.stringify(session))
    await StorageUtil.put('isLogin', true)
    AppStorage.setOrCreate('isLogin', true)
  }

  private normalizeUser(user: UserProfile): UserProfile {
    const normalized: UserProfile = {
      account: user.account,
      nickname: user.nickname,
      passwordHash: user.passwordHash,
      avatarKey: user.avatarKey || 'default',
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt
    }
    return normalized
  }
}
