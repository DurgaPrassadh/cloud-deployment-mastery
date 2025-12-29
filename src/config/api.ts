// API Configuration for 3-Tier Architecture
// Update this URL to point to your Backend EC2 private IP or load balancer

export const API_CONFIG = {
  // For development: use localhost
  // For production: use your Backend EC2 private IP (e.g., http://10.0.2.10:3000)
  BASE_URL: import.meta.env.VITE_API_URL || 'http://localhost:3000',
  
  // API endpoints
  ENDPOINTS: {
    // Tasks
    TASKS: '/api/tasks',
    TASK_BY_ID: (id: string) => `/api/tasks/${id}`,
    
    // Deployments
    DEPLOYMENTS: '/api/deployments',
    DEPLOYMENT_BY_ID: (id: string) => `/api/deployments/${id}`,
    
    // Health check
    HEALTH: '/api/health',
    
    // Metrics
    METRICS: '/api/metrics',
  }
};

export const getApiUrl = (endpoint: string): string => {
  return `${API_CONFIG.BASE_URL}${endpoint}`;
};