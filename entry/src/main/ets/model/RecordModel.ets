export enum RecordType {
  Expense = 'expense',
  Income = 'income'
}

export interface LedgerRecord {
  id: string
  type: RecordType
  amount: number
  category: string
  remark: string
  time: number
  createdAt: number
  updatedAt: number
}

export interface UserProfile {
  account: string
  nickname: string
  passwordHash: string
  avatarKey: string
  createdAt: number
  lastLoginAt: number
}

export interface SessionState {
  loggedIn: boolean
  account: string
  expiresAt: number
}

export interface BudgetConfig {
  monthBudget: number
  categoryBudgets: CategoryBudget[]
  updatedAt: number
}

export interface CategoryBudget {
  category: string
  amount: number
}

export interface LedgerSummary {
  income: number
  expense: number
  balance: number
}

export interface CategorySummary {
  category: string
  amount: number
  percent: number
}

export interface TrendPoint {
  label: string
  income: number
  expense: number
}

export const EXPENSE_CATEGORIES: string[] = ['餐饮', '交通', '购物', '居住', '学习', '娱乐', '医疗', '通讯', '其他']
export const INCOME_CATEGORIES: string[] = ['工资', '奖金', '理财', '兼职', '红包', '其他']
