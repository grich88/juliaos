import React, { useEffect, useState, useCallback } from 'react';
import { MetricsChart } from './MetricsChart';
import { HealthStatus } from './HealthStatus';
import { TracingView } from './TracingView';
import { AlertsView } from './AlertsView';

interface MonitoringDashboardProps {
  agentId: string;
  refreshInterval?: number; // milliseconds
  className?: string;
}

export const MonitoringDashboard = React.memo(function MonitoringDashboard({
  agentId,
  refreshInterval = 5000,
  className = ''
}: MonitoringDashboardProps) {
  const [metrics, setMetrics] = useState<Record<string, any>>({});
  const [health, setHealth] = useState<any>(null);
  const [traces, setTraces] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'metrics' | 'alerts' | 'traces'>('metrics');

  const fetchData = useCallback(async () => {
    try {
      // Fetch metrics
      const metricsResponse = await fetch(`/api/v1/agents/${agentId}/metrics`);
      const metricsData = await metricsResponse.json();
      setMetrics(metricsData);

      // Fetch health status
      const healthResponse = await fetch(`/api/v1/agents/${agentId}/health`);
      const healthData = await healthResponse.json();
      setHealth(healthData);

      // Fetch traces
      const tracesResponse = await fetch(`/api/v1/agents/${agentId}/traces`);
      const tracesData = await tracesResponse.json();
      setTraces(tracesData);

      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch monitoring data');
    } finally {
      setLoading(false);
    }
  }, [agentId]);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, refreshInterval);
    return () => clearInterval(interval);
  }, [fetchData, refreshInterval]);

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
        Error: {error}
      </div>
    );
  }

  return (
    <div className={`monitoring-dashboard space-y-8 ${className}`}>
      {/* Health Status Section */}
      {health && (
        <div className="health-section">
          <h2 className="text-xl font-bold mb-4">Health Status</h2>
          <HealthStatus
            status={health.status}
            message={health.message}
            details={health.details}
          />
        </div>
      )}

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('metrics')}
            className={`
              py-4 px-1 border-b-2 font-medium text-sm
              ${activeTab === 'metrics'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
            `}
          >
            Metrics
          </button>
          <button
            onClick={() => setActiveTab('alerts')}
            className={`
              py-4 px-1 border-b-2 font-medium text-sm
              ${activeTab === 'alerts'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
            `}
          >
            Alerts
          </button>
          <button
            onClick={() => setActiveTab('traces')}
            className={`
              py-4 px-1 border-b-2 font-medium text-sm
              ${activeTab === 'traces'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
            `}
          >
            Traces
          </button>
        </nav>
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        {activeTab === 'metrics' && (
          <div className="metrics-section">
            <h2 className="text-xl font-bold mb-4">Metrics</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {Object.entries(metrics).map(([name, data]) => (
                <MetricsChart
                  key={name}
                  metricName={name}
                  data={data}
                  height={250}
                />
              ))}
            </div>
          </div>
        )}

        {activeTab === 'alerts' && (
          <div className="alerts-section">
            <h2 className="text-xl font-bold mb-4">Alerts</h2>
            <AlertsView agentId={agentId} />
          </div>
        )}

        {activeTab === 'traces' && (
          <div className="tracing-section">
            <h2 className="text-xl font-bold mb-4">Traces</h2>
            <TracingView spans={traces} />
          </div>
        )}
      </div>
    </div>
  );
});

MonitoringDashboard.displayName = 'MonitoringDashboard';