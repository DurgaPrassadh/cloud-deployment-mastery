import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Globe, Server, Database, ArrowDown, Shield } from 'lucide-react';

export const ArchitectureDiagram = () => {
  return (
    <Card className="overflow-hidden">
      <CardHeader className="bg-muted/50">
        <CardTitle className="text-lg flex items-center gap-2">
          <Shield className="h-5 w-5 text-primary" />
          3-Tier Architecture
        </CardTitle>
      </CardHeader>
      <CardContent className="p-6">
        <div className="flex flex-col items-center space-y-4">
          {/* Frontend Tier */}
          <div className="w-full p-4 rounded-lg border-2 border-primary bg-primary/5 animate-fade-in">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-primary/10">
                  <Globe className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold">Frontend EC2</h3>
                  <p className="text-xs text-muted-foreground font-mono">Public Subnet</p>
                </div>
              </div>
              <div className="flex gap-2">
                <Badge variant="outline" className="text-xs">React</Badge>
                <Badge variant="outline" className="text-xs">Nginx</Badge>
                <Badge className="text-xs bg-success">Elastic IP</Badge>
              </div>
            </div>
          </div>

          <ArrowDown className="h-6 w-6 text-muted-foreground" />

          {/* Backend Tier */}
          <div className="w-full p-4 rounded-lg border-2 border-accent bg-accent/5 animate-fade-in" style={{ animationDelay: '0.1s' }}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-accent/10">
                  <Server className="h-5 w-5 text-accent" />
                </div>
                <div>
                  <h3 className="font-semibold">Backend EC2</h3>
                  <p className="text-xs text-muted-foreground font-mono">Private Subnet</p>
                </div>
              </div>
              <div className="flex gap-2">
                <Badge variant="outline" className="text-xs">Node.js</Badge>
                <Badge variant="outline" className="text-xs">Express</Badge>
                <Badge variant="outline" className="text-xs">PM2</Badge>
              </div>
            </div>
          </div>

          <ArrowDown className="h-6 w-6 text-muted-foreground" />

          {/* Database Tier */}
          <div className="w-full p-4 rounded-lg border-2 border-warning bg-warning/5 animate-fade-in" style={{ animationDelay: '0.2s' }}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-warning/10">
                  <Database className="h-5 w-5 text-warning" />
                </div>
                <div>
                  <h3 className="font-semibold">Database EC2</h3>
                  <p className="text-xs text-muted-foreground font-mono">Private Subnet (Locked)</p>
                </div>
              </div>
              <div className="flex gap-2">
                <Badge variant="outline" className="text-xs">PostgreSQL</Badge>
                <Badge variant="destructive" className="text-xs">No Public IP</Badge>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};