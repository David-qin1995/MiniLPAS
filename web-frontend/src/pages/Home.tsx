import { Box, Typography, Grid } from '@mui/material'
import DeviceStatus from '../components/DeviceStatus'
import ChipInfo from '../components/ChipInfo'

export default function Home() {
  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3 }}>
        概览
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <DeviceStatus />
        </Grid>
        <Grid item xs={12}>
          <ChipInfo />
        </Grid>
      </Grid>
    </Box>
  )
}

