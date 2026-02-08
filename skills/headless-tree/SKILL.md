---
name: headless-tree
description: Build and debug tree UIs with @headless-tree/core and @headless-tree/react. Use for sync/async data loaders, feature wiring, drag-and-drop (including foreign and keyboard DnD), hotkeys, search, renaming, checkboxes, state control, performance tuning, virtualization, and React Compiler compatibility.
license: MIT
---

# Headless Tree

Use this skill when implementing or fixing file trees / hierarchical explorers with Headless Tree.

## Install

```bash
# npm
npm install @headless-tree/core @headless-tree/react

# pnpm
pnpm add @headless-tree/core @headless-tree/react

# bun
bun add @headless-tree/core @headless-tree/react
```

## Core rules (do these every time)

1. **Always provide** `rootItemId`, `getItemName`, `isItemFolder`, and a data loader.
2. **Always include needed features explicitly** in `features: []`.
   - TypeScript shows all methods, but runtime behavior exists only if feature is imported.
3. **Always spread props**:
   - `tree.getContainerProps()` on the tree container
   - `item.getProps()` on each item element
4. For DnD, set `indent` and render a drag line with `tree.getDragLineStyle()`.

## Minimal sync template

```tsx
import {
  hotkeysCoreFeature,
  selectionFeature,
  syncDataLoaderFeature,
} from "@headless-tree/core";
import { useTree } from "@headless-tree/react";

const tree = useTree<MyNode>({
  rootItemId: "root",
  getItemName: (item) => item.getItemData().name,
  isItemFolder: (item) => item.getItemData().isFolder,
  dataLoader: {
    getItem: (id) => data[id],
    getChildren: (id) => data[id].children ?? [],
  },
  indent: 20,
  features: [syncDataLoaderFeature, selectionFeature, hotkeysCoreFeature],
});

return (
  <div {...tree.getContainerProps()}>
    {tree.getItems().map((item) => (
      <button
        key={item.getKey()}
        {...item.getProps()}
        style={{ paddingLeft: `${item.getItemMeta().level * 20}px` }}
      >
        {item.getItemName()}
      </button>
    ))}
  </div>
);
```

## Async data loader rules

Use `asyncDataLoaderFeature` when data fetching is async or expensive.

- Implement `dataLoader.getItem` + `dataLoader.getChildren`, or `getChildrenWithData`
- Provide `createLoadingItemData`
- Invalidate/update cache via item methods:
  - `item.invalidateItemData(optimistic?)`
  - `item.invalidateChildrenIds(optimistic?)`
  - `item.updateCachedData(data)`
  - `item.updateCachedChildrenIds(ids)`
- Load non-mounted items if needed:
  - `tree.loadItemData(itemId)`
  - `tree.loadChildrenIds(itemId)`

## Feature dependency map

- **Core (always on):** Tree Core + Main Feature
- `syncDataLoaderFeature` / `asyncDataLoaderFeature`: data access
- `selectionFeature`: multi-select (`item.select`, `item.toggleSelect`, etc.)
- `hotkeysCoreFeature`: required for all keyboard shortcuts
- `dragAndDropFeature`: mouse DnD
- `keyboardDragAndDropFeature`: keyboard DnD (requires `dragAndDropFeature` + `hotkeysCoreFeature`)
- `searchFeature`: typeahead-like search (`tree.openSearch`, `tree.getSearchInputElementProps`)
- `renamingFeature`: rename flow (`item.startRenaming`, `item.getRenameInputProps`)
- `checkboxesFeature`: checkbox selection (`item.getCheckboxProps`)
- `expandAllFeature`: expand/collapse all APIs
- `propMemoizationFeature`: stable prop references for memoized renderers

## Drag-and-drop implementation recipe

### In-tree moves

- Configure:
  - `canReorder` (true for line/in-between drops)
  - `onDrop`
- Prefer utility handler:

```ts
import { createOnDropHandler } from "@headless-tree/core";

onDrop: createOnDropHandler((parentItem, newChildrenIds) => {
  myData[parentItem.getId()].children = newChildrenIds;
});
```

