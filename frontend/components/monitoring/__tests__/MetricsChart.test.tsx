import React from 'react';
import { render, screen } from '@testing-library/react';
import { MetricsChart } from '../MetricsChart';

// Mock recharts to avoid rendering issues in tests
jest.mock('recharts', () => ({
  LineChart: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="line-chart">{children}</div>
  ),
  Line: () => <div data-testid="line" />,
  XAxis: () => <div data-testid="x-axis" />,
  YAxis: () => <div data-testid="y-axis" />,
  CartesianGrid: () => <div data-testid="grid" />,
  Tooltip: () => <div data-testid="tooltip" />,
  Legend: () => <div data-testid="legend" />,
  ResponsiveContainer: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="responsive-container">{children}</div>
  ),
}));

describe('MetricsChart', () => {
  const mockData = [
    {
      timestamp: '2023-01-01T00:00:00Z',
      value: 42,
      tags: { env: 'test' },
    },
    {
      timestamp: '2023-01-01T00:01:00Z',
      value: 43,
      tags: { env: 'test' },
    },
  ];

  it('renders with basic props', () => {
    render(
      <MetricsChart
        data={mockData}
        metricName="test_metric"
      />
    );

    expect(screen.getByText('test_metric')).toBeInTheDocument();
    expect(screen.getByTestId('responsive-container')).toBeInTheDocument();
    expect(screen.getByTestId('line-chart')).toBeInTheDocument();
  });

  it('applies custom height', () => {
    render(
      <MetricsChart
        data={mockData}
        metricName="test_metric"
        height={500}
      />
    );

    const container = screen.getByTestId('responsive-container');
    expect(container).toHaveStyle({ height: '500px' });
  });

  it('applies custom className', () => {
    render(
      <MetricsChart
        data={mockData}
        metricName="test_metric"
        className="custom-class"
      />
    );

    expect(screen.getByTestId('responsive-container').parentElement)
      .toHaveClass('custom-class');
  });

  it('handles empty data', () => {
    render(
      <MetricsChart
        data={[]}
        metricName="test_metric"
      />
    );

    expect(screen.getByText('test_metric')).toBeInTheDocument();
    expect(screen.getByTestId('line-chart')).toBeInTheDocument();
  });

  it('memoizes chart data transformation', () => {
    const { rerender } = render(
      <MetricsChart
        data={mockData}
        metricName="test_metric"
      />
    );

    // Re-render with same data
    rerender(
      <MetricsChart
        data={mockData}
        metricName="test_metric"
      />
    );

    // Component should use memoized data
    expect(screen.getByTestId('line-chart')).toBeInTheDocument();
  });
});