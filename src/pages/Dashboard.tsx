import { useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Header } from '@/components/layout/Header';
import { Sidebar } from '@/components/layout/Sidebar';
import { StatsCard } from '@/components/dashboard/StatsCard';
import { SystemMetricsChart } from '@/components/dashboard/SystemMetricsChart';
import { ArchitectureDiagram } from '@/components/dashboard/ArchitectureDiagram';
import { TaskList } from '@/components/tasks/TaskList';
import { CreateTaskDialog } from '@/components/tasks/CreateTaskDialog';
import { DeploymentList } from '@/components/deployments/DeploymentList';
import { CreateDeploymentDialog } from '@/components/deployments/CreateDeploymentDialog';
import { CheckSquare, Rocket, Activity, Server } from 'lucide-react';
import type { Task, Deployment, CreateTaskInput, CreateDeploymentInput } from '@/types';
import { cn } from '@/lib/utils';

// Demo data for when backend is not connected
const demoTasks: Task[] = [
  {
    id: '1',
    title: 'Configure Nginx reverse proxy',
    description: 'Set up Nginx to route traffic from frontend to backend API',
    status: 'completed',
    priority: 'high',
    environment: 'production',
    assignee: 'DevOps Team',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: '2',
    title: 'Set up PM2 process manager',
    description: 'Configure PM2 for Node.js backend with auto-restart',
    status: 'in_progress',
    priority: 'high',
    environment: 'production',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: '3',
    title: 'Configure PostgreSQL security groups',
    description: 'Restrict database access to backend EC2 only',
    status: 'pending',
    priority: 'critical',
    environment: 'production',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
];

const demoDeployments: Deployment[] = [
  {
    id: '1',
    name: 'Initial Production Deploy',
    environment: 'production',
    status: 'success',
    version: 'v1.0.0',
    commit_sha: 'abc1234567890',
    branch: 'main',
    started_at: new Date(Date.now() - 3600000).toISOString(),
    completed_at: new Date().toISOString(),
    duration_seconds: 245,
  },
  {
    id: '2',
    name: 'Feature: API endpoints',
    environment: 'staging',
    status: 'building',
    version: 'v1.1.0-beta',
    commit_sha: 'def5678901234',
    branch: 'develop',
    started_at: new Date().toISOString(),
  },
];

export const Dashboard = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [tasks, setTasks] = useState<Task[]>(demoTasks);
  const [deployments, setDeployments] = useState<Deployment[]>(demoDeployments);
  const [isTaskDialogOpen, setIsTaskDialogOpen] = useState(false);
  const [isDeployDialogOpen, setIsDeployDialogOpen] = useState(false);

  const handleCreateTask = (input: CreateTaskInput) => {
    const newTask: Task = {
      id: Date.now().toString(),
      ...input,
      status: 'pending',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    setTasks([newTask, ...tasks]);
    setIsTaskDialogOpen(false);
  };

  const handleUpdateTaskStatus = (id: string, status: Task['status']) => {
    setTasks(tasks.map(t => t.id === id ? { ...t, status, updated_at: new Date().toISOString() } : t));
  };

  const handleDeleteTask = (id: string) => {
    setTasks(tasks.filter(t => t.id !== id));
  };

  const handleCreateDeployment = (input: CreateDeploymentInput) => {
    const newDeployment: Deployment = {
      id: Date.now().toString(),
      ...input,
      status: 'building',
      started_at: new Date().toISOString(),
    };
    setDeployments([newDeployment, ...deployments]);
    setIsDeployDialogOpen(false);
  };

  const handleCancelDeployment = (id: string) => {
    setDeployments(deployments.map(d => 
      d.id === id ? { ...d, status: 'failed' as const } : d
    ));
  };

  const taskStats = {
    total: tasks.length,
    completed: tasks.filter(t => t.status === 'completed').length,
    inProgress: tasks.filter(t => t.status === 'in_progress').length,
    pending: tasks.filter(t => t.status === 'pending').length,
  };

  const deployStats = {
    total: deployments.length,
    success: deployments.filter(d => d.status === 'success').length,
    active: deployments.filter(d => ['building', 'deploying'].includes(d.status)).length,
  };

  return (
    <>
      <Helmet>
        <title>DevOps Dashboard | 3-Tier Architecture</title>
        <meta name="description" content="Monitor and manage your 3-tier architecture deployment with this DevOps dashboard" />
      </Helmet>

      <div className="min-h-screen bg-background">
        <Header healthStatus="healthy" />
        <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
        
        <main className={cn(
          "transition-all duration-300 pt-6 pb-12",
          sidebarCollapsed ? "ml-16" : "ml-64"
        )}>
          <div className="container max-w-7xl">
            {activeTab === 'dashboard' && (
              <div className="space-y-6 animate-fade-in">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight">Dashboard</h2>
                  <p className="text-muted-foreground">
                    Monitor your 3-tier architecture deployment
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <StatsCard
                    title="Total Tasks"
                    value={taskStats.total}
                    icon={CheckSquare}
                    variant="primary"
                    trend={{ value: 12, isPositive: true }}
                  />
                  <StatsCard
                    title="Completed"
                    value={taskStats.completed}
                    icon={CheckSquare}
                    variant="success"
                    description={`${Math.round((taskStats.completed / taskStats.total) * 100)}% completion rate`}
                  />
                  <StatsCard
                    title="Deployments"
                    value={deployStats.total}
                    icon={Rocket}
                    variant="default"
                    trend={{ value: 8, isPositive: true }}
                  />
                  <StatsCard
                    title="Active Deploys"
                    value={deployStats.active}
                    icon={Activity}
                    variant={deployStats.active > 0 ? 'warning' : 'default'}
                  />
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <ArchitectureDiagram />
                  <SystemMetricsChart />
                </div>
              </div>
            )}

            {activeTab === 'tasks' && (
              <div className="space-y-6 animate-fade-in">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight">Tasks</h2>
                  <p className="text-muted-foreground">
                    Manage deployment and infrastructure tasks
                  </p>
                </div>
                <TaskList
                  tasks={tasks}
                  onCreateTask={() => setIsTaskDialogOpen(true)}
                  onDeleteTask={handleDeleteTask}
                  onUpdateStatus={handleUpdateTaskStatus}
                />
              </div>
            )}

            {activeTab === 'deployments' && (
              <div className="space-y-6 animate-fade-in">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight">Deployments</h2>
                  <p className="text-muted-foreground">
                    Track and manage application deployments
                  </p>
                </div>
                <DeploymentList
                  deployments={deployments}
                  onTriggerDeploy={() => setIsDeployDialogOpen(true)}
                  onCancelDeploy={handleCancelDeployment}
                />
              </div>
            )}

            {activeTab === 'metrics' && (
              <div className="space-y-6 animate-fade-in">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight">System Metrics</h2>
                  <p className="text-muted-foreground">
                    Real-time monitoring of your infrastructure
                  </p>
                </div>
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <SystemMetricsChart />
                  <StatsCard
                    title="Uptime"
                    value="99.9%"
                    icon={Server}
                    variant="success"
                    description="Last 30 days"
                  />
                </div>
              </div>
            )}

            {activeTab === 'database' && (
              <div className="space-y-6 animate-fade-in">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight">Database</h2>
                  <p className="text-muted-foreground">
                    PostgreSQL database management (connect backend to enable)
                  </p>
                </div>
                <ArchitectureDiagram />
              </div>
            )}
          </div>
        </main>

        <CreateTaskDialog
          open={isTaskDialogOpen}
          onOpenChange={setIsTaskDialogOpen}
          onSubmit={handleCreateTask}
        />

        <CreateDeploymentDialog
          open={isDeployDialogOpen}
          onOpenChange={setIsDeployDialogOpen}
          onSubmit={handleCreateDeployment}
        />
      </div>
    </>
  );
};