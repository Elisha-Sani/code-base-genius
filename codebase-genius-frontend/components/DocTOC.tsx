'use client';
import { useEffect, useState } from 'react';

export default function DocTOC({ content }: { content: string }) {
  const [headings, setHeadings] = useState<{ level: number; text: string; id: string }[]>([]);

  useEffect(() => {
    const regex = /^(#{1,6})\s+(.*)$/gm;
    const matches = [...content.matchAll(regex)];
    setHeadings(matches.map(m => ({
      level: m[1].length,
      text: m[2],
      id: m[2].toLowerCase().replace(/\s+/g, '-'),
    })));
  }, [content]);

  return (
    <nav className="sticky top-4 space-y-2">
      <h3 className="font-bold">Contents</h3>
      <ul className="space-y-1 text-sm">
        {headings.map(h => (
          <li key={h.id} className={`ml-${h.level * 2}`}>
            <a href={`#${h.id}`} className="hover:underline">{h.text}</a>
          </li>
        ))}
      </ul>
    </nav>
  );
}