import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Rocket, GitBranch, GitCommit, Clock, CheckCircle2, XCircle, Loader2, RotateCcw } from 'lucide-react';
import type { Deployment } from '@/types';
import { cn } from '@/lib/utils';
import { formatDistanceToNow } from 'date-fns';

interface DeploymentListProps {
  deployments: Deployment[];
  onTriggerDeploy: () => void;
  onCancelDeploy: (id: string) => void;
}

const statusConfig = {
  pending: { icon: Clock, color: 'text-muted-foreground', label: 'Pending' },
  building: { icon: Loader2, color: 'text-primary', label: 'Building', animate: true },
  deploying: { icon: Rocket, color: 'text-accent', label: 'Deploying', animate: true },
  success: { icon: CheckCircle2, color: 'text-success', label: 'Success' },
  failed: { icon: XCircle, color: 'text-destructive', label: 'Failed' },
  rollback: { icon: RotateCcw, color: 'text-warning', label: 'Rollback' },
};

const envColors = {
  development: 'bg-muted text-muted-foreground',
  staging: 'bg-warning/20 text-warning',
  production: 'bg-success/20 text-success',
};

export const DeploymentList = ({ deployments, onTriggerDeploy, onCancelDeploy }: DeploymentListProps) => {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">Deployments</CardTitle>
          <Button onClick={onTriggerDeploy} size="sm">
            <Rocket className="h-4 w-4 mr-2" />
            New Deployment
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {deployments.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <Rocket className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No deployments yet</p>
            </div>
          ) : (
            deployments.map((deployment) => {
              const status = statusConfig[deployment.status];
              const StatusIcon = status.icon;
              const isActive = deployment.status === 'building' || deployment.status === 'deploying';

              return (
                <div
                  key={deployment.id}
                  className={cn(
                    "p-4 rounded-lg border transition-all",
                    isActive && "border-primary/50 shadow-md animate-pulse-glow"
                  )}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4">
                      <div className={cn(
                        "p-2 rounded-lg",
                        isActive ? "bg-primary/10" : "bg-muted"
                      )}>
                        <StatusIcon className={cn(
                          "h-5 w-5",
                          status.color,
                          isActive && "animate-spin"
                        )} />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="font-semibold">{deployment.name}</h4>
                          <Badge className={cn("text-xs", envColors[deployment.environment])}>
                            {deployment.environment}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-4 mt-2 text-sm text-muted-foreground">
                          <span className="flex items-center gap-1 font-mono">
                            <GitBranch className="h-3 w-3" />
                            {deployment.branch}
                          </span>
                          <span className="flex items-center gap-1 font-mono">
                            <GitCommit className="h-3 w-3" />
                            {deployment.commit_sha.substring(0, 7)}
                          </span>
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {formatDistanceToNow(new Date(deployment.started_at), { addSuffix: true })}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={isActive ? "default" : "outline"} className={cn("text-xs", status.color)}>
                        {status.label}
                      </Badge>
                      {isActive && (
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => onCancelDeploy(deployment.id)}
                        >
                          Cancel
                        </Button>
                      )}
                    </div>
                  </div>
                  {deployment.duration_seconds && (
                    <div className="mt-3 pt-3 border-t text-xs text-muted-foreground">
                      Duration: {Math.floor(deployment.duration_seconds / 60)}m {deployment.duration_seconds % 60}s
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </CardContent>
    </Card>
  );
};