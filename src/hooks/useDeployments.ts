import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { deploymentApi } from '@/services/api';
import type { CreateDeploymentInput } from '@/types';
import { toast } from 'sonner';

export const useDeployments = () => {
  const queryClient = useQueryClient();

  const deploymentsQuery = useQuery({
    queryKey: ['deployments'],
    queryFn: async () => {
      const response = await deploymentApi.getAll();
      if (!response.success) throw new Error(response.error);
      return response.data;
    },
    refetchInterval: 10000, // Refetch every 10 seconds for live updates
  });

  const createMutation = useMutation({
    mutationFn: async (input: CreateDeploymentInput) => {
      const response = await deploymentApi.create(input);
      if (!response.success) throw new Error(response.error);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['deployments'] });
      toast.success('Deployment started');
    },
    onError: (error) => {
      toast.error(`Failed to start deployment: ${error.message}`);
    },
  });

  const cancelMutation = useMutation({
    mutationFn: async (id: string) => {
      const response = await deploymentApi.cancel(id);
      if (!response.success) throw new Error(response.error);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['deployments'] });
      toast.success('Deployment cancelled');
    },
    onError: (error) => {
      toast.error(`Failed to cancel deployment: ${error.message}`);
    },
  });

  return {
    deployments: deploymentsQuery.data ?? [],
    isLoading: deploymentsQuery.isLoading,
    error: deploymentsQuery.error,
    createDeployment: createMutation.mutate,
    cancelDeployment: cancelMutation.mutate,
    isCreating: createMutation.isPending,
    isCancelling: cancelMutation.isPending,
  };
};