1. Nix owns software.
2. Lua owns editor behavior.
3. Stable nvim and nvim-next have different release semantics.


nvim
→ immutable configuration
→ fully Nix-managed
→ production

nvim-next
→ mutable working-tree Lua
→ isolated state
→ experimentation

