import React, { useMemo } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

interface TraceEvent {
  name: string;
  timestamp: string;
  attributes: Record<string, any>;
}

interface TraceSpan {
  context: {
    trace_id: string;
    parent_id: string | null;
    span_id: string;
    start_time: string;
    attributes: Record<string, any>;
  };
  name: string;
  status: 'ok' | 'error';
  end_time: string | null;
  events: TraceEvent[];
  error: string | null;
}

interface TracingViewProps {
  spans: TraceSpan[];
  className?: string;
}

export const TracingView = React.memo(function TracingView({
  spans,
  className = ''
}: TracingViewProps) {
  const timelineData = useMemo(() => {
    return spans.map(span => {
      const startTime = new Date(span.context.start_time).getTime();
      const endTime = span.end_time ? new Date(span.end_time).getTime() : Date.now();
      
      return {
        name: span.name,
        duration: endTime - startTime,
        status: span.status,
        events: span.events,
        error: span.error
      };
    });
  }, [spans]);

  return (
    <div className={`tracing-view ${className}`}>
      <h3 className="text-lg font-semibold mb-4">Trace Timeline</h3>
      <div className="border rounded-lg p-4">
        <BarChart
          width={800}
          height={spans.length * 40 + 40}
          data={timelineData}
          layout="vertical"
          margin={{ top: 20, right: 30, left: 200, bottom: 20 }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis type="number" />
          <YAxis dataKey="name" type="category" width={180} />
          <Tooltip 
            content={({ payload }) => {
              if (!payload?.length) return null;
              const data = payload[0].payload;
              return (
                <div className="bg-white p-2 border rounded shadow">
                  <p><strong>{data.name}</strong></p>
                  <p>Duration: {data.duration}ms</p>
                  {data.error && <p className="text-red-500">Error: {data.error}</p>}
                  {data.events?.length > 0 && (
                    <p>Events: {data.events.length}</p>
                  )}
                </div>
              );
            }}
          />
          <Bar 
            dataKey="duration" 
            fill={(data) => data.status === 'error' ? '#ef4444' : '#3b82f6'}
            onClick={(data) => {
              if (data.events?.length > 0) {
                console.log('Span events:', data.events);
              }
              if (data.error) {
                console.error('Span error:', data.error);
              }
            }}
          />
        </BarChart>
      </div>
    </div>
  );
});

TracingView.displayName = 'TracingView';