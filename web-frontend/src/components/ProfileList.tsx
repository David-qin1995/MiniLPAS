import { Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton, Chip } from '@mui/material'
import { Delete, PowerSettingsNew, PowerOff } from '@mui/icons-material'
import { useEffect, useState } from 'react'

export default function ProfileList() {
  const [profiles, setProfiles] = useState<any[]>([])

  useEffect(() => {
    fetchProfiles()
  }, [])

  const fetchProfiles = () => {
    fetch('http://localhost:8080/api/profiles')
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setProfiles(data.data || [])
        } else {
          console.error('获取配置文件列表失败:', data.error)
        }
      })
      .catch(err => {
        console.error('获取配置文件列表失败:', err)
      })
  }

  const handleEnable = (iccid: string) => {
    fetch(`http://localhost:8080/api/profiles/${iccid}/enable`, { method: 'POST' })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          fetchProfiles()
        } else {
          alert('启用失败: ' + (data.error || '未知错误'))
        }
      })
      .catch(err => {
        alert('启用失败: ' + err.message)
      })
  }

  const handleDisable = (iccid: string) => {
    fetch(`http://localhost:8080/api/profiles/${iccid}/disable`, { method: 'POST' })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          fetchProfiles()
        } else {
          alert('禁用失败: ' + (data.error || '未知错误'))
        }
      })
      .catch(err => {
        alert('禁用失败: ' + err.message)
      })
  }

  const handleDelete = (iccid: string) => {
    if (confirm('确定要删除这个配置文件吗？此操作不可恢复！')) {
      fetch(`http://localhost:8080/api/profiles/${iccid}`, { method: 'DELETE' })
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            fetchProfiles()
          } else {
            alert('删除失败: ' + (data.error || '未知错误'))
          }
        })
        .catch(err => {
          alert('删除失败: ' + err.message)
        })
    }
  }

  return (
    <>
      <Typography variant="h6" gutterBottom>
        配置文件列表
      </Typography>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ICCID</TableCell>
              <TableCell>状态</TableCell>
              <TableCell>服务提供商</TableCell>
              <TableCell>操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {profiles.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} align="center">
                  暂无配置文件
                </TableCell>
              </TableRow>
            ) : (
              profiles.map((profile) => (
                <TableRow key={profile.iccid}>
                  <TableCell>{profile.iccid}</TableCell>
                  <TableCell>
                    <Chip 
                      label={profile.state}
                      color={profile.state === 'enabled' ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{profile.serviceProviderName || '-'}</TableCell>
                  <TableCell>
                    {profile.state === 'enabled' ? (
                      <IconButton onClick={() => handleDisable(profile.iccid)}>
                        <PowerOff />
                      </IconButton>
                    ) : (
                      <IconButton onClick={() => handleEnable(profile.iccid)}>
                        <PowerSettingsNew />
                      </IconButton>
                    )}
                    <IconButton onClick={() => handleDelete(profile.iccid)}>
                      <Delete />
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

