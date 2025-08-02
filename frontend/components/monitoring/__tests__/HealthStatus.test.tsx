import React from 'react';
import { render, screen } from '@testing-library/react';
import { HealthStatus } from '../HealthStatus';

describe('HealthStatus', () => {
  const mockDetails = {
    idle_time: 120,
    error_count: 0,
    last_activity: '2023-01-01T00:00:00Z',
  };

  it('renders healthy status correctly', () => {
    render(
      <HealthStatus
        status="HEALTHY"
        message="System is healthy"
        details={mockDetails}
      />
    );

    expect(screen.getByText('HEALTHY')).toBeInTheDocument();
    expect(screen.getByText('System is healthy')).toBeInTheDocument();
    expect(screen.getByText('idle_time:')).toBeInTheDocument();
    expect(screen.getByText('120')).toBeInTheDocument();
  });

  it('renders degraded status correctly', () => {
    render(
      <HealthStatus
        status="DEGRADED"
        message="System is degraded"
        details={mockDetails}
      />
    );

    const container = screen.getByRole('heading', { name: 'DEGRADED' });
    expect(container).toHaveClass('text-yellow-500');
  });

  it('renders unhealthy status correctly', () => {
    render(
      <HealthStatus
        status="UNHEALTHY"
        message="System is unhealthy"
        details={mockDetails}
      />
    );

    const container = screen.getByRole('heading', { name: 'UNHEALTHY' });
    expect(container).toHaveClass('text-red-500');
  });

  it('applies custom className', () => {
    render(
      <HealthStatus
        status="HEALTHY"
        message="System is healthy"
        details={mockDetails}
        className="custom-class"
      />
    );

    expect(screen.getByTestId('health-status')).toHaveClass('custom-class');
  });

  it('handles complex detail values', () => {
    const complexDetails = {
      ...mockDetails,
      nested: { key: 'value' },
      array: [1, 2, 3],
    };

    render(
      <HealthStatus
        status="HEALTHY"
        message="System is healthy"
        details={complexDetails}
      />
    );

    expect(screen.getByText(/{"key":"value"}/)).toBeInTheDocument();
    expect(screen.getByText(/\[1,2,3\]/)).toBeInTheDocument();
  });

  it('memoizes rendering', () => {
    const { rerender } = render(
      <HealthStatus
        status="HEALTHY"
        message="System is healthy"
        details={mockDetails}
      />
    );

    // Re-render with same props
    rerender(
      <HealthStatus
        status="HEALTHY"
        message="System is healthy"
        details={mockDetails}
      />
    );

    // Component should maintain same DOM structure
    expect(screen.getAllByRole('heading')).toHaveLength(1);
  });
});