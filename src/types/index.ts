// Task Management Types
export interface Task {
  id: string;
  title: string;
  description: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  priority: 'low' | 'medium' | 'high' | 'critical';
  assignee?: string;
  environment: 'development' | 'staging' | 'production';
  created_at: string;
  updated_at: string;
}

export interface CreateTaskInput {
  title: string;
  description: string;
  priority: Task['priority'];
  environment: Task['environment'];
  assignee?: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  status?: Task['status'];
  priority?: Task['priority'];
  environment?: Task['environment'];
  assignee?: string;
}

// Deployment Types
export interface Deployment {
  id: string;
  name: string;
  environment: 'development' | 'staging' | 'production';
  status: 'pending' | 'building' | 'deploying' | 'success' | 'failed' | 'rollback';
  version: string;
  commit_sha: string;
  branch: string;
  started_at: string;
  completed_at?: string;
  duration_seconds?: number;
  logs?: string[];
}

export interface CreateDeploymentInput {
  name: string;
  environment: Deployment['environment'];
  version: string;
  commit_sha: string;
  branch: string;
}

// Metrics Types
export interface SystemMetrics {
  cpu_usage: number;
  memory_usage: number;
  disk_usage: number;
  network_in: number;
  network_out: number;
  active_connections: number;
  uptime_seconds: number;
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  database: boolean;
  api: boolean;
  timestamp: string;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}