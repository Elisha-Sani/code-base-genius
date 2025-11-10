// app/layout.tsx
import './globals.css';
import { Toaster } from 'react-hot-toast';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
        <header className="border-b border-gray-200 dark:border-gray-700 p-4 flex justify-between items-center">
          <h1 className="text-xl font-bold">Codebase Genius</h1>
        </header>
        <main className="max-w-6xl mx-auto p-6">{children}</main>
        <Toaster position="top-right" />
      </body>
    </html>
  );
}