/// Reusable error widgets for consistent UI
library;

import 'package:flutter/material.dart';
import 'failure.dart';
import 'error_handler.dart';

/// Standard error display widget
class ErrorDisplay extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final bool showDetails;

  const ErrorDisplay({
    super.key,
    required this.failure,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              _getIconForFailure(failure),
              size: 64,
              color: _getColorForFailure(failure),
            ),
            const SizedBox(height: 16),

            // Error title
            Text(
              ErrorHandler.getErrorTitle(failure),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error message
            Text(
              failure.userMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),

            // Show technical details in debug mode
            if (showDetails && failure.originalError != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      failure.technicalDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Retry button
            if (failure.isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForFailure(Failure failure) {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off,
      ServerFailure() => Icons.cloud_off,
      NotFoundFailure() => Icons.search_off,
      UnauthorizedFailure() => Icons.lock,
      ForbiddenFailure() => Icons.block,
      ValidationFailure() => Icons.warning,
      TimeoutFailure() => Icons.schedule,
      _ => Icons.error_outline,
    };
  }

  Color _getColorForFailure(Failure failure) {
    return switch (failure) {
      NetworkFailure() => Colors.orange,
      ServerFailure() => Colors.red,
      ValidationFailure() => Colors.amber,
      UnauthorizedFailure() => Colors.blue,
      _ => Colors.red,
    };
  }
}

/// Compact error card for inline display
class ErrorCard extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorCard({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ErrorHandler.getErrorTitle(failure),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    failure.userMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (failure.isRetryable && onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                color: Colors.red.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error banner for top of screen
class ErrorBanner extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const ErrorBanner({
    super.key,
    required this.failure,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Colors.red.shade100,
      content: Text(
        failure.userMessage,
        style: TextStyle(color: Colors.red.shade900),
      ),
      leading: Icon(Icons.error_outline, color: Colors.red.shade700),
      actions: [
        if (failure.isRetryable && onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('RETRY'),
          ),
        TextButton(
          onPressed: onDismiss,
          child: const Text('DISMISS'),
        ),
      ],
    );
  }

  /// Show banner at top of screen
  static void show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.red.shade100,
        content: Text(
          failure.userMessage,
          style: TextStyle(color: Colors.red.shade900),
        ),
        leading: Icon(Icons.error_outline, color: Colors.red.shade700),
        actions: [
          if (failure.isRetryable && onRetry != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                onRetry();
              },
              child: const Text('RETRY'),
            ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}

/// Show error dialog
void showErrorDialog(
  BuildContext context,
  Failure failure, {
  VoidCallback? onRetry,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(ErrorHandler.getErrorTitle(failure)),
      content: Text(failure.userMessage),
      actions: [
        if (failure.isRetryable && onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Show error snackbar
void showErrorSnackBar(
  BuildContext context,
  Failure failure, {
  VoidCallback? onRetry,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failure.userMessage),
      backgroundColor: Colors.red.shade700,
      action: failure.isRetryable && onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}
