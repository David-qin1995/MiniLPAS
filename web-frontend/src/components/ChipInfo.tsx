import { Typography, Grid, Card, CardContent, Box, CircularProgress, Chip } from '@mui/material'
import { useEffect, useState } from 'react'
import { chipApi } from '../utils/api'
import { useAppStore } from '../store/useAppStore'

export default function ChipInfo() {
  const { setLoading } = useAppStore()
  const [chipInfo, setChipInfo] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchChipInfo()
    // 每10秒刷新一次
    const interval = setInterval(fetchChipInfo, 10000)
    return () => clearInterval(interval)
  }, [])

  const fetchChipInfo = async () => {
    setLoading('chipInfo', true)
    setError(null)
    try {
      const response = await chipApi.getChipInfo()
      const data = response.data?.data || response.data
      setChipInfo(data)
      setError(null)
    } catch (error: any) {
      const errorMsg = error.message || '获取芯片信息失败'
      // 检查是否是硬件相关的错误
      if (errorMsg.includes('LPAC') || errorMsg.includes('读卡器') || errorMsg.includes('PCSC')) {
        setError('dev_mode') // 开发模式标记
      } else {
        setError(errorMsg)
      }
      console.error('获取芯片信息失败:', error)
    } finally {
      setLoading('chipInfo', false)
    }
  }

  const loading = useAppStore((state) => state.loading['chipInfo'])

  if (loading && !chipInfo) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
        <CircularProgress size={24} />
      </Box>
    )
  }

  if (!chipInfo && !error) {
    return null
  }

  // 显示开发模式提示
  if (error === 'dev_mode') {
    return (
      <Box>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            芯片信息
          </Typography>
        </Box>
        <Card elevation={2}>
          <CardContent>
            <Box sx={{ textAlign: 'center', py: 2 }}>
              <Chip 
                label="开发模式" 
                color="info" 
                variant="outlined" 
                sx={{ mb: 1 }}
              />
              <Typography variant="body2" color="text.secondary">
                本地开发环境未检测到智能卡读卡器
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                在生产环境连接读卡器后即可正常使用
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box>
    )
  }

  if (error) {
    return (
      <Box>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            芯片信息
          </Typography>
        </Box>
        <Card elevation={2}>
          <CardContent>
            <Box sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="body2" color="error">
                {error}
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box>
    )
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6">
          芯片信息
        </Typography>
      </Box>
      <Grid container spacing={2}>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                EID
              </Typography>
              <Typography variant="body1" sx={{ wordBreak: 'break-all' }}>
                {chipInfo.eid || '未知'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                ICCID
              </Typography>
              <Typography variant="body1" sx={{ wordBreak: 'break-all' }}>
                {chipInfo.iccid || '未知'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        {chipInfo.profileMetadata && (
          <Grid item xs={12} sm={6} md={3}>
            <Card elevation={2}>
              <CardContent>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  配置文件数量
                </Typography>
                <Typography variant="h5">
                  {chipInfo.profileMetadata?.length || 0}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        )}
      </Grid>
    </Box>
  )
}
