import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { AlertsView } from '../AlertsView';

// Mock fetch
global.fetch = jest.fn();

describe('AlertsView', () => {
  const mockActiveAlerts = [
    {
      id: '1',
      agent_id: 'agent-1',
      severity: 'WARNING',
      message: 'High memory usage',
      details: { usage_mb: 1000 },
      timestamp: '2023-01-01T00:00:00Z',
      acknowledged: false,
    },
    {
      id: '2',
      agent_id: 'agent-1',
      severity: 'ERROR',
      message: 'High error rate',
      details: { error_rate: 0.15 },
      timestamp: '2023-01-01T00:01:00Z',
      acknowledged: true,
    },
  ];

  const mockHistoryAlerts = [
    {
      id: '3',
      agent_id: 'agent-1',
      severity: 'INFO',
      message: 'Agent started',
      details: { status: 'running' },
      timestamp: '2023-01-01T00:00:00Z',
      acknowledged: true,
    },
  ];

  beforeEach(() => {
    (global.fetch as jest.Mock)
      .mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: mockActiveAlerts }),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: mockHistoryAlerts }),
        })
      );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders loading state initially', () => {
    render(<AlertsView />);
    expect(screen.getByRole('status')).toBeInTheDocument();
  });

  it('renders alerts after loading', async () => {
    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('Active Alerts')).toBeInTheDocument();
      expect(screen.getByText('Alert History')).toBeInTheDocument();
    });

    expect(screen.getByText('High memory usage')).toBeInTheDocument();
    expect(screen.getByText('High error rate')).toBeInTheDocument();
    expect(screen.getByText('Agent started')).toBeInTheDocument();
  });

  it('handles severity filtering', async () => {
    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('Active Alerts')).toBeInTheDocument();
    });

    // Change severity filter
    fireEvent.change(screen.getByRole('combobox', { name: /severity/i }), {
      target: { value: 'WARNING' },
    });

    // Should only show warning alerts
    expect(screen.getByText('High memory usage')).toBeInTheDocument();
    expect(screen.queryByText('High error rate')).not.toBeInTheDocument();
  });

  it('handles time range filtering', async () => {
    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('Alert History')).toBeInTheDocument();
    });

    // Change time range filter
    fireEvent.change(screen.getByRole('combobox', { name: /time range/i }), {
      target: { value: '1h' },
    });

    // Should show recent alerts
    expect(screen.getByText('Agent started')).toBeInTheDocument();
  });

  it('handles alert acknowledgment', async () => {
    (global.fetch as jest.Mock)
      .mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: mockActiveAlerts }),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: mockHistoryAlerts }),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
        })
      );

    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('Active Alerts')).toBeInTheDocument();
    });

    // Click acknowledge button
    const acknowledgeButton = screen.getByText('Acknowledge');
    fireEvent.click(acknowledgeButton);

    // Should call API
    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        '/api/v1/alerts/1/acknowledge',
        expect.any(Object)
      );
    });
  });

  it('handles fetch errors', async () => {
    (global.fetch as jest.Mock).mockRejectedValue(new Error('Fetch failed'));

    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });

  it('handles empty alert lists', async () => {
    (global.fetch as jest.Mock)
      .mockImplementationOnce(() => 
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: [] }),
        })
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ alerts: [] }),
        })
      );

    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('No active alerts')).toBeInTheDocument();
      expect(screen.getByText('No alerts in history')).toBeInTheDocument();
    });
  });

  it('applies custom className', async () => {
    render(<AlertsView className="custom-class" />);

    await waitFor(() => {
      expect(screen.getByText('Active Alerts')).toBeInTheDocument();
    });

    expect(screen.getByTestId('alerts-view')).toHaveClass('custom-class');
  });

  it('refreshes data periodically', async () => {
    jest.useFakeTimers();

    render(<AlertsView />);

    await waitFor(() => {
      expect(screen.getByText('Active Alerts')).toBeInTheDocument();
    });

    // Fast-forward 30 seconds
    jest.advanceTimersByTime(30000);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledTimes(4); // Initial 2 calls + 2 refresh calls
    });

    jest.useRealTimers();
  });
});