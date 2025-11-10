'use client';

import { useEffect, useRef } from 'react';
import toast from 'react-hot-toast';
import mermaid from 'mermaid';

type MermaidRenderResult =
  | string
  | {
      svg: string;
      bindFunctions?: (element: Element) => void;
    };

export default function MermaidDiagram({ diagram }: { diagram: string }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    mermaid.initialize({ startOnLoad: false, theme: 'default' });

    if (ref.current) {
      mermaid
        .render('graphDiv', diagram)
        .then((result: MermaidRenderResult) => {
          const svgCode = typeof result === 'string' ? result : result.svg;
          const bindFunctions =
            typeof result === 'string' ? undefined : result.bindFunctions;

          if (ref.current) {
            ref.current.innerHTML = svgCode;
            if (bindFunctions) bindFunctions(ref.current);
          }
        })
        .catch((err: unknown) => {
          // eslint-disable-next-line no-console
          console.error('Mermaid render error:', err);
          toast.error('Diagram failed to render');
        });
    }
  }, [diagram]);

  return <div ref={ref} className="border rounded p-4 bg-white dark:bg-gray-900" />;
}