---
name: slatejs
description: Build and debug rich text editors with Slate (slate, slate-react, slate-history). Use for custom schema design, element/leaf rendering, command + transform logic, normalization constraints, serialization/deserialization, paste handling, performance tuning, and collaborative editing integrations.
license: MIT
---

# Slate.js

Use this skill when implementing or fixing a Slate-based editor.

## Install

```bash
# required
npm install slate slate-react

# common optional packages
npm install slate-history slate-hyperscript
```

## Core model (must internalize)

- Slate data is plain JSON.
- `Editor` is the root.
- `Element` nodes contain children.
- `Text` nodes are leaves (`{ text: string, ...marks }`).
- You customize behavior by overriding editor methods in plugins (`withX(editor)`).

## Minimal, correct React setup

```tsx
import { useMemo } from "react";
import { createEditor, Descendant } from "slate";
import { Slate, Editable, withReact } from "slate-react";
import { withHistory } from "slate-history";

const initialValue: Descendant[] = [
  { type: "paragraph", children: [{ text: "Hello Slate" }] },
];

export function MyEditor() {
  // Keep editor instance stable.
  const editor = useMemo(() => withReact(withHistory(createEditor())), []);

  return (
    <Slate editor={editor} initialValue={initialValue}>
      <Editable placeholder="Type here..." />
    </Slate>
  );
}
```

### Important

- `withHistory` should be inside `withReact`:
  - ✅ `withReact(withHistory(createEditor()))`
- `initialValue` is initialization, not a fully controlled value prop.
- To replace content from outside Slate, update `editor.children` and call `editor.onChange()`.

## Rendering contract (critical)

When implementing `renderElement`, `renderLeaf`, or `renderText`:

1. Spread `attributes` on the **top-level DOM node**.
2. Render `children`.

If you don’t, selection/DOM translation behaviors break.

## Common custom rendering template

```tsx
const renderElement = useCallback((props) => {
  switch (props.element.type) {
    case "code":
      return (
        <pre {...props.attributes}>
          <code>{props.children}</code>
        </pre>
      );
    default:
      return <p {...props.attributes}>{props.children}</p>;
  }
}, []);

const renderLeaf = useCallback(({ attributes, children, leaf }) => {
  if (leaf.bold) children = <strong>{children}</strong>;
  if (leaf.italic) children = <em>{children}</em>;
  if (leaf.code) children = <code>{children}</code>;
  return <span {...attributes}>{children}</span>;
}, []);
```

## Command patterns you’ll reuse

```ts
import { Editor, Element as SlateElement, Transforms } from "slate";

export const CustomEditor = {
  isMarkActive(editor, key) {
    const marks = Editor.marks(editor);
    return marks ? marks[key] === true : false;
  },

  toggleMark(editor, key) {
    if (CustomEditor.isMarkActive(editor, key)) {
      Editor.removeMark(editor, key);
    } else {
      Editor.addMark(editor, key, true);
    }
  },

  toggleCodeBlock(editor) {
    const [match] = Editor.nodes(editor, {
      match: (n) => SlateElement.isElement(n) && n.type === "code",
    });

    Transforms.setNodes(
      editor,
      { type: match ? "paragraph" : "code" },
      { match: (n) => SlateElement.isElement(n) && Editor.isBlock(editor, n) }
    );
  },
};
```

## Plugin model (primary extension mechanism)

```ts
const withLinks = (editor) => {
  const { isInline, insertText, insertData } = editor;

  editor.isInline = (element) =>
    element.type === "link" ? true : isInline(element);

  editor.insertText = (text) => {
    // custom behavior
    insertText(text);
  };

  editor.insertData = (data) => {
    // custom paste behavior
    insertData(data);
  };

  return editor;
};
```

Common overrides:
- `isInline`
- `isVoid`
- `markableVoid`
- `normalizeNode`
- `insertText`
- `insertData`
- delete/insert commands (`deleteBackward`, `insertBreak`, etc.)

## Transforms: practical rules

Use `Transforms.*` for structural edits.

