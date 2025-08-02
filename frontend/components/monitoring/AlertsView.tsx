import React, { useState, useCallback, useEffect } from 'react';
import { format } from 'date-fns';

interface Alert {
  id: string;
  agent_id: string;
  severity: 'INFO' | 'WARNING' | 'ERROR' | 'CRITICAL';
  message: string;
  details: Record<string, any>;
  timestamp: string;
  acknowledged: boolean;
}

interface AlertsViewProps {
  agentId?: string;
  className?: string;
}

export const AlertsView = React.memo(function AlertsView({
  agentId,
  className = ''
}: AlertsViewProps) {
  const [activeAlerts, setActiveAlerts] = useState<Alert[]>([]);
  const [alertHistory, setAlertHistory] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSeverity, setSelectedSeverity] = useState<string>('all');
  const [timeRange, setTimeRange] = useState<string>('1h');

  const fetchAlerts = useCallback(async () => {
    try {
      // Fetch active alerts
      const activeResponse = await fetch(
        `/api/v1/alerts/active${agentId ? `?agent_id=${agentId}` : ''}`
      );
      const activeData = await activeResponse.json();
      setActiveAlerts(activeData.alerts || []);

      // Fetch alert history
      const historyResponse = await fetch(
        `/api/v1/alerts/history${agentId ? `?agent_id=${agentId}` : ''}`
      );
      const historyData = await historyResponse.json();
      setAlertHistory(historyData.alerts || []);

      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch alerts');
    } finally {
      setLoading(false);
    }
  }, [agentId]);

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, [fetchAlerts]);

  const handleAcknowledge = useCallback(async (alertId: string) => {
    try {
      const response = await fetch(`/api/v1/alerts/${alertId}/acknowledge`, {
        method: 'POST'
      });
      if (!response.ok) throw new Error('Failed to acknowledge alert');
      fetchAlerts(); // Refresh alerts
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to acknowledge alert');
    }
  }, [fetchAlerts]);

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'INFO': return 'bg-blue-100 text-blue-800';
      case 'WARNING': return 'bg-yellow-100 text-yellow-800';
      case 'ERROR': return 'bg-red-100 text-red-800';
      case 'CRITICAL': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const filteredActiveAlerts = activeAlerts.filter(alert => 
    selectedSeverity === 'all' || alert.severity === selectedSeverity
  );

  const filteredHistoryAlerts = alertHistory.filter(alert => {
    if (selectedSeverity !== 'all' && alert.severity !== selectedSeverity) return false;
    
    const alertTime = new Date(alert.timestamp).getTime();
    const now = Date.now();
    switch (timeRange) {
      case '1h': return now - alertTime <= 3600000;
      case '24h': return now - alertTime <= 86400000;
      case '7d': return now - alertTime <= 604800000;
      default: return true;
    }
  });

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
    <div className={`alerts-view space-y-6 ${className}`}>
      {/* Filters */}
      <div className="flex space-x-4 items-center">
        <select
          value={selectedSeverity}
          onChange={(e) => setSelectedSeverity(e.target.value)}
          className="rounded-md border border-gray-300 px-3 py-2"
        >
          <option value="all">All Severities</option>
          <option value="INFO">Info</option>
          <option value="WARNING">Warning</option>
          <option value="ERROR">Error</option>
          <option value="CRITICAL">Critical</option>
        </select>

        <select
          value={timeRange}
          onChange={(e) => setTimeRange(e.target.value)}
          className="rounded-md border border-gray-300 px-3 py-2"
        >
          <option value="1h">Last Hour</option>
          <option value="24h">Last 24 Hours</option>
          <option value="7d">Last 7 Days</option>
          <option value="all">All Time</option>
        </select>
      </div>

      {/* Active Alerts */}
      <div>
        <h2 className="text-xl font-bold mb-4">Active Alerts</h2>
        {filteredActiveAlerts.length === 0 ? (
          <p className="text-gray-500">No active alerts</p>
        ) : (
          <div className="space-y-4">
            {filteredActiveAlerts.map(alert => (
              <div
                key={alert.id}
                className={`p-4 rounded-lg border ${getSeverityColor(alert.severity)}`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <span className="font-semibold">{alert.severity}</span>
                    <p className="text-sm mt-1">{alert.message}</p>
                    <p className="text-xs mt-1">
                      Agent: {alert.agent_id} • {format(new Date(alert.timestamp), 'PPp')}
                    </p>
                    <pre className="mt-2 text-xs bg-white bg-opacity-50 p-2 rounded">
                      {JSON.stringify(alert.details, null, 2)}
                    </pre>
                  </div>
                  {!alert.acknowledged && (
                    <button
                      onClick={() => handleAcknowledge(alert.id)}
                      className="px-3 py-1 bg-white rounded-md text-sm shadow-sm hover:bg-gray-50"
                    >
                      Acknowledge
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Alert History */}
      <div>
        <h2 className="text-xl font-bold mb-4">Alert History</h2>
        {filteredHistoryAlerts.length === 0 ? (
          <p className="text-gray-500">No alerts in history</p>
        ) : (
          <div className="space-y-2">
            {filteredHistoryAlerts.map(alert => (
              <div
                key={alert.id}
                className={`p-3 rounded-lg border ${getSeverityColor(alert.severity)} opacity-75`}
              >
                <span className="font-semibold">{alert.severity}</span>
                <p className="text-sm mt-1">{alert.message}</p>
                <p className="text-xs mt-1">
                  Agent: {alert.agent_id} • {format(new Date(alert.timestamp), 'PPp')}
                </p>
                <button
                  onClick={() => {
                    const el = document.createElement('textarea');
                    el.value = JSON.stringify(alert.details, null, 2);
                    document.body.appendChild(el);
                    el.select();
                    document.execCommand('copy');
                    document.body.removeChild(el);
                  }}
                  className="text-xs underline mt-1 hover:text-gray-700"
                >
                  Copy Details
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
});

AlertsView.displayName = 'AlertsView';