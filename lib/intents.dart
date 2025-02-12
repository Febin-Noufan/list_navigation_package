// Custom intents for actions
import 'package:flutter/material.dart';

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

class CharacterKeyIntent extends ListNavigationIntent {
  final String character;
  const CharacterKeyIntent(this.character);
}

class SelectNoIntent extends Intent {}

class SelectYesIntent extends Intent {}

class ConfirmIntent extends Intent {}

class EscapeIntent extends Intent{ //Esc botton 
  const EscapeIntent();
}
