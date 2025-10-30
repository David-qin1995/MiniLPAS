import { useEffect, useState, useMemo } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  TextField,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Box,
  Typography,
  Chip,
  InputAdornment,
} from '@mui/material'
import { Search, Settings, List as ListIcon, Notifications, Download, Memory } from '@mui/icons-material'

interface Command {
  id: string
  label: string
  keywords: string[]
  icon: React.ReactNode
  action: () => void
  category: string
}

export default function CommandPalette() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')

  const commands: Command[] = useMemo(
    () => [
      {
        id: 'profiles',
        label: '配置文件管理',
        keywords: ['profile', 'config', '配置', '文件'],
        icon: <ListIcon />,
        action: () => {
          window.location.hash = '#/profiles'
          setOpen(false)
        },
        category: '导航',
      },
      {
        id: 'download',
        label: '下载配置文件',
        keywords: ['download', '下载', '配置'],
        icon: <Download />,
        action: () => {
          window.location.hash = '#/download'
          setOpen(false)
        },
        category: '导航',
      },
      {
        id: 'notifications',
        label: '通知管理',
        keywords: ['notification', '通知', '消息'],
        icon: <Notifications />,
        action: () => {
          window.location.hash = '#/notifications'
          setOpen(false)
        },
        category: '导航',
      },
      {
        id: 'chip',
        label: '芯片信息',
        keywords: ['chip', '芯片', '设备'],
        icon: <Memory />,
        action: () => {
          window.location.hash = '#/chip'
          setOpen(false)
        },
        category: '导航',
      },
      {
        id: 'settings',
        label: '设置',
        keywords: ['settings', '设置', '偏好'],
        icon: <Settings />,
        action: () => {
          window.location.hash = '#/settings'
          setOpen(false)
        },
        category: '导航',
      },
    ],
    []
  )

  const filteredCommands = useMemo(() => {
    if (!query.trim()) return commands
    const q = query.toLowerCase()
    return commands.filter(
      (cmd) =>
        cmd.label.toLowerCase().includes(q) ||
        cmd.keywords.some((kw) => kw.toLowerCase().includes(q)) ||
        cmd.category.toLowerCase().includes(q)
    )
  }, [query, commands])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setOpen(true)
      }
      if (e.key === 'Escape' && open) {
        setOpen(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [open])

  const handleSelect = (command: Command) => {
    command.action()
    setQuery('')
  }

  return (
    <Dialog
      open={open}
      onClose={() => setOpen(false)}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 2,
          maxHeight: '80vh',
        },
      }}
    >
      <DialogTitle>
        <TextField
          fullWidth
          placeholder="搜索命令、页面或设置..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search />
              </InputAdornment>
            ),
            endAdornment: (
              <InputAdornment position="end">
                <Chip label="ESC" size="small" variant="outlined" />
              </InputAdornment>
            ),
          }}
          variant="outlined"
        />
      </DialogTitle>
      <DialogContent dividers sx={{ p: 0 }}>
        {filteredCommands.length === 0 ? (
          <Box sx={{ p: 3, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              未找到匹配的命令
            </Typography>
          </Box>
        ) : (
          <List sx={{ py: 0 }}>
            {filteredCommands.map((cmd, index) => (
              <ListItem key={cmd.id} disablePadding>
                <ListItemButton onClick={() => handleSelect(cmd)} selected={index === 0}>
                  <ListItemIcon>{cmd.icon}</ListItemIcon>
                  <ListItemText
                    primary={cmd.label}
                    secondary={cmd.category}
                  />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        )}
      </DialogContent>
    </Dialog>
  )
}

