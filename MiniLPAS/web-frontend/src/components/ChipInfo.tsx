import { Typography, Grid, Card, CardContent } from '@mui/material'
import { useEffect, useState } from 'react'

export default function ChipInfo() {
  const [chipInfo, setChipInfo] = useState<any>(null)

  useEffect(() => {
    const fetchChipInfo = () => {
      fetch('http://localhost:8080/api/chip/info')
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            setChipInfo(data.data)
          } else {
            console.error('获取芯片信息失败:', data.error)
          }
        })
        .catch(err => {
          console.error('获取芯片信息失败:', err)
        })
    }
    
    fetchChipInfo()
    // 每5秒刷新一次
    const interval = setInterval(fetchChipInfo, 5000)
    return () => clearInterval(interval)
  }, [])

  if (!chipInfo) {
    return <Typography>加载中...</Typography>
  }

  return (
    <>
      <Typography variant="h6" gutterBottom>
        芯片信息
      </Typography>
      <Grid container spacing={2}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">
                EID
              </Typography>
              <Typography variant="body1">
                {chipInfo.eid || '未知'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">
                ICCID
              </Typography>
              <Typography variant="body1">
                {chipInfo.iccid || '未知'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </>
  )
}

