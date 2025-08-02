import React, { useMemo } from 'react';
import { Timeline } from 'react-vis';

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
        title: span.name,
        data: [
          {
            x: startTime,
            y: endTime - startTime,
            status: span.status,
            events: span.events,
            error: span.error
          }
        ]
      };
    });
  }, [spans]);

  return (
    <div className={`tracing-view ${className}`}>
      <h3 className="text-lg font-semibold mb-4">Trace Timeline</h3>
      <div className="border rounded-lg p-4">
        <Timeline
          data={timelineData}
          width={800}
          height={spans.length * 40 + 40}
          margin={{ left: 200, right: 20, top: 20, bottom: 20 }}
          getColor={d => d.status === 'error' ? '#ef4444' : '#3b82f6'}
          onValueClick={d => {
            if (d.events?.length > 0) {
              console.log('Span events:', d.events);
            }
            if (d.error) {
              console.error('Span error:', d.error);
            }
          }}
        />
      </div>
    </div>
  );
});

TracingView.displayName = 'TracingView';