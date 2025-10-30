import { TextField, IconButton, Tooltip, ToggleButton, ToggleButtonGroup, Box } from '@mui/material'
import { Search, Clear, TextFields, Title, Code } from '@mui/icons-material'
import { useState, useEffect } from 'react'

interface SearchBoxProps {
  onSearch: (query: string, options: SearchOptions) => void
  placeholder?: string
}

export interface SearchOptions {
  matchCase: boolean
  wholeWords: boolean
  regex: boolean
}

export default function SearchBox({ onSearch, placeholder = '搜索...' }: SearchBoxProps) {
  const [query, setQuery] = useState('')
  const [options, setOptions] = useState<SearchOptions>({
    matchCase: false,
    wholeWords: false,
    regex: false,
  })

  useEffect(() => {
    onSearch(query, options)
  }, [query, options, onSearch])

  const handleOptionChange = (
    _event: React.MouseEvent<HTMLElement>,
    newOptions: string[]
  ) => {
    setOptions({
      matchCase: newOptions.includes('matchCase'),
      wholeWords: newOptions.includes('wholeWords'),
      regex: newOptions.includes('regex'),
    })
  }

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
      <TextField
        fullWidth
        size="small"
        placeholder={placeholder}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        InputProps={{
          startAdornment: <Search sx={{ color: 'text.secondary', mr: 1 }} />,
          endAdornment: query ? (
            <IconButton size="small" onClick={() => setQuery('')}>
              <Clear />
            </IconButton>
          ) : null,
        }}
      />
      <ToggleButtonGroup
        value={[
          ...(options.matchCase ? ['matchCase'] : []),
          ...(options.wholeWords ? ['wholeWords'] : []),
          ...(options.regex ? ['regex'] : []),
        ]}
        onChange={handleOptionChange}
        size="small"
      >
        <Tooltip title="区分大小写">
          <ToggleButton value="matchCase">
            <TextFields fontSize="small" />
          </ToggleButton>
        </Tooltip>
        <Tooltip title="整词匹配">
          <ToggleButton value="wholeWords">
            <Title fontSize="small" />
          </ToggleButton>
        </Tooltip>
        <Tooltip title="正则表达式">
          <ToggleButton value="regex">
            <Code fontSize="small" />
          </ToggleButton>
        </Tooltip>
      </ToggleButtonGroup>
    </Box>
  )
}

