import { 
  Typography, 
  Card, 
  CardContent, 
  CardActions, 
  IconButton, 
  Chip, 
  Box,
  Grid,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button
} from '@mui/material'
import { Delete, PowerSettingsNew, PowerOff, Edit } from '@mui/icons-material'
import { useEffect, useState, useMemo } from 'react'
import { useAppStore } from '../store/useAppStore'
import { profileApi } from '../utils/api'
import SearchBox, { SearchOptions } from './SearchBox'
import SkeletonLoader from './SkeletonLoader'

interface Profile {
  iccid: string
  state: 'enabled' | 'disabled'
  serviceProviderName?: string
  nickname?: string
  profileName?: string
}

export default function ProfileList() {
  const { profiles, setProfiles, updateProfile, setLoading, showToast } = useAppStore()
  const [searchQuery, setSearchQuery] = useState('')
  const [searchOptions, setSearchOptions] = useState<SearchOptions>({
    matchCase: false,
    wholeWords: false,
    regex: false,
  })
  const [editDialog, setEditDialog] = useState<{ open: boolean; profile: Profile | null; nickname: string }>({
    open: false,
    profile: null,
    nickname: '',
  })

  const refreshTick = useAppStore((state) => state.refresh.profiles)
  useEffect(() => {
    fetchProfiles()
  }, [refreshTick])

  const fetchProfiles = async () => {
    setLoading('profiles', true)
    try {
      const response = await profileApi.getProfiles()
      const data = response.data?.data || response.data || []
      setProfiles(data)
    } catch (error: any) {
      showToast(error.message || '获取配置文件列表失败', 'error')
    } finally {
      setLoading('profiles', false)
    }
  }

  // 搜索过滤
  const filteredProfiles = useMemo(() => {
    if (!searchQuery.trim()) return profiles

    const query = searchQuery.trim()
    
    return profiles.filter((profile) => {
      const searchText = [
        profile.iccid,
        profile.nickname || '',
        profile.serviceProviderName || '',
        profile.profileName || '',
      ].join(' ')

      if (searchOptions.regex) {
        try {
          const regex = new RegExp(query, searchOptions.matchCase ? '' : 'i')
          return regex.test(searchText)
        } catch {
          return false
        }
      }

      const text = searchOptions.matchCase ? searchText : searchText.toLowerCase()
      const q = searchOptions.matchCase ? query : query.toLowerCase()

      if (searchOptions.wholeWords) {
        const words = text.split(/\s+/)
        return words.some(word => word === q)
      }

      return text.includes(q)
    })
  }, [profiles, searchQuery, searchOptions])

  const handleEnable = async (iccid: string) => {
    try {
      await profileApi.enableProfile(iccid)
      updateProfile(iccid, { state: 'enabled' })
      showToast('配置文件已启用', 'success')
    } catch (error: any) {
      showToast(error.message || '启用失败', 'error')
    }
  }

  const handleDisable = async (iccid: string) => {
    try {
      await profileApi.disableProfile(iccid)
      updateProfile(iccid, { state: 'disabled' })
      showToast('配置文件已禁用', 'success')
    } catch (error: any) {
      showToast(error.message || '禁用失败', 'error')
    }
  }

  const handleDelete = async (iccid: string) => {
    if (!confirm('确定要删除这个配置文件吗？此操作不可恢复！')) return
    
    try {
      await profileApi.deleteProfile(iccid)
      setProfiles(profiles.filter(p => p.iccid !== iccid))
      showToast('配置文件已删除', 'success')
    } catch (error: any) {
      showToast(error.message || '删除失败', 'error')
    }
  }

  const handleEditNickname = (profile: Profile) => {
    setEditDialog({
      open: true,
      profile,
      nickname: profile.nickname || '',
    })
  }

  const handleSaveNickname = async () => {
    if (!editDialog.profile) return
    
    try {
      await profileApi.updateProfileNickname(editDialog.profile.iccid, editDialog.nickname)
      updateProfile(editDialog.profile.iccid, { nickname: editDialog.nickname })
      showToast('昵称已更新', 'success')
      setEditDialog({ open: false, profile: null, nickname: '' })
    } catch (error: any) {
      showToast(error.message || '更新失败', 'error')
    }
  }

  const loading = useAppStore((state) => state.loading['profiles'])

  return (
    <>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6">
          配置文件列表
        </Typography>
        <Chip 
          label={`共 ${filteredProfiles.length} 个`}
          size="small" 
          variant="outlined"
        />
      </Box>

      <SearchBox 
        onSearch={(query, options) => {
          setSearchQuery(query)
          setSearchOptions(options)
        }}
        placeholder="搜索 ICCID、昵称、服务提供商..."
      />

      {loading ? (
        <SkeletonLoader variant="profile" count={6} />
      ) : filteredProfiles.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 4, color: 'text.secondary' }}>
          <Typography variant="body2">
            {searchQuery ? '未找到匹配的配置文件' : '暂无配置文件'}
          </Typography>
        </Box>
      ) : (
        <Grid container spacing={2}>
          {filteredProfiles.map((profile) => (
            <Grid item xs={12} sm={6} md={4} key={profile.iccid}>
              <Card 
                elevation={profile.state === 'enabled' ? 3 : 1}
                sx={{ 
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  border: profile.state === 'enabled' ? '2px solid' : 'none',
                  borderColor: profile.state === 'enabled' ? 'primary.main' : 'transparent',
                }}
              >
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 1 }}>
                    <Chip 
                      label={profile.state === 'enabled' ? '已启用' : '已禁用'}
                      color={profile.state === 'enabled' ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                  
                  {profile.nickname && (
                    <Typography variant="h6" gutterBottom>
                      {profile.nickname}
                    </Typography>
                  )}
                  
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    <strong>ICCID:</strong> {profile.iccid}
                  </Typography>
                  
                  {profile.serviceProviderName && (
                    <Typography variant="body2" color="text.secondary">
                      <strong>服务商:</strong> {profile.serviceProviderName}
                    </Typography>
                  )}
                  
                  {profile.profileName && (
                    <Typography variant="body2" color="text.secondary">
                      <strong>配置名:</strong> {profile.profileName}
                    </Typography>
                  )}
                </CardContent>
                
                <CardActions sx={{ justifyContent: 'flex-end', pt: 0 }}>
                  <IconButton 
                    size="small" 
                    onClick={() => handleEditNickname(profile)}
                    title="编辑昵称"
                  >
                    <Edit fontSize="small" />
                  </IconButton>
                  
                  {profile.state === 'enabled' ? (
                    <IconButton 
                      size="small" 
                      onClick={() => handleDisable(profile.iccid)}
                      title="禁用"
                      color="warning"
                    >
                      <PowerOff fontSize="small" />
                    </IconButton>
                  ) : (
                    <IconButton 
                      size="small" 
                      onClick={() => handleEnable(profile.iccid)}
                      title="启用"
                      color="primary"
                    >
                      <PowerSettingsNew fontSize="small" />
                    </IconButton>
                  )}
                  
                  <IconButton 
                    size="small" 
                    onClick={() => handleDelete(profile.iccid)}
                    title="删除"
                    color="error"
                  >
                    <Delete fontSize="small" />
                  </IconButton>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* 编辑昵称对话框 */}
      <Dialog open={editDialog.open} onClose={() => setEditDialog({ open: false, profile: null, nickname: '' })}>
        <DialogTitle>编辑昵称</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="昵称"
            fullWidth
            variant="outlined"
            value={editDialog.nickname}
            onChange={(e) => setEditDialog({ ...editDialog, nickname: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialog({ open: false, profile: null, nickname: '' })}>
            取消
          </Button>
          <Button onClick={handleSaveNickname} variant="contained">
            保存
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
