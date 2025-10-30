import { Paper, Typography, TextField, Button, Box, Alert } from '@mui/material'
import { useState } from 'react'
import { Upload } from '@mui/icons-material'
import { parseActivationCode, parseQRCodeFromImage } from '../utils/qrCodeParser'

export default function DownloadProfile() {
  const [smdp, setSmdp] = useState('')
  const [matchingId, setMatchingId] = useState('')
  const [confirmCode, setConfirmCode] = useState('')
  const [imei, setImei] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null)

  const handleDownload = () => {
    if (!smdp || !matchingId) {
      setMessage({ type: 'error', text: 'SMDP和MatchingID是必填项' })
      return
    }

    setLoading(true)
    setMessage(null)

    fetch('http://localhost:8080/api/profiles/download', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        smdp,
        matchingId,
        confirmCode: confirmCode || null,
        imei: imei || null
      })
    })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setMessage({ type: 'success', text: data.message || '下载已启动' })
          // 清空表单
          setSmdp('')
          setMatchingId('')
          setConfirmCode('')
          setImei('')
        } else {
          setMessage({ type: 'error', text: data.error || '下载失败' })
        }
      })
      .catch(err => {
        setMessage({ type: 'error', text: '下载失败: ' + err.message })
      })
      .finally(() => {
        setLoading(false)
      })
  }

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // 如果是图片，尝试解析QR码
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = async (e) => {
        const dataUrl = e.target?.result as string
        const result = await parseQRCodeFromImage(dataUrl)
        if (result) {
          setSmdp(result.smdp)
          setMatchingId(result.matchingId)
          if (result.reqConCode) {
            // 需要确认码，清空并提示用户输入
            setConfirmCode('')
            setMessage({ type: 'success', text: 'QR码解析成功，请输入确认码' })
          } else {
            setMessage({ type: 'success', text: 'QR码解析成功' })
          }
        } else {
          setMessage({ type: 'error', text: '无法从图片中解析QR码，请确保图片包含有效的激活码QR码' })
        }
      }
      reader.readAsDataURL(file)
    } else {
      // 文本文件，读取内容
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
        setMessage({ type: 'success', text: '激活码解析成功，请输入确认码' })
      } else {
        setConfirmCode('')
        setMessage({ type: 'success', text: '激活码解析成功' })
      }
    } else {
      setMessage({ type: 'error', text: '无法解析激活码格式，请确保格式为 LPA:1$...$...' })
    }
  }

  const handlePaste = (event: React.ClipboardEvent<HTMLInputElement>) => {
    const text = event.clipboardData.getData('text')
    if (text && text.startsWith('LPA:')) {
      handleParseActivationCode(text)
      event.preventDefault()
    }
  }

  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h6" gutterBottom>
        下载配置文件
      </Typography>

      {message && (
        <Alert severity={message.type} sx={{ mb: 2 }} onClose={() => setMessage(null)}>
          {message.text}
        </Alert>
      )}

      <Box component="form" sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          label="SMDP地址"
          value={smdp}
          onChange={(e) => setSmdp(e.target.value)}
          fullWidth
          required
          placeholder="例如: https://smdp.example.com"
        />
        
        <TextField
          label="Matching ID"
          value={matchingId}
          onChange={(e) => setMatchingId(e.target.value)}
          fullWidth
          required
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

        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="outlined"
            component="label"
            startIcon={<Upload />}
          >
            上传QR码/激活码文件
            <input
              type="file"
              hidden
              accept="image/*,.txt"
              onChange={handleFileUpload}
            />
          </Button>
          
          <Box 
            sx={{ 
              flex: 1, 
              border: '1px dashed #ccc', 
              borderRadius: 1, 
              p: 2, 
              textAlign: 'center',
              cursor: 'pointer'
            }}
            onPaste={handlePaste}
          >
            <Typography variant="body2" color="text.secondary">
              或在此区域粘贴激活码 (Ctrl+V)
            </Typography>
          </Box>
        </Box>

        <Button
          variant="contained"
          onClick={handleDownload}
          disabled={loading || !smdp || !matchingId}
          size="large"
        >
          {loading ? '下载中...' : '开始下载'}
        </Button>
      </Box>
    </Paper>
  )
}

