# Contributing to BuilderKit

Thanks for your interest in improving BuilderKit!

## Getting Started

1. **Fork & clone** the repo
2. Install [Rojo](https://rojo.space) for Studio sync
3. Run `rojo serve` to test in Studio

## Development Workflow

```bash
rojo serve
```

### Running Tests

Tests live in `spec/` and use [TestEZ](https://github.com/Roblox/testez) format.

### Code Style

- **Luau type annotations** on all public functions
- **Doc comments** on all exported APIs and command types
- **camelCase** for functions
- Every `create*` function must call `prepareBasePart()` for consistent property handling
- All created instances must be tagged with `CollectionService:AddTag(part, BUILT_TAG)`
- Use `pcall` around risky Roblox API calls (e.g. `Enum.Material[mat]`)

## Adding a New Command Type

1. Implement the function: `function BuilderKit.createNewThing(params) ... end`
2. Add it to `commandMap`: `newThing = BuilderKit.createNewThing`
3. Add batch-mode support via `prepareBasePart()` if it creates BaseParts
4. Write tests for valid params, missing params, and invalid types
5. Document in the README's command table
6. Add a demo in `examples/`

## Error Handling Philosophy

BuilderKit wraps all command dispatch in `pcall`. Failures are caught, warned, and returned as `(nil, errorString)`. The caller decides what to do with errors — BuilderKit never silently swallows them.

## Submitting Changes

1. Feature branch: `git checkout -b feat/your-feature`
2. Test with valid and invalid command structures
3. Open a PR

## Reporting Bugs

Include:
- The command type and params
- Whether it was called via `execute()` or `executeBatch()`
- The error message from the return value
- Whether BuildAnimator was present as a sibling

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