Key options:
- `at` (where)
- `match` (which nodes)
- `mode` (`highest`/`lowest`/`all` for some transforms)
- `voids` (include voids or not)

When combining multiple transforms that temporarily violate constraints, wrap in:

```ts
Editor.withoutNormalizing(editor, () => {
  // multiple transforms
});
```

## Normalization constraints (built in)

Slate enforces constraints like:
- Elements must have at least one text descendant.
- Mixed block + inline siblings are normalized.
- Inline placement rules are enforced.
- Root editor children must be blocks.
- Nodes must be JSON-serializable; avoid `undefined`/`null` pitfalls in model values.

For custom constraints, override `normalizeNode` and fix one issue at a time, then `return`.
Normalization is multi-pass.

## Void and inline gotchas

Void elements must:
- have an empty text child
- render `attributes` and `children`
- set `contentEditable={false}` (Firefox compatibility)

Inline elements are constrained by surrounding text placement rules; Slate may insert empty text nodes as spacers.

## Persistence / serialization

- Prefer storing Slate JSON as-is unless you have a strong reason not to.
- For change detection, ignore selection-only operations:

```ts
const isAstChange = editor.operations.some((op) => op.type !== "set_selection");
```

- For plain text export: `Node.string(...)` across top-level nodes.
- For HTML/Markdown, implement recursive serializers/deserializers.
- For HTML paste, override `insertData` and parse `text/html`.

## Event handling semantics (`Editable`)

When you pass custom handlers to `<Editable />`:
- `return true` => treat as handled; Slate skips its default handler.
- `return false` => Slate still runs default handler.
- `return undefined` => Slate decides based on `preventDefault` / propagation state.

## TypeScript pattern (recommended)

- Extend `CustomTypes` via module augmentation.
- `Editor` custom type should be based on `BaseEditor` (not `Editor`).
- Annotate `initialValue` as `Descendant[]`.
- Guard `Node` before `node.type` access:
  - `Element.isElement(node) && node.type === "paragraph"`

## Performance checklist

1. Memoize `renderElement`, `renderLeaf`, `renderText`, `decorate`, `renderChunk`.
2. Use `useSlateStatic` when you only need the editor instance.
3. Use `useSlateSelector` instead of broad `useSlate` in high-frequency components.
4. Keep normalization efficient; avoid deep scans on every change.
5. For huge documents, enable chunking:
   - implement `editor.getChunkSize = node => (Editor.isEditor(node) ? 1000 : null)`
   - provide `renderChunk`
   - consider `content-visibility: auto` on lowest chunks.

## Collaboration path (recommended)

For multiplayer editing, use Yjs integration packages (`@slate-yjs/core`, provider of choice):
- create shared Yjs doc/type
- compose editor with `withYjs` (and optional cursor plugin)
- connect/disconnect lifecycle correctly
- ensure editor always has valid initial child nodes

## Common failure checklist

- Selection/cursor weirdness after custom renderers → missing `attributes` or `children`.
- Marks not applying on collapsed selection as expected → inspect `editor.marks` behavior.
- `Property 'type' does not exist on type 'Node'` → missing `Element.isElement` guard.
- Pasting rich text becomes plain text → expected unless `insertData` handles `text/html`.
- Toolbar rerenders constantly → replace `useSlate` with `useSlateStatic`/`useSlateSelector`.
- Complex transform sequence causes unstable structure → wrap with `Editor.withoutNormalizing`.

## References

- Docs root: https://docs.slatejs.org/introduction.md
- Walkthroughs: https://docs.slatejs.org/walkthroughs/01-installing-slate.md
- Concepts: https://docs.slatejs.org/concepts/01-interfaces.md
- Transforms API: https://docs.slatejs.org/api/transforms.md
- Editor API: https://docs.slatejs.org/api/nodes/editor.md
- React integration: https://docs.slatejs.org/libraries/slate-react.md
- Performance guide: https://docs.slatejs.org/walkthroughs/09-performance.md
- Source repo: https://github.com/ianstormtaylor/slate
