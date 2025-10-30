import { useEffect, useState } from 'react'
import { Chip, Tooltip, Stack } from '@mui/material'

export default function SystemStatus() {
  const [health, setHealth] = useState<'UP' | 'DOWN' | 'UNKNOWN'>('UNKNOWN')
  const [agents, setAgents] = useState<number>(0)
  const [wsOk, setWsOk] = useState<boolean>(false)

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const h = await fetch('/actuator/health').then(r => r.json()).catch(() => null)
        setHealth((h?.status as any) || 'UNKNOWN')
      } catch {}
      try {
        const s = await fetch('/api/devices/status').then(r => r.json()).catch(() => null)
        const data = s?.data || s
        setAgents(Number(data?.agentCount || 0))
      } catch {}
      try {
        // 简易探测：尝试短连后关闭
        const url = (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws/client'
        const ws = new WebSocket(url)
        const timer = setTimeout(() => { try { ws.close() } catch {} }, 500)
        ws.onopen = () => { setWsOk(true); try { ws.close() } catch {}; clearTimeout(timer) }
        ws.onclose = () => {}
        ws.onerror = () => { setWsOk(false) }
      } catch { setWsOk(false) }
    }
    fetchStatus()
    const id = setInterval(fetchStatus, 10000)
    return () => clearInterval(id)
  }, [])

  return (
    <Stack direction="row" spacing={1}>
      <Tooltip title={`后端健康: ${health}`}>
        <Chip size="small" label={health} color={health === 'UP' ? 'success' : (health === 'DOWN' ? 'error' : 'default')} />
      </Tooltip>
      <Tooltip title={`已连接代理: ${agents}`}>
        <Chip size="small" label={`Agents ${agents}`} color={agents > 0 ? 'primary' : 'default'} />
      </Tooltip>
      <Tooltip title={`WS通道: ${wsOk ? '可用' : '不可用'}`}>
        <Chip size="small" label={`WS ${wsOk ? 'OK' : 'DOWN'}`} color={wsOk ? 'success' : 'warning'} />
      </Tooltip>
    </Stack>
  )
}


