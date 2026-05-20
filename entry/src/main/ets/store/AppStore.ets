import { buildSevenDayTrend, createId, startOfDay, startOfMonth, startOfWeek, summarize } from '../common/Formatters'
import {
  BudgetConfig,
  CategoryBudget,
  CategorySummary,
  EXPENSE_CATEGORIES,
  INCOME_CATEGORIES,
  LedgerRecord,
  LedgerSummary,
  RecordType,
  TrendPoint,
  UserProfile
} from '../model/RecordModel'
import { LedgerRepository } from '../repository/LedgerRepository'
import { UserRepository } from '../repository/UserRepository'

export class AppStore {
  userRepo: UserRepository = new UserRepository()
  ledgerRepo: LedgerRepository = new LedgerRepository()
  profile?: UserProfile
  records: LedgerRecord[] = []
  budget: BudgetConfig = { monthBudget: 0, categoryBudgets: [], updatedAt: 0 }
  isLoggedIn: boolean = false
  dataVersion: number = 0

  async init(): Promise<void> {
    const user = await this.userRepo.restoreSession()
    this.profile = user
    this.isLoggedIn = !!user
    await this.reloadLedger()
  }

  async register(account: string, password: string): Promise<void> {
    await this.userRepo.register(account, password)
    this.profile = undefined
    this.isLoggedIn = false
  }

  async login(account: string, password: string): Promise<void> {
    this.profile = await this.userRepo.login(account, password)
    this.isLoggedIn = true
  }

  async logout(): Promise<void> {
    await this.userRepo.logout()
    this.profile = undefined
    this.isLoggedIn = false
  }

  async updateAvatar(avatarKey: string): Promise<void> {
    if (!this.profile) {
      return
    }
    const user = await this.userRepo.updateAvatar(this.profile.account, avatarKey)
    if (user) {
      this.profile = user
      this.dataVersion += 1
    }
  }

  async updateProfile(nickname: string, avatarKey: string): Promise<void> {
    if (!this.profile) {
      return
    }
    const user = await this.userRepo.updateProfile(this.profile.account, nickname, avatarKey)
    if (user) {
      this.profile = user
      this.dataVersion += 1
    }
  }

  async reloadLedger(): Promise<void> {
    this.records = await this.ledgerRepo.list()
    this.budget = await this.ledgerRepo.getBudget()
    this.dataVersion += 1
  }

  async addRecord(type: RecordType, amount: number, category: string, remark: string, time: number): Promise<LedgerRecord> {
    const now = Date.now()
    const record: LedgerRecord = {
      id: createId('record'),
      type,
      amount,
      category,
      remark,
      time,
      createdAt: now,
      updatedAt: now
    }
    await this.ledgerRepo.upsert(record)
    await this.reloadLedger()
    return record
  }

  async updateRecord(record: LedgerRecord): Promise<void> {
    await this.ledgerRepo.upsert(record)
    await this.reloadLedger()
  }

  async removeRecord(id: string): Promise<void> {
    await this.ledgerRepo.remove(id)
    await this.reloadLedger()
  }

  async updateBudget(value: number): Promise<void> {
    await this.ledgerRepo.setBudget(value)
    await this.reloadLedger()
  }

  async updateCategoryBudget(category: string, value: number): Promise<void> {
    await this.ledgerRepo.setCategoryBudget(category, value)
    await this.reloadLedger()
  }

  categoryExpense(category: string): number {
    let amount = 0
    const monthStart = startOfMonth(Date.now())
    this.records.forEach((item: LedgerRecord) => {
      if (item.type === RecordType.Expense && item.category === category && item.time >= monthStart) {
        amount += item.amount
      }
    })
    return amount
  }

  categoryBudgetValue(category: string): number {
    let value = 0
    this.budget.categoryBudgets.forEach((budget: CategoryBudget) => {
      if (budget.category === category) {
        value = budget.amount
      }
    })
    return value
  }

  async clearData(): Promise<void> {
    await this.ledgerRepo.clearLedger()
    await this.reloadLedger()
  }

  summary(period: 'day' | 'week' | 'month' | 'all'): LedgerSummary {
    const now = Date.now()
    let start = 0
    if (period === 'day') {
      start = startOfDay(now)
    } else if (period === 'week') {
      start = startOfWeek(now)
    } else if (period === 'month') {
      start = startOfMonth(now)
    }
    const list: LedgerRecord[] = []
    this.records.forEach((item: LedgerRecord) => {
      if (item.time >= start) {
        list.push(item)
      }
    })
    return summarize(list)
  }

  categorySummary(type: RecordType): CategorySummary[] {
    const source = type === RecordType.Expense ? EXPENSE_CATEGORIES : INCOME_CATEGORIES
    const monthStart = startOfMonth(Date.now())
    const map = new Map<string, number>()
    let total = 0
    this.records.forEach((item: LedgerRecord) => {
      if (item.type === type && item.time >= monthStart) {
        total += item.amount
        map.set(item.category, (map.get(item.category) || 0) + item.amount)
      }
    })
    const result: CategorySummary[] = []
    source.forEach((category: string) => {
      const amount = map.get(category) || 0
      const item: CategorySummary = { category, amount, percent: total > 0 ? amount / total : 0 }
      if (item.amount > 0) {
        result.push(item)
      }
    })
    return result
  }

  trend(): TrendPoint[] {
    return buildSevenDayTrend(this.records)
  }

  budgetUsedRate(): number {
    if (this.budget.monthBudget <= 0) {
      return 0
    }
    return this.summary('month').expense / this.budget.monthBudget
  }

  exportData(): string {
    return JSON.stringify({ profile: this.profile, budget: this.budget, records: this.records }, null, 2)
  }

  async persistExportData(): Promise<string> {
    const data = this.exportData()
    return await this.ledgerRepo.exportToUserFile(data)
  }
}
