import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import { ProgressInfo } from '../components/ProgressDialog'

interface Device {
  id: string
  name: string
  connected: boolean
}

interface Profile {
  iccid: string
  state: 'enabled' | 'disabled'
  serviceProviderName?: string
  nickname?: string
  profileName?: string
}

interface Notification {
  id: string
  type: string
  message: string
  timestamp: number
}

interface AppState {
  // 主题
  theme: 'light' | 'dark'
  setTheme: (theme: 'light' | 'dark') => void
  
  // 连接状态
  connected: boolean
  setConnected: (connected: boolean) => void
  
  // 设备信息
  devices: Device[]
  currentDevice: Device | null
  setDevices: (devices: Device[]) => void
  setCurrentDevice: (device: Device | null) => void
  
  // 配置文件
  profiles: Profile[]
  setProfiles: (profiles: Profile[]) => void
  updateProfile: (iccid: string, updates: Partial<Profile>) => void
  
  // 通知
  notifications: Notification[]
  setNotifications: (notifications: Notification[]) => void
  addNotification: (notification: Notification) => void
  removeNotification: (id: string) => void
  
  // 加载状态
  loading: Record<string, boolean>
  setLoading: (key: string, loading: boolean) => void
  
  // 列表刷新信号（版本号累加触发 useEffect）
  refresh: { profiles: number; notifications: number }
  triggerProfilesRefresh: () => void
  triggerNotificationsRefresh: () => void
  
  // Toast 通知
  toast: { message: string; severity: 'success' | 'error' | 'info' | 'warning' } | null
  showToast: (message: string, severity?: 'success' | 'error' | 'info' | 'warning') => void
  hideToast: () => void
  
  // 进度对话框
  progress: ProgressInfo | null
  showProgress: (progress: ProgressInfo) => void
  updateProgress: (updates: Partial<ProgressInfo>) => void
  hideProgress: () => void
  cancelProgress?: () => void
  setCancelProgress: (cancelFn?: () => void) => void
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      // 主题（持久化到 localStorage）
      theme: 'light',
      setTheme: (theme) => set({ theme }),
      
      // 连接状态
      connected: false,
      setConnected: (connected) => set({ connected }),
      
      // 设备信息
      devices: [],
      currentDevice: null,
      setDevices: (devices) => set({ devices }),
      setCurrentDevice: (device) => set({ currentDevice: device }),
      
      // 配置文件
      profiles: [],
      setProfiles: (profiles) => set({ profiles }),
      updateProfile: (iccid, updates) =>
        set((state) => ({
          profiles: state.profiles.map((p) =>
            p.iccid === iccid ? { ...p, ...updates } : p
          ),
        })),
      
      // 通知
      notifications: [],
      setNotifications: (notifications) => set({ notifications }),
      addNotification: (notification) =>
        set((state) => ({
          notifications: [...state.notifications, notification],
        })),
      removeNotification: (id) =>
        set((state) => ({
          notifications: state.notifications.filter((n) => n.id !== id),
        })),
      
      // 加载状态
      loading: {},
      setLoading: (key, loading) =>
        set((state) => ({
          loading: { ...state.loading, [key]: loading },
        })),

      // 刷新信号
      refresh: { profiles: 0, notifications: 0 },
      triggerProfilesRefresh: () =>
        set((state) => ({ refresh: { ...state.refresh, profiles: state.refresh.profiles + 1 } })),
      triggerNotificationsRefresh: () =>
        set((state) => ({ refresh: { ...state.refresh, notifications: state.refresh.notifications + 1 } })),
      
      // Toast 通知
      toast: null,
      showToast: (message, severity = 'info') =>
        set({ toast: { message, severity } }),
      hideToast: () => set({ toast: null }),
      
      // 进度对话框
      progress: null,
      showProgress: (progress) => set({ progress }),
      updateProgress: (updates) =>
        set((state) => ({
          progress: state.progress ? { ...state.progress, ...updates } : null,
        })),
      hideProgress: () => set({ progress: null }),
      cancelProgress: undefined,
      setCancelProgress: (cancelFn) => set({ cancelProgress: cancelFn }),
    }),
    {
      name: 'minilpa-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ theme: state.theme }), // 只持久化主题
    }
  )
)



