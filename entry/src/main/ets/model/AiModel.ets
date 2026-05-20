import { RecordType } from './RecordModel'

export enum AiRole {
  User = 'user',
  Assistant = 'assistant',
  System = 'system'
}

export interface AiChatMessage {
  id: string
  role: AiRole
  content: string
  createdAt: number
}

export interface AiProviderMessage {
  role: string
  content: string
}

export interface AiProviderRequestBody {
  model: string
  messages: AiProviderMessage[]
  stream: boolean
  temperature: number
}

export interface AiProviderChoiceMessage {
  role: string
  content: string
}

export interface AiProviderChoice {
  index: number
  message: AiProviderChoiceMessage
  finish_reason: string
}

export interface AiProviderResponseBody {
  choices: AiProviderChoice[]
}

export interface AiLedgerOperationResponse {
  action: string
  targetId: string
  type: string
  amount: number
  category: string
  remark: string
  date: string
  reply: string
}

export interface LedgerOperation {
  action: string
  targetId: string
  type: RecordType
  amount: number
  category: string
  remark: string
  time: number
  reply: string
}
