import { LedgerRecord, LedgerSummary, RecordType, TrendPoint } from '../model/RecordModel'

export function money(value: number): string {
  return `${value.toFixed(2)}元`
}

export function dayText(time: number): string {
  const date = new Date(time)
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${date.getFullYear()}-${month}-${day}`
}

export function startOfDay(time: number): number {
  const date = new Date(time)
  date.setHours(0, 0, 0, 0)
  return date.getTime()
}

export function startOfWeek(time: number): number {
  const date = new Date(startOfDay(time))
  const offset = date.getDay() === 0 ? 6 : date.getDay() - 1
  date.setDate(date.getDate() - offset)
  return date.getTime()
}

export function startOfMonth(time: number): number {
  const date = new Date(time)
  return new Date(date.getFullYear(), date.getMonth(), 1).getTime()
}

export function summarize(records: LedgerRecord[]): LedgerSummary {
  let income = 0
  let expense = 0
  records.forEach((item: LedgerRecord) => {
    if (item.type === RecordType.Income) {
      income += item.amount
    } else {
      expense += item.amount
    }
  })
  const summary: LedgerSummary = { income, expense, balance: income - expense }
  return summary
}

export function buildSevenDayTrend(records: LedgerRecord[]): TrendPoint[] {
  const result: TrendPoint[] = []
  const today = startOfDay(Date.now())
  for (let index = 6; index >= 0; index--) {
    const begin = today - index * 24 * 60 * 60 * 1000
    const end = begin + 24 * 60 * 60 * 1000
    const summary = summarize(records.filter((item: LedgerRecord) => item.time >= begin && item.time < end))
    const point: TrendPoint = { label: dayText(begin).substring(5), income: summary.income, expense: summary.expense }
    result.push(point)
  }
  return result
}

export function createId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`
}
