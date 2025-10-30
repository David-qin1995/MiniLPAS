import { useState } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Switch,
  FormControlLabel,
  List,
  ListItem,
  Divider,
  Button,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Grid,
} from '@mui/material'
import { useThemeContext } from '../contexts/ThemeContext'
import { useAppStore } from '../store/useAppStore'

export default function Settings() {
  const { toggleTheme, theme } = useThemeContext()
  const { showToast } = useAppStore()
  const [language, setLanguage] = useState('zh-CN')

  const handleReset = () => {
    if (confirm('确定要重置所有设置吗？')) {
      localStorage.clear()
      showToast('设置已重置', 'success')
      window.location.reload()
    }
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3 }}>
        设置
      </Typography>

      <Grid container spacing={3}>
        {/* 外观设置 */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                外观
              </Typography>
              <List>
                <ListItem>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={theme === 'dark'}
                        onChange={toggleTheme}
                      />
                    }
                    label="深色主题"
                  />
                </ListItem>
                <Divider />
                <ListItem>
                  <FormControl fullWidth>
                    <InputLabel>语言</InputLabel>
                    <Select
                      value={language}
                      label="语言"
                      onChange={(e) => setLanguage(e.target.value)}
                    >
                      <MenuItem value="zh-CN">简体中文</MenuItem>
                      <MenuItem value="en-US">English</MenuItem>
                    </Select>
                  </FormControl>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* 其他设置 */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                其他
              </Typography>
              <List>
                <ListItem>
                  <Button variant="outlined" color="warning" onClick={handleReset}>
                    重置所有设置
                  </Button>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}
