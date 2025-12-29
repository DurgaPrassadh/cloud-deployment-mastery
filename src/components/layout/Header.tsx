import { Activity, Server, Bell, Settings } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

interface HeaderProps {
  healthStatus?: 'healthy' | 'degraded' | 'unhealthy';
}

export const Header = ({ healthStatus = 'healthy' }: HeaderProps) => {
  const statusColors = {
    healthy: 'bg-success',
    degraded: 'bg-warning',
    unhealthy: 'bg-destructive',
  };

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/60">
      <div className="container flex h-16 items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-lg bg-primary/10">
              <Server className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-lg font-semibold tracking-tight">DevOps Dashboard</h1>
              <p className="text-xs text-muted-foreground font-mono">3-Tier Architecture</p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-muted">
            <div className={`status-indicator ${statusColors[healthStatus]}`} />
            <span className="text-sm font-medium capitalize">{healthStatus}</span>
          </div>

          <Badge variant="outline" className="font-mono text-xs">
            <Activity className="h-3 w-3 mr-1" />
            Live
          </Badge>

          <Button variant="ghost" size="icon">
            <Bell className="h-5 w-5" />
          </Button>

          <Button variant="ghost" size="icon">
            <Settings className="h-5 w-5" />
          </Button>
        </div>
      </div>
    </header>
  );
};