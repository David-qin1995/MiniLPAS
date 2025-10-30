import { 
  Paper, 
  Typography, 
  TextField, 
  Button, 
  Box, 
  CircularProgress,
  Card,
  CardContent
} from '@mui/material'
import { useState, useCallback, DragEvent } from 'react'
import { Upload, CloudUpload } from '@mui/icons-material'
import { parseActivationCode, parseQRCodeFromImage } from '../utils/qrCodeParser'
import { profileApi } from '../utils/api'
import { useAppStore } from '../store/useAppStore'

export default function DownloadProfile() {
  const { setLoading, showToast } = useAppStore()
  const [smdp, setSmdp] = useState('')
  const [matchingId, setMatchingId] = useState('')
  const [confirmCode, setConfirmCode] = useState('')
  const [imei, setImei] = useState('')
  const [loading, setLocalLoading] = useState(false)
  const [dragActive, setDragActive] = useState(false)

  const handleDownload = async () => {
    if (!smdp || !matchingId) {
      showToast('SMDP和MatchingID是必填项', 'error')
      return
    }

    setLocalLoading(true)
    setLoading('download', true)
    
    try {
      await profileApi.downloadProfile({
        smdp,
        matchingId,
        confirmCode: confirmCode || undefined,
        imei: imei || undefined,
      })
      
      showToast('下载已启动', 'success')
      // 清空表单
      setSmdp('')
      setMatchingId('')
      setConfirmCode('')
      setImei('')
    } catch (error: any) {
      showToast(error.message || '下载失败', 'error')
    } finally {
      setLocalLoading(false)
      setLoading('download', false)
    }
  }

  const handleFileUpload = async (file: File) => {
    if (file.type.startsWith('image/')) {
      // 图片文件，尝试解析QR码
      const reader = new FileReader()
      reader.onload = async (e) => {
        const dataUrl = e.target?.result as string
        try {
          const result = await parseQRCodeFromImage(dataUrl)
          if (result) {
            setSmdp(result.smdp)
            setMatchingId(result.matchingId)
            if (result.reqConCode) {
              setConfirmCode('')
              showToast('QR码解析成功，请输入确认码', 'success')
            } else {
              showToast('QR码解析成功', 'success')
            }
          } else {
            showToast('无法从图片中解析QR码', 'error')
          }
        } catch (error) {
          showToast('QR码解析失败', 'error')
        }
      }
      reader.readAsDataURL(file)
    } else {
      // 文本文件
      const reader = new FileReader()
      reader.onload = (e) => {
        const text = e.target?.result as string
        handleParseActivationCode(text)
      }
      reader.readAsText(file)
    }
  }

  const handleParseActivationCode = (text: string) => {
    const parsed = parseActivationCode(text)
    if (parsed) {
      setSmdp(parsed.smdp)
      setMatchingId(parsed.matchingId)
      if (parsed.reqConCode) {
        setConfirmCode('')
        showToast('激活码解析成功，请输入确认码', 'success')
      } else {
        showToast('激活码解析成功', 'success')
      }
    } else {
      showToast('无法解析激活码格式', 'error')
    }
  }

  const handleDrag = useCallback((e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true)
    } else if (e.type === 'dragleave') {
      setDragActive(false)
    }
  }, [])

  const handleDrop = useCallback((e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0])
    }
  }, [])

  const handlePaste = (event: React.ClipboardEvent<HTMLInputElement>) => {
    const text = event.clipboardData.getData('text')
    if (text && text.startsWith('LPA:')) {
      handleParseActivationCode(text)
      event.preventDefault()
    }
  }

  return (
    <Paper elevation={0}>
      <Typography variant="h6" gutterBottom>
        下载配置文件
      </Typography>

      {/* 拖拽上传区域 */}
      <Card 
        elevation={0}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        sx={{
          mb: 3,
          border: '2px dashed',
          borderColor: dragActive ? 'primary.main' : 'divider',
          backgroundColor: dragActive ? 'action.hover' : 'background.paper',
          transition: 'all 0.2s ease',
          cursor: 'pointer',
        }}
      >
        <CardContent sx={{ textAlign: 'center', py: 4 }}>
          <CloudUpload sx={{ fontSize: 48, color: 'primary.main', mb: 2 }} />
          <Typography variant="h6" gutterBottom>
            拖拽文件到此处或点击上传
          </Typography>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            支持 QR 码图片、激活码文本文件
          </Typography>
          <Button
            variant="outlined"
            component="label"
            startIcon={<Upload />}
            sx={{ mt: 2 }}
          >
            选择文件
            <input
              type="file"
              hidden
              accept="image/*,.txt"
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file) handleFileUpload(file)
              }}
            />
          </Button>
        </CardContent>
      </Card>

      {/* 表单 */}
      <Box component="form" sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          label="SMDP地址"
          value={smdp}
          onChange={(e) => setSmdp(e.target.value)}
          fullWidth
          required
          placeholder="例如: https://smdp.example.com"
          onPaste={handlePaste}
        />
        
        <TextField
          label="Matching ID"
          value={matchingId}
          onChange={(e) => setMatchingId(e.target.value)}
          fullWidth
          required
          onPaste={handlePaste}
        />
        
        <TextField
          label="确认码 (可选)"
          value={confirmCode}
          onChange={(e) => setConfirmCode(e.target.value)}
          fullWidth
        />
        
        <TextField
          label="IMEI (可选)"
          value={imei}
          onChange={(e) => setImei(e.target.value)}
          fullWidth
        />

        <Button
          variant="contained"
          onClick={handleDownload}
          disabled={loading || !smdp || !matchingId}
          size="large"
          startIcon={loading ? <CircularProgress size={20} /> : undefined}
          sx={{ mt: 2 }}
        >
          {loading ? '下载中...' : '开始下载'}
        </Button>
      </Box>
    </Paper>
  )
}
