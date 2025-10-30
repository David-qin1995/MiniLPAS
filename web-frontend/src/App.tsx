import { Suspense, lazy } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Box, AppBar, Toolbar, Typography, IconButton, Tooltip } from '@mui/material'
import { Brightness4, Brightness7 } from '@mui/icons-material'
import Sidebar, { DRAWER_WIDTH } from './components/Sidebar'
import Toast from './components/Toast'
import ProgressDialog from './components/ProgressDialog'
import CommandPalette from './components/CommandPalette'
import SkeletonLoader from './components/SkeletonLoader'
import { useThemeContext } from './contexts/ThemeContext'
import { useAppStore } from './store/useAppStore'
import { useServerEvents } from './hooks/useServerEvents'
import SystemStatus from './components/SystemStatus'

// 路由级代码分割
const Profiles = lazy(() => import('./pages/Profiles'))
const Download = lazy(() => import('./pages/Download'))
const Notifications = lazy(() => import('./pages/Notifications'))
const Chip = lazy(() => import('./pages/Chip'))
const Settings = lazy(() => import('./pages/Settings'))

function LoadingFallback() {
  return (
    <Box sx={{ p: 3 }}>
      <SkeletonLoader variant="card" count={3} />
    </Box>
  )
}

function AppContent() {
  const { toggleTheme } = useThemeContext()
  const theme = useAppStore((state) => state.theme)
  useServerEvents()

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      <Sidebar />
      
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { sm: `${DRAWER_WIDTH}px` },
          bgcolor: 'background.default',
        }}
      >
        <AppBar
          position="fixed"
          elevation={0}
          sx={{
            width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
            ml: { sm: `${DRAWER_WIDTH}px` },
            bgcolor: 'background.paper',
            borderBottom: '1px solid',
            borderColor: 'divider',
          }}
        >
          <Toolbar>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1, fontWeight: 600 }}>
              MiniLPA Web
            </Typography>
            <SystemStatus />
            <Tooltip title="切换主题 (Ctrl+K 打开命令面板)">
              <IconButton color="inherit" onClick={toggleTheme} sx={{ mr: 1 }}>
                {theme === 'light' ? <Brightness4 /> : <Brightness7 />}
              </IconButton>
            </Tooltip>
          </Toolbar>
        </AppBar>

        <Box sx={{ mt: { xs: 7, sm: 8 }, p: 3 }}>
          <Suspense fallback={<LoadingFallback />}>
            <Routes>
              <Route path="/" element={<Profiles />} />
              <Route path="/profiles" element={<Navigate to="/" replace />} />
              <Route path="/download" element={<Download />} />
              <Route path="/notifications" element={<Notifications />} />
              <Route path="/chip" element={<Chip />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Suspense>
        </Box>
      </Box>

      <Toast />
      <ProgressDialog />
      <CommandPalette />
    </Box>
  )
}

function App() {
  return (
    <BrowserRouter>
      <AppContent />
    </BrowserRouter>
  )
}

export default App