Utilities available:
- `createOnDropHandler`
- `removeItemsFromParents`
- `insertItemsAtTarget`
- `isOrderedDragTarget`

### Foreign drag objects (in/out of tree)

- Outbound: `createForeignDragObject`
- Inbound allow/visualize: `canDropForeignDragObject`, `canDragForeignDragObjectOver`
- Inbound drop: `onDropForeignDragObject`
- Outbound completion: `onCompleteForeignDrop`

### DnD customization knobs

- `canDrag(items)`
- `canDrop(items, target)`
- `openOnDropDelay`
- `draggedItemOverwritesSelection`
- `setDragImage(...)`
- `seperateDragHandle: true` + `item.getDragHandleProps()`

## Search / renaming / checkboxes

- **Search:** render input only when `tree.isSearchOpen()` and spread `tree.getSearchInputElementProps()`.
- **Renaming:** if `item.isRenaming()`, render input with `item.getRenameInputProps()`.
- **Checkboxes:** render `<input type="checkbox" {...item.getCheckboxProps()} />`.
  - `propagateCheckedState` can recursively affect descendants.
  - In async trees, propagation may trigger loading of descendants.

## State management patterns

Headless Tree supports 3 patterns:

1. **Internal state** (default), optional `initialState`
2. **Partial controlled state** (`state: { selectedItems }` + `setSelectedItems`)
3. **Fully controlled state** (`state` + `setState`)

For external data mutations:
- **Sync loader:** mutate data, then `tree.rebuildTree()`
- **Async loader:** invalidate/update cache; rebuild as needed
- If your tree data lives in React state, prefer `tree.scheduleRebuildTree()` after state updates

## Performance and scale

- Add `propMemoizationFeature` + memoized row component (`React.memo`) for expensive item renderers.
- Virtualize with flat items from `tree.getItems()` (e.g. TanStack Virtual).
- For very large trees, consider `instanceBuilder: buildProxiedInstance`.
  - Caveat: method identities on item instances are not stable in proxied mode.

## Accessibility + keyboard DnD

- ARIA props are generated by `getContainerProps` / `getProps`.
- Include `hotkeysCoreFeature` for keyboard navigation.
- For keyboard DnD, include `keyboardDragAndDropFeature` and render:

```tsx
import { AssistiveTreeDescription } from "@headless-tree/react";

<AssistiveTreeDescription tree={tree} />
```

## React Compiler compatibility

Two safe options:

1. Import from `@headless-tree/react/react-compiler` and call `tree()` each access.
2. Add `"use no memo";` in components using normal `useTree`.

## Plugins / custom behavior

Use `FeatureImplementation` to extend/override behavior.

- Later features override earlier ones.
- Use `prev?.()` to compose prior behavior.
- `feature.overwrites` can enforce order.
- You can override click behavior, props, rename logic, checkbox logic, etc.

## Non-React integrations

If using `createTree` directly:

- call once: `createTree(...)`
- on mount: `tree.setMounted(true)` + `tree.rebuildTree()`
- on config change: `tree.setConfig(...)`
- on unmount: `tree.setMounted(false)`
- remap React-style prop names if your framework needs different names

## Common failure checklist

- Methods present in TS but not working at runtime → missing feature import.
- Tree not keyboard-focusable / hotkeys not firing → missing `hotkeysCoreFeature` or container not focused.
- DnD looks broken → missing `indent`, missing drag line render, or missing `canReorder` for ordered drops.
- Async updates not reflected → cache not invalidated/updated.
- Sync external mutations not reflected → forgot `tree.rebuildTree()`.
- Search/rename not visible → inputs not rendered by consumer.

## Official docs

- Start: https://headless-tree.lukasbach.com/llm/getstarted.md
- Features: https://headless-tree.lukasbach.com/llm/features/overview.md
- DnD: https://headless-tree.lukasbach.com/llm/dnd/overview.md
- State: https://headless-tree.lukasbach.com/llm/guides/state.md
- Hotkeys: https://headless-tree.lukasbach.com/llm/guides/hotkeys.md
- Performance: https://headless-tree.lukasbach.com/llm/recipe/virtualization.md
- React Compiler: https://headless-tree.lukasbach.com/llm/guides/react-compiler.md
