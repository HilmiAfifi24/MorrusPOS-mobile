import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../utils/storage_service.dart';

class RealtimeService {
  final StorageService storageService;
  HubConnection? _hubConnection;
  String? _currentOutletId;

  RealtimeService({required this.storageService});

  // Callback when stock updates are received
  void Function(String outletId, List<Map<String, dynamic>> updates)?
  onStockUpdate;

  // Callback when SignalR automatically reconnects and re-joins the outlet group
  void Function()? onReconnected;

  Future<void> connect(String outletId) async {
    // If there is an existing connection, stop it first
    if (_hubConnection != null) {
      await disconnect();
    }

    final token = storageService.token ?? '';
    final baseUrl = storageService.baseUrl;

    debugPrint(
      'Connecting to SignalR Hub at $baseUrl/hub/notifications with outlet: $outletId',
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/hub/notifications',
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('ReceiveStockUpdate', (arguments) {
      debugPrint('SignalR: Received ReceiveStockUpdate event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = Map<String, dynamic>.from(arguments[0] as Map);
          final eventOutletId = data['outletId'] as String;
          final rawUpdates = data['updates'] as List<dynamic>;

          final updates = rawUpdates.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return <String, dynamic>{
              'productId': map['productId'] as String,
              'qty': (map['qty'] as num).toDouble(),
            };
          }).toList();

          if (onStockUpdate != null) {
            onStockUpdate!(eventOutletId, updates);
          }
        } catch (e) {
          debugPrint('Error parsing stock update event arguments: $e');
        }
      }
    });

    // Log when reconnecting starts
    _hubConnection!.onreconnecting(({error}) {
      debugPrint('SignalR: Reconnecting... Error: $error');
    });

    // After automatic reconnect, re-join the outlet group so events are still received
    _hubConnection!.onreconnected(({connectionId}) async {
      debugPrint('SignalR: Reconnected. ConnectionId: $connectionId');
      if (_currentOutletId != null) {
        try {
          await _hubConnection!.invoke(
            'JoinOutletGroup',
            args: [_currentOutletId!],
          );
          debugPrint(
            'SignalR: Re-joined group Outlet_$_currentOutletId after reconnect',
          );
          onReconnected?.call();
        } catch (e) {
          debugPrint('SignalR: Error rejoining group after reconnect: $e');
        }
      }
    });

    _hubConnection!.onclose(({error}) {
      debugPrint('SignalR connection closed. Error: $error');
    });

    try {
      await _hubConnection!.start();
      debugPrint('SignalR Connection Started Successfully.');

      // Join the group for the selected outlet
      await _hubConnection!.invoke('JoinOutletGroup', args: [outletId]);
      _currentOutletId = outletId;
      debugPrint('SignalR: Joined group Outlet_$outletId');
    } catch (e) {
      debugPrint('Error starting SignalR connection or joining group: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      try {
        debugPrint('Disconnecting from SignalR Hub.');
        await _hubConnection!.stop();
      } catch (e) {
        debugPrint('Error stopping SignalR connection: $e');
      } finally {
        _hubConnection = null;
        _currentOutletId = null;
      }
    }
  }
}
