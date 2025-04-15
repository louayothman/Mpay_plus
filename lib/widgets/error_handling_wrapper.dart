import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class ErrorHandlingWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onInit;
  final bool checkConnectivity;

  const ErrorHandlingWrapper({
    Key? key,
    required this.child,
    this.onInit,
    this.checkConnectivity = true,
  }) : super(key: key);

  @override
  State<ErrorHandlingWrapper> createState() => _ErrorHandlingWrapperState();
}

class _ErrorHandlingWrapperState extends State<ErrorHandlingWrapper> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  late StreamSubscription<bool> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    if (widget.checkConnectivity) {
      _checkConnectivity();
      _listenToConnectivity();
    }
    if (widget.onInit != null) {
      _initializeData();
    }
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityUtils.isConnected();
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = ConnectivityUtils.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          if (isConnected && _hasError) {
            // Retry initialization if connection is restored and there was an error
            _initializeData();
          }
        });
      }
    });
  }

  Future<void> _initializeData() async {
    if (widget.onInit == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await widget.onInit!();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.checkConnectivity) {
      _connectivitySubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return ErrorHandler.buildEmptyStateWidget(
        message: 'حدث خطأ: $_errorMessage',
        icon: Icons.error_outline,
        onRefresh: _initializeData,
      );
    }

    return Column(
      children: [
        if (widget.checkConnectivity && !_isConnected)
          ConnectivityUtils.connectivityBanner(_isConnected),
        Expanded(child: widget.child),
      ],
    );
  }
}
