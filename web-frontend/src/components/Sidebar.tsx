import { useMemo } from 'react'
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Tooltip,
  Box,
  Divider,
  Typography,
} from '@mui/material'
import {
  List as ListIcon,
  Download,
  Notifications,
  Settings,
  Memory,
} from '@mui/icons-material'
import { useNavigate, useLocation } from 'react-router-dom'

const DRAWER_WIDTH = 240

interface NavItem {
  id: string
  label: string
  icon: React.ReactNode
  path: string
}

const navItems: NavItem[] = [
  { id: 'profiles', label: '配置文件', icon: <ListIcon />, path: '/' },
  { id: 'download', label: '下载配置', icon: <Download />, path: '/download' },
  { id: 'notifications', label: '通知管理', icon: <Notifications />, path: '/notifications' },
  { id: 'chip', label: '芯片信息', icon: <Memory />, path: '/chip' },
  { id: 'settings', label: '设置', icon: <Settings />, path: '/settings' },
]

export default function Sidebar() {
  const navigate = useNavigate()
  const location = useLocation()

  const activePath = useMemo(() => {
    return location.pathname
  }, [location.pathname])

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: DRAWER_WIDTH,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: DRAWER_WIDTH,
          boxSizing: 'border-box',
          borderRight: '1px solid',
          borderColor: 'divider',
        },
      }}
    >
      <Box sx={{ p: 2 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          MiniLPA
        </Typography>
      </Box>
      <Divider />
      <List sx={{ pt: 1 }}>
        {navItems.map((item) => (
          <ListItem key={item.id} disablePadding>
            <ListItemButton
              selected={activePath === item.path}
              onClick={() => navigate(item.path)}
              sx={{
                '&.Mui-selected': {
                  backgroundColor: 'primary.main',
                  color: 'primary.contrastText',
                  '&:hover': {
                    backgroundColor: 'primary.dark',
                  },
                  '& .MuiListItemIcon-root': {
                    color: 'primary.contrastText',
                  },
                },
              }}
            >
              <ListItemIcon
                sx={{
                  color: activePath === item.path ? 'inherit' : 'action',
                  minWidth: 40,
                }}
              >
                {item.icon}
              </ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Drawer>
  )
}

export { DRAWER_WIDTH }

