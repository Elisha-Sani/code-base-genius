'use client';

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen text-center">
      <h2 className="text-2xl font-bold mb-4">Something went wrong</h2>
      <p className="mb-6 text-gray-600 dark:text-gray-300">{error.message}</p>
      <button
        onClick={() => reset()}
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
      >
        Try Again
      </button>
    </div>
  );
}