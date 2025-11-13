import 'package:flutter/material.dart';

class LoadingCenter extends StatelessWidget {
  const LoadingCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
