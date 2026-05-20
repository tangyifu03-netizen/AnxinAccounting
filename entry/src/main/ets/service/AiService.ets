import http from '@ohos.net.http'
import { dayText, money } from '../common/Formatters'
import {
  AiChatMessage,
  AiLedgerOperationResponse,
  AiProviderMessage,
  AiProviderRequestBody,
  AiProviderResponseBody,
  AiRole,
  LedgerOperation
} from '../model/AiModel'
import { CategoryBudget, EXPENSE_CATEGORIES, INCOME_CATEGORIES, LedgerRecord, RecordType } from '../model/RecordModel'
import { appStore } from '../store/GlobalStore'
import StorageUtil from '../Util/StorageUtil'

const AI_API_KEY = 'deepseek_api_key'
const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions'
const DEEPSEEK_MODEL = 'deepseek-v4-flash'

export class AiService {
  async getApiKey(): Promise<string> {
    return await StorageUtil.get(AI_API_KEY, '') as string
  }

  async saveApiKey(apiKey: string): Promise<void> {
    await StorageUtil.put(AI_API_KEY, apiKey.trim())
  }

  async clearApiKey(): Promise<void> {
    await StorageUtil.delete(AI_API_KEY)
  }

  async chat(messages: AiChatMessage[]): Promise<string> {
    const apiKey = await this.getApiKey()
    if (apiKey.length === 0) {
      throw new Error('请先填写 DeepSeek API Key')
    }
    const requestMessages: AiProviderMessage[] = []
    requestMessages.push({
      role: AiRole.System,
      content: this.buildSystemPrompt()
    })
    messages.forEach((item: AiChatMessage) => {
      requestMessages.push({
        role: item.role,
        content: item.content
      })
    })
    const body: AiProviderRequestBody = {
      model: DEEPSEEK_MODEL,
      messages: requestMessages,
      stream: false,
      temperature: 0.6
    }
    const request = http.createHttp()
    try {
      const response = await request.request(DEEPSEEK_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        extraData: JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 60000,
        connectTimeout: 30000
      })
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`DeepSeek 请求失败：${response.responseCode}`)
      }
      const raw = response.result as string
      const data = JSON.parse(raw) as AiProviderResponseBody
      if (!data.choices || data.choices.length === 0 || !data.choices[0].message) {
        throw new Error('DeepSeek 返回内容为空')
      }
      return data.choices[0].message.content
    } finally {
      request.destroy()
    }
  }

  async parseLedgerOperation(content: string): Promise<LedgerOperation | undefined> {
    const apiKey = await this.getApiKey()
    if (apiKey.length === 0) {
      throw new Error('请先填写 DeepSeek API Key')
    }
    const requestMessages: AiProviderMessage[] = [
      {
        role: AiRole.System,
        content: this.buildLedgerOperationPrompt()
      },
      {
        role: AiRole.User,
        content
      }
    ]
    const body: AiProviderRequestBody = {
      model: DEEPSEEK_MODEL,
      messages: requestMessages,
      stream: false,
      temperature: 0.1
    }
    const reply = await this.requestDeepSeek(apiKey, body)
    const parsed = this.parseOperationResponse(reply)
    if (!parsed || parsed.action === 'chat') {
      return undefined
    }
    if (parsed.action !== 'add_record' && parsed.action !== 'update_record' && parsed.action !== 'delete_record') {
      return undefined
    }

    const targetRecord = this.findRecordById(parsed.targetId)
    if ((parsed.action === 'update_record' || parsed.action === 'delete_record') && !targetRecord) {
      return undefined
    }

    let type = parsed.type === 'income' ? RecordType.Income : RecordType.Expense
    if (targetRecord && parsed.type.length === 0) {
      type = targetRecord.type
    }

    let amount = parsed.amount
    if (targetRecord && (!Number.isFinite(amount) || amount <= 0)) {
      amount = targetRecord.amount
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      return undefined
    }

    let category = parsed.category
    if (targetRecord && category.length === 0) {
      category = targetRecord.category
    }
    category = this.normalizeCategory(type, category)

    let remark = parsed.remark
    if (targetRecord && remark.length === 0) {
      remark = targetRecord.remark
    }
    if (remark.length === 0) {
      remark = category
    }

    let time = Date.now()
    if (parsed.date.length > 0) {
      time = this.parseDateText(parsed.date)
    } else if (targetRecord) {
      time = targetRecord.time
    }

    const operation: LedgerOperation = {
      action: parsed.action,
      targetId: parsed.targetId,
      type,
      amount,
      category,
      remark,
      time,
      reply: parsed.reply
    }
    return operation
  }

  private async requestDeepSeek(apiKey: string, body: AiProviderRequestBody): Promise<string> {
    const request = http.createHttp()
    try {
      const response = await request.request(DEEPSEEK_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        extraData: JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 60000,
        connectTimeout: 30000
      })
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`DeepSeek 请求失败：${response.responseCode}`)
      }
      const raw = response.result as string
      const data = JSON.parse(raw) as AiProviderResponseBody
      if (!data.choices || data.choices.length === 0 || !data.choices[0].message) {
        throw new Error('DeepSeek 返回内容为空')
      }
      return data.choices[0].message.content
    } finally {
      request.destroy()
    }
  }

  private parseOperationResponse(reply: string): AiLedgerOperationResponse | undefined {
    let jsonText = reply.trim()
    const start = jsonText.indexOf('{')
    const end = jsonText.lastIndexOf('}')
    if (start >= 0 && end > start) {
      jsonText = jsonText.substring(start, end + 1)
    }
    try {
      return JSON.parse(jsonText) as AiLedgerOperationResponse
    } catch (error) {
      return undefined
    }
  }

  private findRecordById(id: string): LedgerRecord | undefined {
    let record: LedgerRecord | undefined = undefined
    appStore.records.forEach((item: LedgerRecord) => {
      if (item.id === id) {
        record = item
      }
    })
    return record
  }

  private normalizeCategory(type: RecordType, category: string): string {
    const validCategories = type === RecordType.Income ? INCOME_CATEGORIES : EXPENSE_CATEGORIES
    if (validCategories.indexOf(category) >= 0) {
      return category
    }
    return '其他'
  }

  private parseDateText(value: string): number {
    if (!value || value.length === 0) {
      return Date.now()
    }
    const parts = value.split('-')
    if (parts.length !== 3) {
      return Date.now()
    }
    const year = Number(parts[0])
    const month = Number(parts[1])
    const day = Number(parts[2])
    if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
      return Date.now()
    }
    const time = new Date(year, month - 1, day).getTime()
    if (time > Date.now()) {
      return Date.now()
    }
    return time
  }

  private buildLedgerOperationPrompt(): string {
    const today = dayText(Date.now())
    return `你是安心记账的账单操作解析器。请判断用户是否要对账单执行新增、修改、删除或普通查询。只返回 JSON，不要解释，不要使用 Markdown。今天日期是${today}。
返回格式固定为{"action":"add_record|update_record|delete_record|chat","targetId":"账单id或空字符串","type":"expense或income或空字符串","amount":数字,"category":"分类或空字符串","remark":"备注或空字符串","date":"YYYY-MM-DD或空字符串","reply":"给用户看的简短确认文案"}。
新增账单：action 返回 add_record，targetId 为空，日期无法确定时用今天。
修改账单：action 返回 update_record，必须从可操作账单列表中选择最匹配的 targetId；未提到的字段沿用目标账单原值，并返回修改后的完整 type、amount、category、remark、date。
删除账单：action 返回 delete_record，必须从可操作账单列表中选择最匹配的 targetId，同时返回该账单当前的完整 type、amount、category、remark、date。
如果用户只是查询、分析、聊天，或修改/删除目标不明确，action 返回 chat，targetId 为空，reply 用中文说明需要用户补充哪一笔账单。
支出分类只能从${EXPENSE_CATEGORIES.join('、')}中选择；收入分类只能从${INCOME_CATEGORIES.join('、')}中选择。无法确定分类时用“其他”。金额必须是数字。
可操作账单列表：${this.buildOperableRecordsContext()}`
  }

  private buildSystemPrompt(): string {
    return `你是“安心记账”的 AI 记账助手。请使用中文回答，语气简洁、温和、实用。你已获得当前 App 本地登录会话提供的用户资料和账单摘要权限，可以回答当前登录用户的账号、昵称、注册时间、最近登录时间、账单统计和预算情况。用户要求新增、修改或删除账单时，提醒用户我会先生成确认卡片，确认后再写入本地账单。不要声称没有绑定账号或无法访问当前登录用户资料；但不要暴露密码、密码哈希、API Key 或头像文件地址。不要编造不存在的数据。当前本地上下文如下：${this.buildUserContext()}${this.buildLedgerContext()}`
  }

  private buildUserContext(): string {
    const profile = appStore.profile
    if (!profile) {
      return '当前登录用户：未读取到登录用户资料。'
    }
    return `当前登录用户：账号${profile.account}，昵称${profile.nickname}，注册日期${dayText(profile.createdAt)}，最近登录${dayText(profile.lastLoginAt)}。`
  }

  private buildLedgerContext(): string {
    const month = appStore.summary('month')
    const budget = appStore.budget
    let context = `本月收入${money(month.income)}，本月支出${money(month.expense)}，本月结余${money(month.balance)}，总预算${money(budget.monthBudget)}。`
    if (budget.categoryBudgets.length > 0) {
      context += '分类预算：'
      budget.categoryBudgets.forEach((item: CategoryBudget) => {
        context += `${item.category}${money(item.amount)}；`
      })
    }
    const recent: LedgerRecord[] = []
    appStore.records.forEach((item: LedgerRecord) => {
      recent.push(item)
    })
    recent.sort((left: LedgerRecord, right: LedgerRecord) => right.time - left.time)
    context += '最近账单：'
    recent.slice(0, 8).forEach((item: LedgerRecord) => {
      const typeText = item.type === RecordType.Income ? '收入' : '支出'
      context += `${typeText}-${item.category}-${money(item.amount)}-${item.remark || '无备注'}；`
    })
    return context
  }

  private buildOperableRecordsContext(): string {
    const recent: LedgerRecord[] = []
    appStore.records.forEach((item: LedgerRecord) => {
      recent.push(item)
    })
    recent.sort((left: LedgerRecord, right: LedgerRecord) => right.time - left.time)
    if (recent.length === 0) {
      return '暂无账单。'
    }
    let context = ''
    recent.slice(0, 20).forEach((item: LedgerRecord) => {
      const typeText = item.type === RecordType.Income ? 'income' : 'expense'
      context += `id=${item.id}，date=${dayText(item.time)}，type=${typeText}，category=${item.category}，amount=${item.amount}，remark=${item.remark || '无备注'}；`
    })
    return context
  }
}

export const aiService = new AiService()
