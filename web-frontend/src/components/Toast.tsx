import { Snackbar, Alert, AlertColor } from '@mui/material'
import { useAppStore } from '../store/useAppStore'

export default function Toast() {
  const toast = useAppStore((state) => state.toast)
  const hideToast = useAppStore((state) => state.hideToast)

  return (
    <Snackbar
      open={!!toast}
      autoHideDuration={6000}
      onClose={hideToast}
      anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
    >
      {toast && (
        <Alert onClose={hideToast} severity={toast.severity as AlertColor} sx={{ width: '100%' }}>
          {toast.message}
        </Alert>
      )}
    </Snackbar>
  )
}



