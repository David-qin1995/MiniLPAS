import { useState } from 'react'
import { Container, AppBar, Toolbar, Typography, Box, Paper, Tabs, Tab } from '@mui/material'
import DeviceStatus from './components/DeviceStatus'
import ChipInfo from './components/ChipInfo'
import ProfileList from './components/ProfileList'
import DownloadProfile from './components/DownloadProfile'
import NotificationList from './components/NotificationList'

function App() {
  const [connected, setConnected] = useState(false)
  const [tabValue, setTabValue] = useState(0)

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            MiniLPA Web
          </Typography>
        </Toolbar>
      </AppBar>
      
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <DeviceStatus 
          connected={connected} 
          onConnectionChange={setConnected} 
        />
        
        {connected && (
          <>
            <Paper sx={{ p: 2, mt: 2 }}>
              <ChipInfo />
            </Paper>
            
            <Paper sx={{ mt: 2 }}>
              <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
                <Tab label="配置文件" />
                <Tab label="下载配置" />
                <Tab label="通知管理" />
              </Tabs>
              
              <Box sx={{ p: 2 }}>
                {tabValue === 0 && <ProfileList />}
                {tabValue === 1 && <DownloadProfile />}
                {tabValue === 2 && <NotificationList />}
              </Box>
            </Paper>
          </>
        )}
      </Container>
    </Box>
  )
}

export default App

