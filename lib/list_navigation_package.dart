import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:list_navigation_package/intents.dart';

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
  final String Function(int index) getItemString;
  final VoidCallback? onEscapeDoubleTap;
   final VoidCallback? onEscapeSingleTap;

  /// Optional separator builder.  If null, no separator is displayed.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Optional padding for the inner ListView.
  final EdgeInsets? padding;

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
    required this.getItemString, // Add this new property
    this.separatorBuilder,
    this.padding,
    this.onEscapeDoubleTap,
    this.onEscapeSingleTap,
  });

  @override
  // ignore: library_private_types_in_public_api
  _KeyboardNavigableListState createState() => _KeyboardNavigableListState<T>();
}

class _KeyboardNavigableListState<T> extends State<KeyboardNavigableList<T>> {
  int _focusedIndex = -1;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  String _quickTypeBuffer = '';
  Timer? _quickTypeTimer;
  Timer? _escapeTimer;

  static const _quickTypeDuration = Duration(milliseconds: 500);
  static const _escapeDoubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNode = FocusNode();
      if (widget.itemCount > 0) {
      _focusedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectedIndexChange?.call(_focusedIndex);
        _scrollToIndex(_focusedIndex);
      });
    }
  }

  void _handleCharacterKey(String character) {
    if (widget.itemCount == 0) return;

    // Handle quick typing
    if (_quickTypeTimer?.isActive ?? false) {
      // Quick typing in progress - add to buffer
      _quickTypeTimer?.cancel();
      _quickTypeBuffer += character.toLowerCase();

      // Set timer to clear buffer
      _quickTypeTimer = Timer(_quickTypeDuration, () {
        setState(() {
          _quickTypeBuffer = '';
        });
      });

      // Search for quick type match
      int startIndex = 0;
      for (int i = 0; i < widget.itemCount; i++) {
        int currentIndex = (startIndex + i) % widget.itemCount;
        String itemString = widget.getItemString(currentIndex).toLowerCase();

        if (itemString.startsWith(_quickTypeBuffer)) {
          setState(() {
            _focusedIndex = currentIndex;
          });
          widget.onSelectedIndexChange?.call(_focusedIndex);
          _scrollToIndex(_focusedIndex);
          return;
        }
      }
    } else {
      // Start new quick typing session
      _quickTypeBuffer = character.toLowerCase();
      _quickTypeTimer = Timer(_quickTypeDuration, () {
        setState(() {
          _quickTypeBuffer = '';
        });
      });

      // Regular single-character matching
      int startIndex = _focusedIndex + 1;
      for (int i = 0; i < widget.itemCount; i++) {
        int currentIndex = (startIndex + i) % widget.itemCount;
        String itemString = widget.getItemString(currentIndex).toLowerCase();

        if (itemString.startsWith(character.toLowerCase())) {
          setState(() {
            _focusedIndex = currentIndex;
          });
          widget.onSelectedIndexChange?.call(_focusedIndex);
          _scrollToIndex(_focusedIndex);
          return;
        }
      }
    }
  }

  // Double tap escape functionality
 void _handleEscape() {
    if (widget.onEscapeDoubleTap == null && widget.onEscapeSingleTap == null) return;

    if (_escapeTimer?.isActive ?? false) {
      // Double tap detected within the time window
      _escapeTimer?.cancel();
      widget.onEscapeDoubleTap?.call(); // Only call if it's not null
    } else {
      // First tap, start the timer
      _escapeTimer = Timer(_escapeDoubleTapThreshold, () {
        // Timer expired, single tap only, call single tap action
        widget.onEscapeSingleTap?.call(); // Only call if not null
      });
    }
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

  Map<ShortcutActivator, Intent> get _shortcuts {
    final Map<ShortcutActivator, Intent> baseShortcuts = {
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
        const SingleActivator(LogicalKeyboardKey.escape): const EscapeIntent(),
      const SingleActivator(LogicalKeyboardKey.keyD, alt: true):
          const DeleteIntent(),
      if (widget.onEdit != null)
        const SingleActivator(LogicalKeyboardKey.keyE, alt: true):
            const EditIntent(),
      if (widget.onCopy != null)
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const CopyIntent(),
    };

    // Add character key shortcuts
    for (final key in LogicalKeyboardKey.knownLogicalKeys) {
      if (_isCharacterKey(key)) {
        baseShortcuts[SingleActivator(key)] = CharacterKeyIntent(key.keyLabel);
      }
    }

    return baseShortcuts;
  }

  bool _isCharacterKey(LogicalKeyboardKey key) {
    final keyLabel = key.keyLabel;
    return keyLabel.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(keyLabel);
  }

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
        EditIntent: CallbackAction<EditIntent>(
          onInvoke: (intent) => _handleEdit(),
        ),
        EscapeIntent: CallbackAction<EscapeIntent>(
          //Esc button functionalities
          onInvoke: (intent) => _handleEscape(),
        ),
        CopyIntent: CallbackAction<CopyIntent>(
          onInvoke: (intent) => _handleCopy(),
        ),
        CharacterKeyIntent: CallbackAction<CharacterKeyIntent>(
          onInvoke: (intent) => _handleCharacterKey(intent.character),
        ),
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (intent) => _handleDelete(),
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
          child: ListView.separated(
            controller: _scrollController,
            padding: widget.padding, // Apply padding
            itemCount: widget.itemCount,
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
            separatorBuilder: widget.separatorBuilder ??
                (context, index) => const SizedBox
                    .shrink(), // Use provided separator or no separator.
          ),
        ),
      ),
    );
  }

  void _handleDelete() {
    if (widget.onDelete == null || _focusedIndex == -1) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        int selectedOption = 0; 

        return StatefulBuilder(
          builder: (context, setState) {
            return Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.arrowLeft): SelectNoIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowRight): SelectYesIntent(),
                LogicalKeySet(LogicalKeyboardKey.enter): ConfirmIntent(),
              },
              child: Actions(
                actions: {
                  SelectNoIntent: CallbackAction<SelectNoIntent>(
                    onInvoke: (intent) => setState(() => selectedOption = 0),
                  ),
                  SelectYesIntent: CallbackAction<SelectYesIntent>(
                    onInvoke: (intent) => setState(() => selectedOption = 1),
                  ),
                  ConfirmIntent: CallbackAction<ConfirmIntent>(
                    onInvoke: (intent) {
                      if (selectedOption == 1) {
                        widget.onDelete!(_focusedIndex);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                },
                child: AlertDialog(
                  title: const Text("Confirm Deletion"),
                  content:
                      const Text("Are you sure you want to delete this item?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "No",
                        style: TextStyle(
                          color:
                              selectedOption == 0 ? Colors.blue : Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onDelete!(_focusedIndex);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Yes",
                        style: TextStyle(
                          color:
                              selectedOption == 1 ? Colors.blue : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _quickTypeTimer?.cancel();
     _escapeTimer?.cancel();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }
}



