# Contributing to Keep Track

First off, thank you for considering contributing to Keep Track! It's people like you that make Keep Track such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [What Should I Know Before I Get Started?](#what-should-i-know-before-i-get-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Your First Code Contribution](#your-first-code-contribution)
  - [Pull Requests](#pull-requests)
- [Style Guides](#style-guides)
  - [Git Commit Messages](#git-commit-messages)
  - [Dart Style Guide](#dart-style-guide)
  - [Documentation Style Guide](#documentation-style-guide)
- [Additional Notes](#additional-notes)

## Code of Conduct

This project and everyone participating in it is governed by the [Keep Track Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [project email].

## What Should I Know Before I Get Started?

### Project Architecture

Keep Track follows Clean Architecture principles with a feature-based organization:

- **Core Layer**: Contains framework-agnostic business logic
- **Feature Modules**: Self-contained features with their own domain, data, and presentation layers
- **Shared Code**: Cross-cutting concerns and utilities

### Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: Custom StreamState implementation
- **Dependency Injection**: Custom DI system
- **Architecture**: Clean Architecture with Repository pattern

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Use the bug report template** and include:
- A clear and descriptive title
- Exact steps to reproduce the problem
- Expected behavior vs actual behavior
- Screenshots (if applicable)
- Your environment (OS, Flutter version, etc.)
- Any relevant logs or error messages

#### Example Bug Report

```markdown
**Describe the bug**
Tasks are not syncing to the server when offline mode is enabled.

**To Reproduce**
1. Enable offline mode in settings
2. Create a new task
3. Wait for sync
4. Check server - task is not present

**Expected behavior**
Task should sync once connection is restored.

**Environment:**
- OS: Windows 11
- App Version: 1.2.0
- Flutter: 3.19.0

**Additional context**
Error in console: "Sync queue failed: Connection timeout"
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most users
- **List any alternative solutions** you've considered
- **Include mockups or examples** if applicable

#### Example Enhancement Suggestion

```markdown
**Is your feature request related to a problem?**
I often need to share project progress with my team, but there's no easy way to export.

**Describe the solution you'd like**
Add an "Export Project" button that generates a PDF report with:
- Project overview
- Task completion status
- Time spent on tasks
- Budget summary

**Describe alternatives you've considered**
- Manual screenshot and sharing
- Copy-pasting into a document

**Additional context**
Similar to how Trello exports boards.
```

### Your First Code Contribution

Unsure where to begin? You can start by looking through these issues:

- **Good First Issue**: Issues labeled `good-first-issue` - should only require a few lines of code
- **Help Wanted**: Issues labeled `help-wanted` - more involved but great for learning

#### Local Development Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/KeepTrack.git
   cd KeepTrack
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/Khesir/KeepTrack.git
   ```

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Set up Supabase** (see README.md for detailed instructions)

6. **Create a branch**:
   ```bash
   git checkout -b feature/my-new-feature
   ```

7. **Make your changes** and test thoroughly

8. **Run tests**:
   ```bash
   flutter test
   ```

9. **Format code**:
   ```bash
   dart format .
   ```

10. **Analyze code**:
    ```bash
    flutter analyze
    ```

### Pull Requests

1. **Ensure your branch is up to date**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**:
   ```bash
   git push origin feature/my-new-feature
   ```

3. **Open a Pull Request** from your fork to the main repository

4. **Fill in the PR template** with all required information

5. **Link relevant issues** using keywords (Fixes #123, Resolves #456)

6. **Wait for review** - maintainers will review your PR and may request changes

#### Pull Request Guidelines

- **One feature per PR** - Keep PRs focused and atomic
- **Write clear commit messages** - Follow the commit message guidelines
- **Add tests** - All new features should have tests
- **Update documentation** - Update README, comments, and docs as needed
- **Follow coding standards** - Use the style guides below
- **No breaking changes** - Unless discussed and approved first

#### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## How Has This Been Tested?
Describe the tests you ran

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Screenshots (if applicable)
Add screenshots to demonstrate the changes

## Related Issues
Fixes #(issue number)
```

## Style Guides

### Git Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that don't affect code meaning (formatting, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Changes to build process, dependencies, etc.

**Examples:**

```bash
feat(tasks): add ability to set recurring tasks

- Add RecurrencePattern model
- Update task creation UI
- Add recurrence calculation logic

Closes #123
```

```bash
fix(auth): resolve login timeout on slow connections

Increase timeout from 5s to 15s and add retry logic

Fixes #456
```

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

**DO:**
- Use `lowerCamelCase` for variable names
- Use `UpperCamelCase` for class names
- Use `lowercase_with_underscores` for file names
- Format code with `dart format`
- Use `const` constructors when possible
- Document all public APIs

**DON'T:**
- Use `var` when the type is not obvious
- Create overly long methods (> 50 lines)
- Ignore analyzer warnings

**Example:**

```dart
/// Manages task state and operations.
///
/// This controller handles CRUD operations for tasks and maintains
/// the current state using StreamState.
class TaskController extends StreamState<List<Task>> {
  final TaskRepository _repository;

  TaskController({
    required TaskRepository repository,
  }) : _repository = repository;

  /// Creates a new task with the given [title] and [priority].
  Future<void> createTask({
    required String title,
    required TaskPriority priority,
  }) async {
    try {
      final task = Task(
        id: const Uuid().v4(),
        title: title,
        priority: priority,
        createdAt: DateTime.now(),
      );

      await _repository.create(task);
      await refresh();
    } catch (e) {
      setError('Failed to create task: $e');
    }
  }
}
```

### Documentation Style Guide

**Code Comments:**
- Use `///` for public API documentation
- Use `//` for inline comments
- Explain **why**, not **what** (code should be self-explanatory)

**README Updates:**
- Keep it concise and scannable
- Use headers and lists
- Include code examples
- Update the Table of Contents

**Commit Messages:**
- First line: < 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- Reference issues and PRs

## Additional Notes

### Issue and Pull Request Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements or additions to documentation
- `good-first-issue`: Good for newcomers
- `help-wanted`: Extra attention is needed
- `question`: Further information is requested
- `wontfix`: This will not be worked on
- `duplicate`: This issue or pull request already exists
- `invalid`: This doesn't seem right

### Community

- Join our [Discord server](https://discord.gg/yourserver)
- Follow us on [Twitter](https://twitter.com/yourhandle)
- Check out [GitHub Discussions](https://github.com/Khesir/KeepTrack/discussions)

### Getting Help

If you need help:
1. Check the [documentation](./docs)
2. Search [existing issues](https://github.com/Khesir/KeepTrack/issues)
3. Ask in [Discussions](https://github.com/Khesir/KeepTrack/discussions)
4. Join our [Discord](https://discord.gg/yourserver)

---

**Thank you for contributing to Keep Track! 🎉**

Your contributions make this project better for everyone.
