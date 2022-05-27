// Generic Interface for all BLoCs
import 'package:flutter/material.dart';

abstract class CustomBlocBase {
  void dispose();
}

// Generic BLoC provider
class CustomBlocProvider<T extends CustomBlocBase> extends StatefulWidget {
  CustomBlocProvider({
    Key key,
    @required this.child,
    @required this.bloc,
  }) : super(key: key);

  final T bloc;
  final Widget child;

  @override
  _CustomBlocProviderState<T> createState() => _CustomBlocProviderState<T>();

  static T of<T extends CustomBlocBase>(BuildContext context) {
    CustomBlocProvider<T> provider =
        context.findAncestorWidgetOfExactType<CustomBlocProvider<T>>();
    return provider.bloc;
  }
}

class _CustomBlocProviderState<T>
    extends State<CustomBlocProvider<CustomBlocBase>> {
  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
