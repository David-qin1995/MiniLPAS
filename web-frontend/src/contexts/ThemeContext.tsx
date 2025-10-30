import React, { createContext, useContext, ReactNode } from 'react'
import { ThemeProvider as MuiThemeProvider, createTheme, CssBaseline } from '@mui/material'
import { useAppStore } from '../store/useAppStore'

const ThemeContext = createContext<{ toggleTheme: () => void }>({
  toggleTheme: () => {},
})

export const useThemeContext = () => useContext(ThemeContext)

export function ThemeProvider({ children }: { children: ReactNode }) {
  const theme = useAppStore((state) => state.theme)
  const setTheme = useAppStore((state) => state.setTheme)

  // 检测系统主题
  React.useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = (e: MediaQueryListEvent) => {
      // 仅在用户未手动设置主题时跟随系统
      const stored = localStorage.getItem('minilpa-storage')
      if (!stored || !JSON.parse(stored)?.state?.theme) {
        setTheme(e.matches ? 'dark' : 'light')
      }
    }

    // 初始检查
    if (!localStorage.getItem('minilpa-storage')) {
      setTheme(mediaQuery.matches ? 'dark' : 'light')
    }

    mediaQuery.addEventListener('change', handleChange)
    return () => mediaQuery.removeEventListener('change', handleChange)
  }, [setTheme])

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light')
  }

  const muiTheme = createTheme({
    palette: {
      mode: theme,
      primary: {
        main: '#1976d2',
      },
      secondary: {
        main: '#dc004e',
      },
    },
    components: {
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: 12,
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: 8,
            textTransform: 'none',
          },
        },
      },
    },
  })

  return (
    <ThemeContext.Provider value={{ toggleTheme }}>
      <MuiThemeProvider theme={muiTheme}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  )
}

