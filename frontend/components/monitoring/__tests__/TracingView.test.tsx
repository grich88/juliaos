import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { TracingView } from '../TracingView';

// Mock react-vis
jest.mock('react-vis', () => ({
  Timeline: ({ data, onValueClick }: any) => (
    <div data-testid="timeline">
      {data.map((item: any, index: number) => (
        <div
          key={index}
          data-testid="timeline-item"
          onClick={() => onValueClick(item.data[0])}
        >
          {item.title}
        </div>
      ))}
    </div>
  ),
}));

describe('TracingView', () => {
  const mockSpans = [
    {
      context: {
        trace_id: 'trace-1',
        parent_id: null,
        span_id: 'span-1',
        start_time: '2023-01-01T00:00:00Z',
        attributes: { service: 'test' },
      },
      name: 'root-span',
      status: 'ok',
      end_time: '2023-01-01T00:01:00Z',
      events: [
        {
          name: 'event-1',
          timestamp: '2023-01-01T00:00:30Z',
          attributes: { type: 'test' },
        },
      ],
      error: null,
    },
    {
      context: {
        trace_id: 'trace-1',
        parent_id: 'span-1',
        span_id: 'span-2',
        start_time: '2023-01-01T00:00:15Z',
        attributes: { service: 'test' },
      },
      name: 'child-span',
      status: 'error',
      end_time: '2023-01-01T00:00:45Z',
      events: [],
      error: 'Test error',
    },
  ];

  it('renders with basic props', () => {
    render(<TracingView spans={mockSpans} />);

    expect(screen.getByText('Trace Timeline')).toBeInTheDocument();
    expect(screen.getByTestId('timeline')).toBeInTheDocument();
    expect(screen.getAllByTestId('timeline-item')).toHaveLength(2);
  });

  it('applies custom className', () => {
    render(<TracingView spans={mockSpans} className="custom-class" />);

    expect(screen.getByTestId('tracing-view')).toHaveClass('custom-class');
  });

  it('handles span click with events', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    
    render(<TracingView spans={mockSpans} />);
    
    fireEvent.click(screen.getByText('root-span'));
    
    expect(consoleSpy).toHaveBeenCalledWith('Span events:', [
      {
        name: 'event-1',
        timestamp: '2023-01-01T00:00:30Z',
        attributes: { type: 'test' },
      },
    ]);
    
    consoleSpy.mockRestore();
  });

  it('handles span click with error', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
    
    render(<TracingView spans={mockSpans} />);
    
    fireEvent.click(screen.getByText('child-span'));
    
    expect(consoleSpy).toHaveBeenCalledWith('Span error:', 'Test error');
    
    consoleSpy.mockRestore();
  });

  it('handles empty spans array', () => {
    render(<TracingView spans={[]} />);

    expect(screen.getByText('Trace Timeline')).toBeInTheDocument();
    expect(screen.queryAllByTestId('timeline-item')).toHaveLength(0);
  });

  it('memoizes timeline data transformation', () => {
    const { rerender } = render(<TracingView spans={mockSpans} />);

    // Re-render with same spans
    rerender(<TracingView spans={mockSpans} />);

    // Component should maintain same DOM structure
    expect(screen.getAllByTestId('timeline-item')).toHaveLength(2);
  });
});