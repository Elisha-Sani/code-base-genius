'use client';

export default function GlobalError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <html>
      <body className="flex flex-col items-center justify-center min-h-screen text-center bg-gray-50 dark:bg-gray-900">
        <h2 className="text-2xl font-bold mb-4 text-red-600">Critical Error</h2>
        <p className="mb-6 text-gray-700 dark:text-gray-300">{error.message}</p>
        <button
          onClick={() => reset()}
          className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
        >
          Reload App
        </button>
      </body>
    </html>
  );
}