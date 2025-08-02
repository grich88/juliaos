import React from 'react';
import { CheckCircleIcon, ExclamationCircleIcon, XCircleIcon } from '@heroicons/react/24/solid';

interface HealthStatusProps {
  status: 'HEALTHY' | 'DEGRADED' | 'UNHEALTHY';
  message: string;
  details: Record<string, any>;
  className?: string;
}

export const HealthStatus = React.memo(function HealthStatus({
  status,
  message,
  details,
  className = ''
}: HealthStatusProps) {
  const statusConfig = {
    HEALTHY: {
      icon: CheckCircleIcon,
      color: 'text-green-500',
      bgColor: 'bg-green-50',
      borderColor: 'border-green-200'
    },
    DEGRADED: {
      icon: ExclamationCircleIcon,
      color: 'text-yellow-500',
      bgColor: 'bg-yellow-50',
      borderColor: 'border-yellow-200'
    },
    UNHEALTHY: {
      icon: XCircleIcon,
      color: 'text-red-500',
      bgColor: 'bg-red-50',
      borderColor: 'border-red-200'
    }
  };

  const config = statusConfig[status];
  const Icon = config.icon;

  return (
    <div className={`health-status p-4 rounded-lg border ${config.bgColor} ${config.borderColor} ${className}`}>
      <div className="flex items-center mb-2">
        <Icon className={`w-6 h-6 ${config.color} mr-2`} />
        <h3 className={`text-lg font-semibold ${config.color}`}>{status}</h3>
      </div>
      <p className="text-gray-700 mb-4">{message}</p>
      <div className="grid grid-cols-2 gap-4">
        {Object.entries(details).map(([key, value]) => (
          <div key={key} className="text-sm">
            <span className="font-medium text-gray-600">{key}: </span>
            <span className="text-gray-800">
              {typeof value === 'object' ? JSON.stringify(value) : String(value)}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
});

HealthStatus.displayName = 'HealthStatus';