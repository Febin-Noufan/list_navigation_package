import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Custom intents for actions
class ListNavigationIntent extends Intent {
  const ListNavigationIntent();
}

class MoveUpIntent extends ListNavigationIntent {
  const MoveUpIntent();
}

class EnterIntent extends ListNavigationIntent {
  const EnterIntent();
}

class MoveDownIntent extends ListNavigationIntent {
  const MoveDownIntent();
}

class HomeIntent extends ListNavigationIntent {
  const HomeIntent();
}

class EndIntent extends ListNavigationIntent {
  const EndIntent();
}

class PageUpIntent extends ListNavigationIntent {
  const PageUpIntent();
}

class PageDownIntent extends ListNavigationIntent {
  const PageDownIntent();
}

class DeleteIntent extends ListNavigationIntent {
  const DeleteIntent();
}

class EditIntent extends ListNavigationIntent {
  const EditIntent();
}

class CopyIntent extends ListNavigationIntent {
  const CopyIntent();
}

class KeyboardNavigableList<T> extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int, bool, bool) itemBuilder;
  final void Function(int index) onItemTap;
  final void Function(int index)? onDelete;
  final void Function(int index)? onEdit;
  final void Function(int index)? onCopy;
  final ScrollController? scrollController;
  final double itemExtent;
  final void Function(int)? onSelectedIndexChange;
  final String? emptyStateMessage;
  final Widget? loadingWidget;
  final bool isLoading;

  const KeyboardNavigableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onItemTap,
    this.onDelete,
    this.onEdit,
    this.onCopy,
    this.scrollController,
    this.itemExtent = 72.0,
    this.onSelectedIndexChange,
    this.emptyStateMessage,
    this.loadingWidget,
    this.isLoading = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _KeyboardNavigableListState createState() => _KeyboardNavigableListState<T>();
}

class _KeyboardNavigableListState<T> extends State<KeyboardNavigableList<T>> {
  int _focusedIndex = -1;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNode = FocusNode();
  }

  void _moveSelection(int delta) {
    if (widget.itemCount == 0) return;

    setState(() {
      _focusedIndex = (_focusedIndex + delta).clamp(0, widget.itemCount - 1);
    });

    widget.onSelectedIndexChange?.call(_focusedIndex);
    _scrollToIndex(_focusedIndex);
  }

  void _jumpToEdge(bool start) {
    setState(() {
      _focusedIndex = start ? 0 : widget.itemCount - 1;
    });

    widget.onSelectedIndexChange?.call(_focusedIndex);
    _scrollToIndex(_focusedIndex);
  }

  void _pageMove(bool down) {
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemsPerPage = (viewportHeight / widget.itemExtent).floor();
    _moveSelection(down ? itemsPerPage : -itemsPerPage);
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final itemOffset = index * widget.itemExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    double targetOffset =
        itemOffset - (viewportHeight / 2) + (widget.itemExtent / 2);
    targetOffset =
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleDelete() {
    if (widget.onDelete == null || _focusedIndex == -1) return;
    _showDeleteConfirmation(_focusedIndex);
  }

  void _handleEdit() {
    if (widget.onEdit != null && _focusedIndex != -1) {
      widget.onEdit!(_focusedIndex);
    }
  }

  void _handleCopy() {
    if (widget.onCopy != null && _focusedIndex != -1) {
      widget.onCopy!(_focusedIndex);
    }
  }

  void _showDeleteConfirmation(int index) {
    bool isNoSelected = true; // Default to "No"

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return KeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    setState(() {
                      isNoSelected = !isNoSelected;
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (isNoSelected) {
                      Navigator.of(context).pop();
                    } else {
                      widget.onDelete!(index);
                      Navigator.of(context).pop();
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Delete Item',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Content
                      const Text(
                        'Are you sure you want to delete this item?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Text(
                      //   'This action cannot be undone.',
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all(
                                isNoSelected
                                    ? const Color.fromARGB(255, 5, 5, 5)
                                    : const Color.fromARGB(230, 235, 230, 230),
                              ),
                              overlayColor: MaterialStateProperty.all(
                                Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color:
                                    isNoSelected ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Delete button
                          TextButton(
                            onPressed: () {
                              widget.onDelete!(index);
                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all(
                                !isNoSelected
                                    ? const Color.fromARGB(255, 18, 18, 18)
                                    : const Color.fromARGB(255, 245, 243, 243),
                              ),
                              overlayColor: MaterialStateProperty.all(
                                Colors.red.shade100,
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: !isNoSelected
                                    ? const Color.fromARGB(255, 248, 247, 247)
                                    : const Color.fromARGB(255, 4, 4, 4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<ShortcutActivator, Intent> get _shortcuts => {
        const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const MoveDownIntent(),
        const SingleActivator(LogicalKeyboardKey.home): const HomeIntent(),
        const SingleActivator(LogicalKeyboardKey.end): const EndIntent(),
        const SingleActivator(LogicalKeyboardKey.pageUp): const PageUpIntent(),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const PageDownIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const EnterIntent(),
        if (widget.onDelete != null)
          const SingleActivator(LogicalKeyboardKey.keyD, alt: true):
              const DeleteIntent(),
        if (widget.onEdit != null)
          const SingleActivator(LogicalKeyboardKey.keyE, alt: true):
              const EditIntent(),
        if (widget.onCopy != null)
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              const CopyIntent(),
      };

  // Update the actions map to include Enter action:
  Map<Type, Action<Intent>> get _actions => {
        MoveUpIntent: CallbackAction<MoveUpIntent>(
          onInvoke: (intent) => _moveSelection(-1),
        ),
        MoveDownIntent: CallbackAction<MoveDownIntent>(
          onInvoke: (intent) => _moveSelection(1),
        ),
        HomeIntent: CallbackAction<HomeIntent>(
          onInvoke: (intent) => _jumpToEdge(true),
        ),
        EndIntent: CallbackAction<EndIntent>(
          onInvoke: (intent) => _jumpToEdge(false),
        ),
        PageUpIntent: CallbackAction<PageUpIntent>(
          onInvoke: (intent) => _pageMove(false),
        ),
        PageDownIntent: CallbackAction<PageDownIntent>(
          onInvoke: (intent) => _pageMove(true),
        ),
        EnterIntent: CallbackAction<EnterIntent>(
          onInvoke: (intent) => _handleEnter(),
        ),
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (intent) => _handleDelete(),
        ),
        EditIntent: CallbackAction<EditIntent>(
          onInvoke: (intent) => _handleEdit(),
        ),
        CopyIntent: CallbackAction<CopyIntent>(
          onInvoke: (intent) => _handleCopy(),
        ),
      };

  void _handleEnter() {
    if (_focusedIndex != -1) {
      widget.onItemTap(_focusedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (widget.itemCount == 0) {
      return Center(
        child: Text(
          widget.emptyStateMessage ?? 'No items available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.itemCount,
            itemExtent: widget.itemExtent,
            itemBuilder: (context, index) {
              final isSelected = index == _focusedIndex;

              return InkWell(
                onTap: () {
                  setState(() {
                    _focusedIndex = index;
                  });
                  widget.onItemTap(index);
                },
                child:
                    widget.itemBuilder(context, index, isSelected, isSelected),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }
}
