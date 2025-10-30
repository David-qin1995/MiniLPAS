import { useEffect, useRef } from 'react'
import { useAppStore } from '../store/useAppStore'

export function useServerEvents() {
  const showToast = useAppStore((s) => s.showToast)
  const updateProgress = useAppStore((s) => s.updateProgress)
  const showProgress = useAppStore((s) => s.showProgress)
  const hideProgress = useAppStore((s) => s.hideProgress)
  const wsRef = useRef<WebSocket | null>(null)
  const triggerProfilesRefresh = useAppStore((s) => s.triggerProfilesRefresh)
  const triggerNotificationsRefresh = useAppStore((s) => s.triggerNotificationsRefresh)

  useEffect(() => {
    const url = (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws/client'
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onopen = () => {
      showToast('已连接服务器事件通道', 'success')
    }
    ws.onclose = () => {
      showToast('服务器事件通道已断开', 'warning')
    }
    ws.onerror = () => {
      showToast('服务器事件通道异常', 'error')
    }
    ws.onmessage = (ev) => {
      try {
        const msg = JSON.parse(ev.data)
        const topic = msg.topic as string
        const data = msg.data
        if (topic === 'progress') {
          const text = data?.message || '执行中...'
          let pct = typeof data?.progress === 'number' ? data.progress : undefined
          if (pct === undefined && typeof text === 'string') {
            const m = text.match(/(\d{1,3})%/)
            if (m) pct = Math.min(100, Math.max(0, parseInt(m[1], 10)))
          }
          // 累积步骤：将不同 message 作为步骤，最多保留 8 条
          const current = (useAppStore.getState().progress) || undefined
          const steps = current?.steps ? [...current.steps] : []
          if (!steps.length || steps[steps.length - 1] !== text) {
            steps.push(text)
            if (steps.length > 8) steps.shift()
          }
          const currentStep = steps.length - 1
          const base = { message: text, steps, currentStep }
          if (pct !== undefined) {
            if (!pct || pct < 0) {
              showProgress({ ...base, progress: -1 })
            } else {
              showProgress({ ...base, progress: pct })
              updateProgress({ message: text, progress: pct, steps, currentStep })
              if (pct >= 100) hideProgress()
            }
          } else {
            showProgress({ ...base, progress: -1 })
          }
        } else if (topic === 'agent-response') {
          const ok = data?.success === true
          const text = ok ? (data?.data || '操作成功') : (data?.error || '操作失败')
          showToast(text, ok ? 'success' : 'error')
          if (ok) {
            const t = (data?.type || '').toString().toLowerCase()
            if (['download-profile','enable-profile','disable-profile','delete-profile','set-profile-nickname'].includes(t)) {
              triggerProfilesRefresh()
            }
            if (['process-notification','remove-notification','get-notifications'].includes(t)) {
              triggerNotificationsRefresh()
            }
          }
        }
      } catch {
        // ignore parse errors
      }
    }

    return () => {
      try { ws.close() } catch {}
      wsRef.current = null
    }
    // mount once
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
}


