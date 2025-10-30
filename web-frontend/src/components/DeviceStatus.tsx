import { Paper, Typography, Chip, Box, CircularProgress } from '@mui/material'
import { useEffect, useState } from 'react'
import { useAppStore } from '../store/useAppStore'
import { deviceApi } from '../utils/api'
// import { io, Socket } from 'socket.io-client'
// 暂时禁用 Socket.IO，使用轮询

export default function DeviceStatus() {
  const setConnected = useAppStore((s) => s.setConnected)
  const [status, setStatus] = useState<'connecting' | 'connected' | 'disconnected'>('disconnected')
  // const [socket, setSocket] = useState<Socket | null>(null)

  useEffect(() => {
    // 初始检查状态
    checkStatus()

    // 暂时禁用 WebSocket，使用轮询方式
    // TODO: 启用 WebSocket 实时更新
    console.log('Using polling mode for device status')
    
    // 每 3 秒轮询一次状态
    const pollingInterval = setInterval(checkStatus, 3000)

    return () => {
      clearInterval(pollingInterval)
    }
  }, [])

  const checkStatus = async () => {
    try {
      const response = await deviceApi.getStatus()
      const data = response.data?.data || response.data
      if (data?.connected) {
        setStatus('connected')
        setConnected(true)
      } else {
        setStatus('disconnected')
        setConnected(false)
      }
    } catch (error) {
      setStatus('disconnected')
      setConnected(false)
    }
  }

  // const startPolling = () => {
  //   // 如果 WebSocket 失败，增加轮询频率
  //   const interval = setInterval(checkStatus, 2000)
  //   return () => clearInterval(interval)
  // }

  const getStatusColor = () => {
    switch (status) {
      case 'connected':
        return 'success'
      case 'connecting':
        return 'warning'
      default:
        return 'default'
    }
  }

  const getStatusText = () => {
    switch (status) {
      case 'connected':
        return '已连接'
      case 'connecting':
        return '连接中...'
      default:
        return '未连接'
    }
  }

  return (
    <Paper elevation={2} sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Typography variant="h6" component="div">
          连接状态
        </Typography>
        <Chip 
          label={getStatusText()}
          color={getStatusColor()}
          icon={status === 'connecting' ? <CircularProgress size={16} /> : undefined}
        />
        {status === 'connected' && (
          <Chip 
            label="代理服务运行中"
            color="success"
            variant="outlined"
            size="small"
          />
        )}
      </Box>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1.5 }}>
        {status === 'disconnected' && '请先启动本地代理服务'}
        {status === 'connecting' && '正在连接代理服务...'}
        {status === 'connected' && '代理服务已就绪，可以管理配置文件'}
      </Typography>
    </Paper>
  )
}
