import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api'

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// 响应拦截器 - 统一错误处理
api.interceptors.response.use(
  (response) => {
    // 如果后端返回的是 { success: true, data: ... } 格式
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      if (!response.data.success) {
        return Promise.reject(new Error(response.data.error || '请求失败'))
      }
    }
    return response
  },
  (error) => {
    // 统一错误处理
    const message = error.response?.data?.error || error.message || '网络错误'
    return Promise.reject(new Error(message))
  }
)

// API 方法
export const deviceApi = {
  getStatus: () => api.get('/devices/status'),
  getDevices: () => api.get('/devices'),
  getDevice: (id: string) => api.get(`/devices/${id}`),
}

export const chipApi = {
  getChipInfo: () => api.get('/chip'),
  getChipInfoById: (id: string) => api.get(`/chip/${id}`),
}

export const profileApi = {
  getProfiles: () => api.get('/profiles'),
  downloadProfile: (data: {
    smdp: string
    matchingId: string
    confirmCode?: string
    imei?: string
  }) => api.post('/profiles/download', data),
  enableProfile: (iccid: string) => api.post(`/profiles/${iccid}/enable`),
  disableProfile: (iccid: string) => api.post(`/profiles/${iccid}/disable`),
  deleteProfile: (iccid: string) => api.delete(`/profiles/${iccid}`),
  updateProfileNickname: (iccid: string, nickname: string) =>
    api.patch(`/profiles/${iccid}/nickname`, { nickname }),
}

export const notificationApi = {
  getNotifications: () => api.get('/notifications'),
  processNotification: (id: string, action: string) =>
    api.post(`/notifications/${id}/process`, { action }),
  deleteNotification: (id: string) => api.delete(`/notifications/${id}`),
}



