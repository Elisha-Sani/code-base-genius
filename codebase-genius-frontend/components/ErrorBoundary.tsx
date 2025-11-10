'use client';
import { Component, ReactNode } from 'react';

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
}

export default class ErrorBoundary extends Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): ErrorBoundaryState {
    return { hasError: true };
  }

  componentDidCatch(error: unknown, errorInfo: unknown) {
    // eslint-disable-next-line no-console
    console.error('ErrorBoundary caught an error', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback ?? (
          <div className="p-4 border rounded bg-red-100 text-red-700">
            Something went wrong while rendering this visualization.
          </div>
        )
      );
    }
    return this.props.children;
  }
}