'use client';
import { useEffect, useState } from 'react';

export default function DarkModeToggle() {
  const [dark, setDark] = useState(false);

  useEffect(() => {
    const root = document.documentElement;
    if (dark) root.classList.add('dark');
    else root.classList.remove('dark');
  }, [dark]);

  return (
    <button
      onClick={() => setDark(!dark)}
      className="px-3 py-1 rounded bg-gray-200 dark:bg-gray-800"
    >
      {dark ? '🌙 Dark' : '☀️ Light'}
    </button>
  );
}