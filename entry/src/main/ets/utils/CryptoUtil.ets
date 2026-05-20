export default class CryptoUtil {
  static simpleHash(value: string): string {
    let hash = 2166136261
    for (let index = 0; index < value.length; index++) {
      hash ^= value.charCodeAt(index)
      hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24)
    }
    return (hash >>> 0).toString(16).padStart(8, '0')
  }

  static hashPassword(account: string, password: string): string {
    return CryptoUtil.simpleHash(`${account}:universityCompetition:${password}`)
  }
}
