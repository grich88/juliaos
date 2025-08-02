import React, { useMemo } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';

interface MetricPoint {
  timestamp: string;
  value: number;
  tags: Record<string, string>;
}

interface MetricsChartProps {
  data: MetricPoint[];
  metricName: string;
  height?: number;
  className?: string;
}

export const MetricsChart = React.memo(function MetricsChart({
  data,
  metricName,
  height = 300,
  className = ''
}: MetricsChartProps) {
  const chartData = useMemo(() => {
    return data.map(point => ({
      timestamp: new Date(point.timestamp).toLocaleTimeString(),
      value: point.value,
      ...point.tags
    }));
  }, [data]);

  return (
    <div className={`metrics-chart ${className}`}>
      <h3 className="text-lg font-semibold mb-2">{metricName}</h3>
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="timestamp" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line
            type="monotone"
            dataKey="value"
            stroke="#8884d8"
            activeDot={{ r: 8 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
});

MetricsChart.displayName = 'MetricsChart';