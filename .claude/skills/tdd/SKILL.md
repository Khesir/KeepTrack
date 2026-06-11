---
name: tdd
description: >
  Test-driven development with red-green-refactor loop. Use when user wants
  to build features or fix bugs using TDD, mentions "red-green-refactor",
  wants integration tests, or asks for test-first development. Language-agnostic
  — applies to TypeScript, Python, Rust, Go, C++, and any other language.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not
implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through
public APIs. They describe _what_ the system does, not _how_ it does it. A good
test reads like a specification — "user can checkout with valid cart" tells you
exactly what capability exists. These tests survive refactors because they don't
care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators,
test private methods, or verify through external means (like querying a database
directly instead of using the interface). The warning sign: your test breaks
when you refactor, but behavior hasn't changed.

## Language and tooling

Before writing any tests, discover the project's test runner and conventions:

| Language | Common test runners | Config files |
|----------|-------------------|--------------|
| TypeScript / JavaScript | Jest, Vitest, Mocha | `jest.config.*`, `vitest.config.*`, `package.json` |
| Python | pytest, unittest | `pytest.ini`, `pyproject.toml` |
| Rust | Built-in (`cargo test`) | `Cargo.toml` |
| Go | Built-in (`go test`) | `go.mod` |
| C++ | Catch2, GoogleTest, doctest | `CMakeLists.txt`, `conanfile.txt` |

Use the project's existing test runner and file conventions — do not introduce
a new one. Look at existing test files to understand naming patterns, file
structure, and assertion style before writing anything.

## Anti-Pattern: Horizontal Slices

**Do NOT write all tests first, then all implementation.** This is "horizontal
slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces bad tests:
- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things rather than user-facing behavior
- Tests become insensitive to real changes

**Correct approach**: Vertical slices via tracer bullets. One test → one
implementation → repeat.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, use the project's domain glossary so that test
names and interface vocabulary match the project's language, and respect ADRs
in the area you're touching.

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for deep modules (small interface, deep implementation)
- [ ] Design interfaces for testability (accept dependencies, return results)
- [ ] List the behaviors to test — not implementation steps, behaviors
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most
important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors
matter most. Focus testing effort on critical paths and complex logic, not
every possible edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet — proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:
- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for refactor candidates:

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply relevant design principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## What makes a good test (language-agnostic)

**Good — tests observable behavior through public interface:**
```
# Pseudocode
test "user can checkout with valid cart":
  cart = create_cart()
  cart.add(product)
  result = checkout(cart, payment_method)
  assert result.status == "confirmed"
```

**Bad — tests implementation detail:**
```
# Pseudocode
test "checkout calls payment processor":
  mock = mock_internal(payment_processor)
  checkout(cart, payment)
  assert mock.was_called_with(cart.total)  # testing HOW, not WHAT
```

**Good — verifies through public interface:**
```
# Pseudocode
test "created user is retrievable":
  user = create_user(name: "Alice")
  retrieved = get_user(user.id)
  assert retrieved.name == "Alice"
```

**Bad — bypasses interface to verify:**
```
# Pseudocode
test "create_user saves to database":
  create_user(name: "Alice")
  row = db.raw_query("SELECT * FROM users WHERE name = 'Alice'")
  assert row exists  # bypasses the interface
```

## Mocking guidelines (language-agnostic)

Mock at **system boundaries** only:
- External APIs (payment providers, email services, third-party HTTP)
- Time and randomness
- File system (sometimes)
- Databases (prefer a real test DB where possible)

**Never mock your own modules or internal collaborators.** If you feel the need
to mock something you own, it's a signal the interface needs redesign.

**Design for mockability at boundaries:**

```
# GOOD — dependency injected, easy to mock at boundary
function process_payment(order, payment_client):
  return payment_client.charge(order.total)

# BAD — creates its own dependency, hard to mock
function process_payment(order):
  client = ExternalPaymentService(config.api_key)
  return client.charge(order.total)
```

## Checklist per cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Mocks only at system boundaries
```