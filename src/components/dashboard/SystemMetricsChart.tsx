import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Cpu, HardDrive, MemoryStick, Wifi } from 'lucide-react';

interface MetricGaugeProps {
  label: string;
  value: number;
  icon: React.ReactNode;
  color: string;
}

const MetricGauge = ({ label, value, icon, color }: MetricGaugeProps) => (
  <div className="space-y-2">
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        {icon}
        <span className="text-sm font-medium">{label}</span>
      </div>
      <span className="text-sm font-mono font-bold">{value}%</span>
    </div>
    <Progress value={value} className={`h-2 ${color}`} />
  </div>
);

export const SystemMetricsChart = () => {
  // Simulated metrics for demo (replace with real API data)
  const [metrics, setMetrics] = useState({
    cpu: 45,
    memory: 62,
    disk: 38,
    network: 25,
  });

  useEffect(() => {
    // Simulate real-time updates
    const interval = setInterval(() => {
      setMetrics({
        cpu: Math.min(100, Math.max(10, metrics.cpu + (Math.random() - 0.5) * 10)),
        memory: Math.min(100, Math.max(20, metrics.memory + (Math.random() - 0.5) * 5)),
        disk: Math.min(100, Math.max(20, metrics.disk + (Math.random() - 0.5) * 2)),
        network: Math.min(100, Math.max(5, metrics.network + (Math.random() - 0.5) * 15)),
      });
    }, 3000);

    return () => clearInterval(interval);
  }, [metrics]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">System Resources</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <MetricGauge
          label="CPU Usage"
          value={Math.round(metrics.cpu)}
          icon={<Cpu className="h-4 w-4 text-primary" />}
          color="bg-primary"
        />
        <MetricGauge
          label="Memory"
          value={Math.round(metrics.memory)}
          icon={<MemoryStick className="h-4 w-4 text-accent" />}
          color="bg-accent"
        />
        <MetricGauge
          label="Disk"
          value={Math.round(metrics.disk)}
          icon={<HardDrive className="h-4 w-4 text-warning" />}
          color="bg-warning"
        />
        <MetricGauge
          label="Network"
          value={Math.round(metrics.network)}
          icon={<Wifi className="h-4 w-4 text-success" />}
          color="bg-success"
        />
      </CardContent>
    </Card>
  );
};