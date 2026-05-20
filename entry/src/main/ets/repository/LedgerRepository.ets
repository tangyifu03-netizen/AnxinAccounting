import { BudgetConfig, CategoryBudget, LedgerRecord } from '../model/RecordModel'
import StorageUtil from '../Util/StorageUtil'
import fs from '@ohos.file.fs'
import picker from '@ohos.file.picker'

const RECORDS_KEY = 'ledger_records'
const BUDGET_KEY = 'budget_config'
const EXPORT_KEY = 'last_export_data'
const DEFAULT_BUDGET = '{"monthBudget":0,"categoryBudgets":[],"updatedAt":0}'

export class LedgerRepository {
  async list(): Promise<LedgerRecord[]> {
    const raw = await StorageUtil.get(RECORDS_KEY, '[]') as string
    try {
      return JSON.parse(raw) as LedgerRecord[]
    } catch (error) {
      await StorageUtil.put(RECORDS_KEY, '[]')
      return []
    }
  }

  async saveAll(records: LedgerRecord[]): Promise<void> {
    const sorted = records.sort((left: LedgerRecord, right: LedgerRecord) => right.time - left.time)
    await StorageUtil.put(RECORDS_KEY, JSON.stringify(sorted))
  }

  async upsert(record: LedgerRecord): Promise<void> {
    const records = await this.list()
    const index = records.findIndex((item: LedgerRecord) => item.id === record.id)
    if (index >= 0) {
      records[index] = {
        id: record.id,
        type: record.type,
        amount: record.amount,
        category: record.category,
        remark: record.remark,
        time: record.time,
        createdAt: record.createdAt,
        updatedAt: Date.now()
      }
    } else {
      records.unshift(record)
    }
    await this.saveAll(records)
  }

  async remove(id: string): Promise<void> {
    const records = await this.list()
    await this.saveAll(records.filter((item: LedgerRecord) => item.id !== id))
  }

  async getBudget(): Promise<BudgetConfig> {
    const raw = await StorageUtil.get(BUDGET_KEY, DEFAULT_BUDGET) as string
    try {
      const budget = JSON.parse(raw) as BudgetConfig
      if (!budget.categoryBudgets) {
        budget.categoryBudgets = []
      }
      return budget
    } catch (error) {
      const budget: BudgetConfig = { monthBudget: 0, categoryBudgets: [], updatedAt: Date.now() }
      await StorageUtil.put(BUDGET_KEY, JSON.stringify(budget))
      return budget
    }
  }

  async setBudget(monthBudget: number): Promise<void> {
    const old = await this.getBudget()
    const budget: BudgetConfig = { monthBudget, categoryBudgets: old.categoryBudgets, updatedAt: Date.now() }
    await StorageUtil.put(BUDGET_KEY, JSON.stringify(budget))
  }

  async setCategoryBudget(category: string, amount: number): Promise<void> {
    const old = await this.getBudget()
    const list: CategoryBudget[] = old.categoryBudgets.filter((item: CategoryBudget) => item.category !== category)
    if (amount > 0) {
      const next: CategoryBudget = { category, amount }
      list.push(next)
    }
    const budget: BudgetConfig = { monthBudget: old.monthBudget, categoryBudgets: list, updatedAt: Date.now() }
    await StorageUtil.put(BUDGET_KEY, JSON.stringify(budget))
  }

  async clearLedger(): Promise<void> {
    await StorageUtil.delete(RECORDS_KEY)
  }

  async saveExportData(value: string): Promise<void> {
    await StorageUtil.put(EXPORT_KEY, value)
  }

  async exportToUserFile(value: string): Promise<string> {
    await this.saveExportData(value)
    const saveOptions = new picker.DocumentSaveOptions()
    saveOptions.newFileNames = [`安心记账导出_${Date.now()}.json`]
    const documentPicker = new picker.DocumentViewPicker()
    const uris = await documentPicker.save(saveOptions)
    if (!uris || uris.length === 0) {
      throw new Error('已取消导出')
    }
    const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
    try {
      fs.writeSync(file.fd, value)
    } finally {
      fs.closeSync(file)
    }
    return uris[0]
  }
}
