// QR码解析工具
// 注意：需要在浏览器环境中使用jsQR库

export interface ActivationCode {
  smdp: string
  matchingId: string
  oid?: string
  reqConCode: boolean
}

export function parseActivationCode(text: string): ActivationCode | null {
  // 解析格式: LPA:1$SMDP$MatchingID$OID$ReqConCode
  const regex = /LPA:1\$([^\$]*)\$([^\$]*)(?:\$([^\$]*))?(?:\$([^\$]*))?/
  const match = text.match(regex)
  
  if (match) {
    return {
      smdp: match[1],
      matchingId: match[2],
      oid: match[3],
      reqConCode: match[4] === '1'
    }
  }
  
  return null
}

// 从图片URL解析QR码（需要使用jsQR库）
export async function parseQRCodeFromImage(imageUrl: string): Promise<ActivationCode | null> {
  return new Promise((resolve) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    
    img.onload = () => {
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      if (!ctx) {
        resolve(null)
        return
      }
      
      canvas.width = img.width
      canvas.height = img.height
      ctx.drawImage(img, 0, 0)
      
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      
      // 动态导入jsQR（如果可用）
      // @ts-ignore
      if (typeof window !== 'undefined' && window.jsQR) {
        // @ts-ignore
        const code = window.jsQR(imageData.data, imageData.width, imageData.height)
        if (code) {
          const parsed = parseActivationCode(code.data)
          resolve(parsed)
          return
        }
      }
      
      resolve(null)
    }
    
    img.onerror = () => resolve(null)
    img.src = imageUrl
  })
}

