import React from 'react';
import { render, screen, act, waitFor } from '@testing-library/react';
import { MonitoringDashboard } from '../MonitoringDashboard';

// Mock fetch
global.fetch = jest.fn();

// Mock child components
jest.mock('../MetricsChart', () => ({
  MetricsChart: ({ metricName }: { metricName: string }) => (
    <div data-testid="metrics-chart">{metricName}</div>
  ),
}));

jest.mock('../HealthStatus', () => ({
  HealthStatus: ({ status }: { status: string }) => (
    <div data-testid="health-status">{status}</div>
  ),
}));

jest.mock('../TracingView', () => ({
  TracingView: ({ spans }: { spans: any[] }) => (
    <div data-testid="tracing-view">
      Spans: {spans.length}
    </div>
  ),
}));

describe('MonitoringDashboard', () => {
  const mockMetrics = {
    'test_metric': [
      { timestamp: '2023-01-01T00:00:00Z', value: 42 },
    ],
  };

  const mockHealth = {
    status: 'HEALTHY',
    message: 'All systems operational',
    details: { test: 'value' },
  };

  const mockTraces = [
    {
      context: {
        trace_id: 'test',
        span_id: 'span-1',
      },
      name: 'test-span',
    },
  ];

  beforeEach(() => {
    (global.fetch as jest.Mock).mockReset();
  });

  it('renders loading state initially', () => {
    (global.fetch as jest.Mock).mockImplementation(() => 
      new Promise(() => {})
    );

    render(<MonitoringDashboard agentId="test-agent" />);

    expect(screen.getByRole('status')).toBeInTheDocument();
  });

  it('renders data after successful fetch', async () => {
    (global.fetch as jest.Mock)
      .mockImplementationOnce(() => 
        Promise.resolve({
          json: () => Promise.resolve(mockMetrics),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          json: () => Promise.resolve(mockHealth),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          json: () => Promise.resolve(mockTraces),
        })
      );

    render(<MonitoringDashboard agentId="test-agent" />);

    await waitFor(() => {
      expect(screen.getByTestId('health-status')).toBeInTheDocument();
      expect(screen.getByTestId('metrics-chart')).toBeInTheDocument();
      expect(screen.getByTestId('tracing-view')).toBeInTheDocument();
    });
  });

  it('handles fetch errors', async () => {
    (global.fetch as jest.Mock).mockRejectedValue(new Error('Fetch failed'));

    render(<MonitoringDashboard agentId="test-agent" />);

    await waitFor(() => {
      expect(screen.getByText(/Error:/)).toBeInTheDocument();
    });
  });

  it('refreshes data at specified interval', async () => {
    jest.useFakeTimers();

    (global.fetch as jest.Mock)
      .mockImplementation(() => 
        Promise.resolve({
          json: () => Promise.resolve({}),
        })
      );

    render(
      <MonitoringDashboard
        agentId="test-agent"
        refreshInterval={1000}
      />
    );

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledTimes(3); // Initial 3 calls
    });

    act(() => {
      jest.advanceTimersByTime(1000);
    });

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledTimes(6); // After refresh
    });

    jest.useRealTimers();
  });

  it('cleans up interval on unmount', async () => {
    jest.useFakeTimers();

    (global.fetch as jest.Mock)
      .mockImplementation(() => 
        Promise.resolve({
          json: () => Promise.resolve({}),
        })
      );

    const { unmount } = render(
      <MonitoringDashboard
        agentId="test-agent"
        refreshInterval={1000}
      />
    );

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledTimes(3);
    });

    unmount();

    act(() => {
      jest.advanceTimersByTime(1000);
    });

    // Fetch count should not increase after unmount
    expect(global.fetch).toHaveBeenCalledTimes(3);

    jest.useRealTimers();
  });

  it('applies custom className', () => {
    render(
      <MonitoringDashboard
        agentId="test-agent"
        className="custom-class"
      />
    );

    expect(screen.getByTestId('monitoring-dashboard'))
      .toHaveClass('custom-class');
  });
});