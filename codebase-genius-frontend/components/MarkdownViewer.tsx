'use client';

import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import rehypeHighlight from 'rehype-highlight';
import { ComponentPropsWithoutRef } from 'react';
import 'highlight.js/styles/github-dark.css'; // choose your theme

type CodeProps = ComponentPropsWithoutRef<'code'> & {
  inline?: boolean;
  node?: any;
};

export default function MarkdownViewer({ content }: { content: string }) {
  return (
    <article className="prose dark:prose-invert max-w-none">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeHighlight]}
        components={{
          code({ inline, className, children, ...props }: CodeProps) {
            if (!inline) {
              return (
                <pre className="relative">
                  <code className={className} {...props}>
                    {children}
                  </code>
                  <button
                    onClick={() =>
                      navigator.clipboard.writeText(String(children))
                    }
                    className="absolute top-2 right-2 text-xs bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded"
                  >
                    Copy
                  </button>
                </pre>
              );
            }
            return (
              <code className={className} {...props}>
                {children}
              </code>
            );
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </article>
  );
}