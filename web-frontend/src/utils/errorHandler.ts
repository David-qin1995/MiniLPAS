import { AxiosError } from 'axios'
import { useAppStore } from '../store/useAppStore'

export interface ApiError {
  message: string
  code?: string
  status?: number
  retryable?: boolean
}

export function handleApiError(error: unknown): ApiError {
  if (error instanceof AxiosError) {
    const status = error.response?.status
    const message = error.response?.data?.message || error.response?.data?.error || error.message || '请求失败'
    
    // 根据HTTP状态码判断是否可重试
    const retryable = status && (status === 408 || status === 429 || status >= 500)
    
    return {
      message,
      code: error.code,
      status,
      retryable,
    }
  }
  
  if (error instanceof Error) {
    return {
      message: error.message,
      retryable: false,
    }
  }
  
  return {
    message: '未知错误',
    retryable: false,
  }
}

export async function retryRequest<T>(
  requestFn: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> {
  let lastError: unknown
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await requestFn()
    } catch (error) {
      lastError = error
      const apiError = handleApiError(error)
      
      // 如果不可重试或已达到最大重试次数，直接抛出
      if (!apiError.retryable || attempt === maxRetries) {
        throw error
      }
      
      // 指数退避
      const waitTime = delay * Math.pow(2, attempt)
      await new Promise(resolve => setTimeout(resolve, waitTime))
    }
  }
  
  throw lastError
}

