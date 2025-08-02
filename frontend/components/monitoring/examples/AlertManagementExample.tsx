import React, { useState, useCallback, useEffect } from 'react';
import { AlertsView } from '../AlertsView';
import { MonitoringDashboard } from '../MonitoringDashboard';

/**
 * Example component demonstrating various ways to use the alerts system
 * in the frontend, including:
 * 1. Basic AlertsView usage
 * 2. Custom alert filtering and handling
 * 3. Integration with MonitoringDashboard
 * 4. Real-time alert updates
 */
export const AlertManagementExample: React.FC = () => {
  // Example 1: Basic Usage
  const BasicExample = () => (
    <div className="example-section">
      <h2>Basic Alerts View</h2>
      <AlertsView />
    </div>
  );

  // Example 2: Custom Filtering and Handling
  const CustomExample = () => {
    const [selectedAgent, setSelectedAgent] = useState<string>('');
    const [customSeverityFilter, setCustomSeverityFilter] = useState<string>('all');

    const handleAlertAcknowledge = useCallback(async (alertId: string) => {
      try {
        await fetch(`/api/v1/alerts/${alertId}/acknowledge`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          }
        });
        // Handle success (e.g., show notification)
        console.log(`Alert ${alertId} acknowledged`);
      } catch (error) {
        // Handle error
        console.error('Failed to acknowledge alert:', error);
      }
    }, []);

    return (
      <div className="example-section">
        <h2>Custom Alerts Integration</h2>
        
        {/* Agent selector */}
        <select
          value={selectedAgent}
          onChange={(e) => setSelectedAgent(e.target.value)}
          className="mb-4 p-2 border rounded"
        >
          <option value="">All Agents</option>
          <option value="agent-1">Agent 1</option>
          <option value="agent-2">Agent 2</option>
        </select>

        {/* Custom severity filter */}
        <select
          value={customSeverityFilter}
          onChange={(e) => setCustomSeverityFilter(e.target.value)}
          className="ml-4 mb-4 p-2 border rounded"
        >
          <option value="all">All Severities</option>
          <option value="INFO">Info Only</option>
          <option value="WARNING">Warnings Only</option>
          <option value="ERROR">Errors Only</option>
          <option value="CRITICAL">Critical Only</option>
        </select>

        {/* Alerts view with custom props */}
        <AlertsView
          agentId={selectedAgent || undefined}
          className="custom-alerts-view"
        />
      </div>
    );
  };

  // Example 3: Dashboard Integration
  const DashboardExample = () => {
    const [selectedAgent, setSelectedAgent] = useState<string>('agent-1');

    return (
      <div className="example-section">
        <h2>Dashboard Integration</h2>
        
        {/* Agent selector */}
        <select
          value={selectedAgent}
          onChange={(e) => setSelectedAgent(e.target.value)}
          className="mb-4 p-2 border rounded"
        >
          <option value="agent-1">Agent 1</option>
          <option value="agent-2">Agent 2</option>
        </select>

        {/* Full monitoring dashboard */}
        <MonitoringDashboard
          agentId={selectedAgent}
          refreshInterval={5000}
          className="dashboard-example"
        />
      </div>
    );
  };

  // Example 4: Real-time Updates
  const RealtimeExample = () => {
    const [alerts, setAlerts] = useState<any[]>([]);
    const [isConnected, setIsConnected] = useState(false);

    useEffect(() => {
      // Set up WebSocket connection for real-time updates
      const ws = new WebSocket('ws://localhost:8000/ws/alerts');

      ws.onopen = () => {
        setIsConnected(true);
        console.log('WebSocket connected');
      };

      ws.onmessage = (event) => {
        const newAlert = JSON.parse(event.data);
        setAlerts(prev => [...prev, newAlert]);
      };

      ws.onclose = () => {
        setIsConnected(false);
        console.log('WebSocket disconnected');
      };

      return () => {
        ws.close();
      };
    }, []);

    return (
      <div className="example-section">
        <h2>Real-time Alerts</h2>
        
        {/* Connection status */}
        <div className={`status-indicator ${isConnected ? 'connected' : 'disconnected'}`}>
          {isConnected ? 'Connected' : 'Disconnected'}
        </div>

        {/* Real-time alerts list */}
        <div className="realtime-alerts">
          {alerts.map((alert, index) => (
            <div
              key={index}
              className={`alert-item ${alert.severity.toLowerCase()}`}
            >
              <span className="timestamp">
                {new Date(alert.timestamp).toLocaleTimeString()}
              </span>
              <span className="severity">{alert.severity}</span>
              <span className="message">{alert.message}</span>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="alert-management-examples p-4 space-y-8">
      <h1 className="text-2xl font-bold mb-8">Alert Management Examples</h1>
      
      <BasicExample />
      <CustomExample />
      <DashboardExample />
      <RealtimeExample />

      <style jsx>{`
        .example-section {
          border: 1px solid #e2e8f0;
          border-radius: 0.5rem;
          padding: 1.5rem;
          margin-bottom: 2rem;
        }

        .status-indicator {
          padding: 0.5rem;
          border-radius: 0.25rem;
          margin-bottom: 1rem;
        }

        .status-indicator.connected {
          background-color: #c6f6d5;
          color: #2f855a;
        }

        .status-indicator.disconnected {
          background-color: #fed7d7;
          color: #c53030;
        }

        .realtime-alerts {
          max-height: 300px;
          overflow-y: auto;
        }

        .alert-item {
          padding: 0.5rem;
          margin-bottom: 0.5rem;
          border-radius: 0.25rem;
        }

        .alert-item.info {
          background-color: #ebf8ff;
        }

        .alert-item.warning {
          background-color: #fffaf0;
        }

        .alert-item.error {
          background-color: #fff5f5;
        }

        .alert-item.critical {
          background-color: #faf5ff;
        }

        .timestamp {
          color: #718096;
          margin-right: 1rem;
          font-size: 0.875rem;
        }

        .severity {
          font-weight: 600;
          margin-right: 1rem;
        }
      `}</style>
    </div>
  );
};

AlertManagementExample.displayName = 'AlertManagementExample';