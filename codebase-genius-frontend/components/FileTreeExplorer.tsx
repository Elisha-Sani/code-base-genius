'use client';
import { useState } from 'react';

type TreeNode = { name: string; type: 'file'|'dir'; children?: TreeNode[] };

export default function FileTreeExplorer({ tree }: { tree: TreeNode }) {
  return (
    <ul className="font-mono text-sm">
      <TreeNodeItem node={tree} />
    </ul>
  );
}

function TreeNodeItem({ node }: { node: TreeNode }) {
  const [open, setOpen] = useState(false);

  if (node.type === 'dir') {
    return (
      <li>
        <button onClick={() => setOpen(!open)} className="font-bold">
          {open ? '📂' : '📁'} {node.name}
        </button>
        {open && node.children && (
          <ul className="ml-4">
            {node.children.map((child, i) => (
              <TreeNodeItem key={i} node={child} />
            ))}
          </ul>
        )}
      </li>
    );
  }
  return <li>📄 {node.name}</li>;
}