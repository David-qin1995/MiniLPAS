import { useEffect, useState } from 'react'
import { parseQRCodeFromImage, parseActivationCode } from '../utils/qrCodeParser'
import { useAppStore } from '../store/useAppStore'

interface PasteResult {
  smdp: string
  matchingId: string
  confirmCode?: string
}

export function usePasteQRCode(onPaste?: (result: PasteResult) => void) {
  const { showToast } = useAppStore()
  const [isListening, setIsListening] = useState(false)

  useEffect(() => {
    if (!isListening) return

    const handlePaste = async (e: ClipboardEvent) => {
      const items = e.clipboardData?.items
      if (!items) return

      // 检查剪贴板中是否有图片
      for (let i = 0; i < items.length; i++) {
        const item = items[i]
        
        if (item.type.startsWith('image/')) {
          e.preventDefault()
          const file = item.getAsFile()
          if (!file) continue

          const reader = new FileReader()
          reader.onload = async (e) => {
            const dataUrl = reader.result as string
            try {
              const result = await parseQRCodeFromImage(dataUrl)
              if (result) {
                onPaste?.({
                  smdp: result.smdp,
                  matchingId: result.matchingId,
                  confirmCode: result.reqConCode ? '' : undefined,
                })
                showToast('二维码粘贴成功', 'success')
              } else {
                showToast('无法从剪贴板图片中解析二维码', 'error')
              }
            } catch (error) {
              showToast('二维码解析失败', 'error')
            }
          }
          reader.readAsDataURL(file)
          return
        }

        // 检查剪贴板中是否有文本（可能是激活码）
        if (item.type === 'text/plain') {
          item.getAsString(async (text) => {
            const parsed = parseActivationCode(text.trim())
            if (parsed) {
              e.preventDefault()
              onPaste?.({
                smdp: parsed.smdp,
                matchingId: parsed.matchingId,
                confirmCode: parsed.reqConCode ? '' : undefined,
              })
              showToast('激活码粘贴成功', 'success')
            }
          })
        }
      }
    }

    document.addEventListener('paste', handlePaste)
    return () => {
      document.removeEventListener('paste', handlePaste)
    }
  }, [isListening, onPaste, showToast])

  return {
    isListening,
    startListening: () => setIsListening(true),
    stopListening: () => setIsListening(false),
  }
}

