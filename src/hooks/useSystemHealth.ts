import { useQuery } from '@tanstack/react-query';
import { systemApi } from '@/services/api';

export const useSystemHealth = () => {
  const healthQuery = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const response = await systemApi.getHealth();
      if (!response.success) throw new Error(response.error);
      return response.data;
    },
    refetchInterval: 15000, // Check health every 15 seconds
    retry: 3,
  });

  const metricsQuery = useQuery({
    queryKey: ['metrics'],
    queryFn: async () => {
      const response = await systemApi.getMetrics();
      if (!response.success) throw new Error(response.error);
      return response.data;
    },
    refetchInterval: 5000, // Update metrics every 5 seconds
    retry: 2,
  });

  return {
    health: healthQuery.data,
    metrics: metricsQuery.data,
    isHealthLoading: healthQuery.isLoading,
    isMetricsLoading: metricsQuery.isLoading,
    healthError: healthQuery.error,
    metricsError: metricsQuery.error,
  };
};