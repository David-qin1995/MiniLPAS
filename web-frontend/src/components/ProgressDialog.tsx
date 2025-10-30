import { Dialog, DialogTitle, DialogContent, LinearProgress, Typography, Box, IconButton } from '@mui/material'
import { Close } from '@mui/icons-material'
import { useAppStore } from '../store/useAppStore'

export interface ProgressInfo {
  message: string
  progress?: number // 0-100
  steps?: string[]
  currentStep?: number
  cancellable?: boolean
}

export default function ProgressDialog() {
  const progress = useAppStore((state) => state.progress)
  // const hideProgress = useAppStore((state) => state.hideProgress)
  const cancelProgress = useAppStore((state) => state.cancelProgress)

  if (!progress) return null

  const handleClose = () => {
    if (progress.cancellable) {
      cancelProgress?.()
    }
  }

  return (
    <Dialog
      open={!!progress}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 2,
        },
      }}
    >
      <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h6">操作进行中</Typography>
        {progress.cancellable && (
          <IconButton size="small" onClick={handleClose}>
            <Close />
          </IconButton>
        )}
      </DialogTitle>
      <DialogContent>
        <Box sx={{ py: 2 }}>
          <Typography variant="body1" sx={{ mb: 2 }}>
            {progress.message}
          </Typography>
          
          {progress.progress !== undefined && (
            <Box sx={{ mb: 2 }}>
              <LinearProgress
                variant={progress.progress >= 0 ? 'determinate' : 'indeterminate'}
                value={progress.progress}
                sx={{ height: 8, borderRadius: 4 }}
              />
              {progress.progress >= 0 && (
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block', textAlign: 'right' }}>
                  {Math.round(progress.progress)}%
                </Typography>
              )}
            </Box>
          )}

          {progress.steps && progress.steps.length > 0 && (
            <Box sx={{ mt: 2 }}>
              {progress.steps.map((step, index) => (
                <Box
                  key={index}
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    mb: 1,
                    opacity: progress.currentStep !== undefined && index < progress.currentStep ? 0.6 : 1,
                  }}
                >
                  <Typography
                    variant="body2"
                    sx={{
                      color:
                        progress.currentStep !== undefined && index === progress.currentStep
                          ? 'primary.main'
                          : 'text.secondary',
                      fontWeight:
                        progress.currentStep !== undefined && index === progress.currentStep ? 600 : 400,
                    }}
                  >
                    {step}
                  </Typography>
                </Box>
              ))}
            </Box>
          )}
        </Box>
      </DialogContent>
    </Dialog>
  )
}

