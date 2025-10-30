import { Box, Skeleton, Card, CardContent, Grid } from '@mui/material'

interface SkeletonLoaderProps {
  variant?: 'profile' | 'card' | 'list' | 'table'
  count?: number
}

export default function SkeletonLoader({ variant = 'card', count = 3 }: SkeletonLoaderProps) {
  if (variant === 'profile') {
    return (
      <Grid container spacing={2}>
        {Array.from({ length: count }).map((_, index) => (
          <Grid item xs={12} sm={6} md={4} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Skeleton variant="rectangular" width={80} height={24} />
                </Box>
                <Skeleton variant="text" width="60%" height={32} sx={{ mb: 1 }} />
                <Skeleton variant="text" width="100%" height={20} sx={{ mb: 0.5 }} />
                <Skeleton variant="text" width="80%" height={20} sx={{ mb: 0.5 }} />
                <Skeleton variant="text" width="70%" height={20} />
                <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1, mt: 2 }}>
                  <Skeleton variant="circular" width={32} height={32} />
                  <Skeleton variant="circular" width={32} height={32} />
                  <Skeleton variant="circular" width={32} height={32} />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    )
  }

  if (variant === 'list') {
    return (
      <Box>
        {Array.from({ length: count }).map((_, index) => (
          <Box key={index} sx={{ mb: 2 }}>
            <Card>
              <CardContent>
                <Skeleton variant="text" width="40%" height={24} sx={{ mb: 1 }} />
                <Skeleton variant="text" width="100%" height={20} />
                <Skeleton variant="text" width="80%" height={20} />
              </CardContent>
            </Card>
          </Box>
        ))}
      </Box>
    )
  }

  if (variant === 'card') {
    return (
      <Box>
        {Array.from({ length: count }).map((_, index) => (
          <Card key={index} sx={{ mb: 2 }}>
            <CardContent>
              <Skeleton variant="text" width="60%" height={32} sx={{ mb: 2 }} />
              <Skeleton variant="rectangular" width="100%" height={120} sx={{ mb: 2 }} />
              <Skeleton variant="text" width="100%" height={20} />
              <Skeleton variant="text" width="80%" height={20} />
            </CardContent>
          </Card>
        ))}
      </Box>
    )
  }

  return (
    <Box>
      {Array.from({ length: count }).map((_, index) => (
        <Skeleton key={index} variant="rectangular" width="100%" height={60} sx={{ mb: 1 }} />
      ))}
    </Box>
  )
}
