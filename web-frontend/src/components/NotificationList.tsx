import { 
  Typography, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow, 
  Paper, 
  IconButton, 
  Chip, 
  Button, 
  Checkbox,
  Box,
  Tooltip,
  CircularProgress
} from '@mui/material'
import { CheckCircle, Delete as DeleteIcon, SelectAll, InvertColorsOff } from '@mui/icons-material'
import { useEffect, useState } from 'react'
import { useAppStore } from '../store/useAppStore'
import { notificationApi } from '../utils/api'

interface Notification {
  seq: number
  profileManagementOperation: string
  iccid: string | null
  notificationAddress: string | null
}

export default function NotificationList() {
  const { setLoading, showToast } = useAppStore()
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [selected, setSelected] = useState<number[]>([])
  const [lastSelectedIndex, setLastSelectedIndex] = useState<number | null>(null)
  const loading = useAppStore((state) => state.loading['notifications'])

  const refreshTick = useAppStore((state) => state.refresh.notifications)
  useEffect(() => {
    fetchNotifications()
  }, [refreshTick])

  const fetchNotifications = async () => {
    setLoading('notifications', true)
    try {
      const response = await notificationApi.getNotifications()
      const data = response.data?.data || response.data || []
      setNotifications(data)
    } catch (error: any) {
      showToast(error.message || '获取通知列表失败', 'error')
    } finally {
      setLoading('notifications', false)
    }
  }

  const handleSelect = (seq: number, index: number, shiftKey: boolean = false) => {
    if (shiftKey && lastSelectedIndex !== null) {
      // Shift+点击：区间选择
      const start = Math.min(lastSelectedIndex, index)
      const end = Math.max(lastSelectedIndex, index)
      const range = notifications.slice(start, end + 1).map(n => n.seq)
      setSelected(prev => {
        const newSelected = [...prev]
        range.forEach(s => {
          if (!newSelected.includes(s)) newSelected.push(s)
        })
        return newSelected
      })
    } else {
      // 普通点击：切换选择
      setSelected(prev => 
        prev.includes(seq) 
          ? prev.filter(s => s !== seq)
          : [...prev, seq]
      )
      setLastSelectedIndex(index)
    }
  }

  const handleSelectAll = () => {
    if (selected.length === notifications.length) {
      setSelected([])
      setLastSelectedIndex(null)
    } else {
      setSelected(notifications.map(n => n.seq))
      setLastSelectedIndex(notifications.length > 0 ? 0 : null)
    }
  }

  const handleInvertSelection = () => {
    setSelected(prev => 
      notifications
        .map(n => n.seq)
        .filter(seq => !prev.includes(seq))
    )
  }

  const handleProcess = async (remove: boolean = false) => {
    if (selected.length === 0) {
      showToast('请先选择要处理的通知', 'warning')
      return
    }
    
    setLoading('process', true)
    try {
      // 处理每个选中的通知
      const promises = selected.map(seq => 
        notificationApi.processNotification(seq.toString(), remove ? 'remove' : 'process')
      )
      await Promise.all(promises)
      
      showToast(`已处理 ${selected.length} 个通知`, 'success')
      setSelected([])
      setLastSelectedIndex(null)
      fetchNotifications()
    } catch (error: any) {
      showToast(error.message || '处理失败', 'error')
    } finally {
      setLoading('process', false)
    }
  }

  const handleRemove = async () => {
    if (selected.length === 0) {
      showToast('请先选择要删除的通知', 'warning')
      return
    }
    
    if (!confirm(`确定要删除选中的 ${selected.length} 个通知吗？`)) return
    
    setLoading('remove', true)
    try {
      const promises = selected.map(seq => 
        notificationApi.deleteNotification(seq.toString())
      )
      await Promise.all(promises)
      
      showToast(`已删除 ${selected.length} 个通知`, 'success')
      setSelected([])
      setLastSelectedIndex(null)
      fetchNotifications()
    } catch (error: any) {
      showToast(error.message || '删除失败', 'error')
    } finally {
      setLoading('remove', false)
    }
  }

  const handleProcessSingle = async (seq: number) => {
    setLoading(`process-${seq}`, true)
    try {
      await notificationApi.processNotification(seq.toString(), 'process')
      showToast('通知已处理', 'success')
      fetchNotifications()
    } catch (error: any) {
      showToast(error.message || '处理失败', 'error')
    } finally {
      setLoading(`process-${seq}`, false)
    }
  }

  const getOperationText = (op: string): string => {
    const map: Record<string, string> = {
      'install': '安装',
      'enable': '启用',
      'disable': '禁用',
      'delete': '删除'
    }
    return map[op.toLowerCase()] || op
  }

  const getOperationColor = (op: string): 'error' | 'warning' | 'info' | 'success' | 'default' => {
    const map: Record<string, 'error' | 'warning' | 'info' | 'success' | 'default'> = {
      'delete': 'error',
      'disable': 'warning',
      'enable': 'success',
      'install': 'info'
    }
    return map[op.toLowerCase()] || 'default'
  }

  return (
    <>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6">
          通知列表
        </Typography>
        {selected.length > 0 && (
          <Chip 
            label={`已选择 ${selected.length} 个`}
            color="primary"
            variant="outlined"
          />
        )}
      </Box>
      
      {selected.length > 0 && (
        <Box sx={{ mb: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Button 
            variant="contained" 
            color="primary" 
            onClick={() => handleProcess(false)}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : <CheckCircle />}
          >
            处理选中 ({selected.length})
          </Button>
          <Button 
            variant="outlined" 
            color="error"
            onClick={handleRemove}
            disabled={loading}
            startIcon={<DeleteIcon />}
          >
            删除选中
          </Button>
          <Button 
            variant="outlined"
            onClick={() => {
              setSelected([])
              setLastSelectedIndex(null)
            }}
          >
            清除选择
          </Button>
        </Box>
      )}
      
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Tooltip title="全选">
                  <Checkbox
                    checked={notifications.length > 0 && selected.length === notifications.length}
                    indeterminate={selected.length > 0 && selected.length < notifications.length}
                    onChange={handleSelectAll}
                  />
                </Tooltip>
              </TableCell>
              <TableCell>序号</TableCell>
              <TableCell>操作类型</TableCell>
              <TableCell>ICCID</TableCell>
              <TableCell>通知地址</TableCell>
              <TableCell>操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading && notifications.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : notifications.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  暂无通知
                </TableCell>
              </TableRow>
            ) : (
              notifications.map((notif, index) => (
                <TableRow 
                  key={notif.seq}
                  selected={selected.includes(notif.seq)}
                  sx={{ 
                    '&:hover': { backgroundColor: 'action.hover' },
                    cursor: 'pointer'
                  }}
                  onClick={(e) => {
                    if ((e.target as HTMLElement).closest('button, a')) return
                    handleSelect(notif.seq, index, e.shiftKey)
                  }}
                >
                  <TableCell padding="checkbox" onClick={(e) => e.stopPropagation()}>
                    <Checkbox
                      checked={selected.includes(notif.seq)}
                      onChange={() => handleSelect(notif.seq, index)}
                    />
                  </TableCell>
                  <TableCell>{notif.seq}</TableCell>
                  <TableCell>
                    <Chip 
                      label={getOperationText(notif.profileManagementOperation)}
                      size="small"
                      color={getOperationColor(notif.profileManagementOperation)}
                    />
                  </TableCell>
                  <TableCell>{notif.iccid || '-'}</TableCell>
                  <TableCell>{notif.notificationAddress || '-'}</TableCell>
                  <TableCell onClick={(e) => e.stopPropagation()}>
                    <Tooltip title="处理">
                      <IconButton 
                        size="small"
                        onClick={() => handleProcessSingle(notif.seq)}
                        disabled={loading}
                      >
                        <CheckCircle />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
      
      {notifications.length > 0 && (
        <Box sx={{ mt: 2, display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
          <Tooltip title="反选">
            <Button 
              variant="outlined"
              size="small"
              onClick={handleInvertSelection}
              startIcon={<InvertColorsOff />}
            >
              反选
            </Button>
          </Tooltip>
        </Box>
      )}
    </>
  )
}
