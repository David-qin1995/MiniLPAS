import { Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton, Chip, Button, Checkbox } from '@mui/material'
import { CheckCircle } from '@mui/icons-material'
import { useEffect, useState } from 'react'

interface Notification {
  seq: number
  profileManagementOperation: string
  iccid: string | null
  notificationAddress: string | null
}

export default function NotificationList() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [selected, setSelected] = useState<number[]>([])

  useEffect(() => {
    fetchNotifications()
  }, [])

  const fetchNotifications = () => {
    fetch('http://localhost:8080/api/notifications')
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setNotifications(data.data || [])
        }
      })
      .catch(err => {
        console.error('获取通知列表失败:', err)
      })
  }

  const handleSelect = (seq: number) => {
    setSelected(prev => 
      prev.includes(seq) 
        ? prev.filter(s => s !== seq)
        : [...prev, seq]
    )
  }

  const handleSelectAll = () => {
    if (selected.length === notifications.length) {
      setSelected([])
    } else {
      setSelected(notifications.map(n => n.seq))
    }
  }

  const handleProcess = (remove: boolean = false) => {
    if (selected.length === 0) return
    
    fetch('http://localhost:8080/api/notifications/process', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ seq: selected, remove })
    })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          fetchNotifications()
          setSelected([])
        } else {
          alert('处理失败: ' + data.error)
        }
      })
      .catch(err => {
        alert('处理失败: ' + err.message)
      })
  }

  const handleRemove = () => {
    if (selected.length === 0) return
    if (!confirm(`确定要删除选中的 ${selected.length} 个通知吗？`)) return
    
    fetch('http://localhost:8080/api/notifications', {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ seq: selected })
    })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          fetchNotifications()
          setSelected([])
        } else {
          alert('删除失败: ' + data.error)
        }
      })
      .catch(err => {
        alert('删除失败: ' + err.message)
      })
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

  return (
    <>
      <Typography variant="h6" gutterBottom>
        通知列表
      </Typography>
      
      {selected.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <Button 
            variant="contained" 
            color="primary" 
            onClick={() => handleProcess(false)}
            style={{ marginRight: 8 }}
          >
            处理选中 ({selected.length})
          </Button>
          <Button 
            variant="outlined" 
            color="error"
            onClick={handleRemove}
          >
            删除选中
          </Button>
        </div>
      )}
      
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Checkbox
                  checked={selected.length === notifications.length && notifications.length > 0}
                  indeterminate={selected.length > 0 && selected.length < notifications.length}
                  onChange={handleSelectAll}
                />
              </TableCell>
              <TableCell>序号</TableCell>
              <TableCell>操作类型</TableCell>
              <TableCell>ICCID</TableCell>
              <TableCell>通知地址</TableCell>
              <TableCell>操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {notifications.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  暂无通知
                </TableCell>
              </TableRow>
            ) : (
              notifications.map((notif) => (
                <TableRow key={notif.seq}>
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={selected.includes(notif.seq)}
                      onChange={() => handleSelect(notif.seq)}
                    />
                  </TableCell>
                  <TableCell>{notif.seq}</TableCell>
                  <TableCell>
                    <Chip 
                      label={getOperationText(notif.profileManagementOperation)}
                      size="small"
                      color={notif.profileManagementOperation === 'delete' ? 'error' : 'default'}
                    />
                  </TableCell>
                  <TableCell>{notif.iccid || '-'}</TableCell>
                  <TableCell>{notif.notificationAddress || '-'}</TableCell>
                  <TableCell>
                    <IconButton 
                      size="small"
                      onClick={() => handleProcess(false)}
                    >
                      <CheckCircle />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </>
  )
}

