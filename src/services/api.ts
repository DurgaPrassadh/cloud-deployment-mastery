import { API_CONFIG, getApiUrl } from '@/config/api';
import type { 
  Task, 
  CreateTaskInput, 
  UpdateTaskInput, 
  Deployment, 
  CreateDeploymentInput,
  HealthStatus,
  SystemMetrics,
  ApiResponse 
} from '@/types';

// Generic fetch wrapper with error handling
async function fetchApi<T>(
  endpoint: string,
  options?: RequestInit
): Promise<ApiResponse<T>> {
  try {
    const response = await fetch(getApiUrl(endpoint), {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    const data = await response.json();

    if (!response.ok) {
      return {
        success: false,
        error: data.error || `HTTP Error: ${response.status}`,
      };
    }

    return {
      success: true,
      data: data.data || data,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Network error',
    };
  }
}

// Task API
export const taskApi = {
  getAll: () => fetchApi<Task[]>(API_CONFIG.ENDPOINTS.TASKS),
  
  getById: (id: string) => fetchApi<Task>(API_CONFIG.ENDPOINTS.TASK_BY_ID(id)),
  
  create: (input: CreateTaskInput) =>
    fetchApi<Task>(API_CONFIG.ENDPOINTS.TASKS, {
      method: 'POST',
      body: JSON.stringify(input),
    }),
  
  update: (id: string, input: UpdateTaskInput) =>
    fetchApi<Task>(API_CONFIG.ENDPOINTS.TASK_BY_ID(id), {
      method: 'PUT',
      body: JSON.stringify(input),
    }),
  
  delete: (id: string) =>
    fetchApi<void>(API_CONFIG.ENDPOINTS.TASK_BY_ID(id), {
      method: 'DELETE',
    }),
};

// Deployment API
export const deploymentApi = {
  getAll: () => fetchApi<Deployment[]>(API_CONFIG.ENDPOINTS.DEPLOYMENTS),
  
  getById: (id: string) => fetchApi<Deployment>(API_CONFIG.ENDPOINTS.DEPLOYMENT_BY_ID(id)),
  
  create: (input: CreateDeploymentInput) =>
    fetchApi<Deployment>(API_CONFIG.ENDPOINTS.DEPLOYMENTS, {
      method: 'POST',
      body: JSON.stringify(input),
    }),
  
  cancel: (id: string) =>
    fetchApi<Deployment>(API_CONFIG.ENDPOINTS.DEPLOYMENT_BY_ID(id), {
      method: 'DELETE',
    }),
};

// Health & Metrics API
export const systemApi = {
  getHealth: () => fetchApi<HealthStatus>(API_CONFIG.ENDPOINTS.HEALTH),
  
  getMetrics: () => fetchApi<SystemMetrics>(API_CONFIG.ENDPOINTS.METRICS),
};