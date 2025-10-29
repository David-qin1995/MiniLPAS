import { Paper, Typography, Chip } from '@mui/material'
import { useEffect, useState } from 'react'

interface DeviceStatusProps {
  connected: boolean
  onConnectionChange: (connected: boolean) => void
}

export default function DeviceStatus({ onConnectionChange }: DeviceStatusProps) {
  const [status, setStatus] = useState<'connecting' | 'connected' | 'disconnected'>('disconnected')

  useEffect(() => {
    // 检查代理连接状态
    const checkStatus = () => {
      fetch('http://localhost:8080/api/devices/status')
        .then(res => res.json())
        .then(data => {
          if (data.success && data.data?.connected) {
            setStatus('connected')
            onConnectionChange(true)
          } else {
            setStatus('disconnected')
            onConnectionChange(false)
          }
        })
        .catch(() => {
          setStatus('disconnected')
          onConnectionChange(false)
        })
    }
    
    // 立即检查一次
    checkStatus()
    
    // 每3秒轮询一次状态
    const interval = setInterval(checkStatus, 3000)
    
    return () => clearInterval(interval)
  }, [onConnectionChange])

  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h6" gutterBottom>
        连接状态
      </Typography>
      <Chip 
        label={
          status === 'connected' ? '已连接' :
          status === 'connecting' ? '连接中...' :
          '未连接'
        }
        color={status === 'connected' ? 'success' : 'default'}
        sx={{ mr: 2 }}
      />
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
        {status === 'disconnected' && '请先启动本地代理服务'}
      </Typography>
    </Paper>
  )
}

