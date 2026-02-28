import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/config/api_config.dart';

class SocketService {
  late IO.Socket socket;
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void init() {
    // Determine the socket URL from API_BASE_URL
    // If API_BASE_URL is https://domain.com/api/v1, we want https://domain.com
    final uri = Uri.parse(ApiConfig.baseUrl);
    final socketUrl = uri.origin;

    print('[SOCKET] Initializing with: $socketUrl');

    socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // Use WebSocket transport for efficiency
      .enableAutoConnect()
      .build());

    socket.onConnect((_) {
      print('[SOCKET] Connected to Backend');
    });

    socket.onDisconnect((_) {
      print('[SOCKET] Disconnected from Backend');
    });

    socket.onConnectError((err) {
      print('[SOCKET] Connection Error: $err');
    });
  }

  void joinCampaign(String campaignId) {
    socket.emit('join_campaign', campaignId);
    print('[SOCKET] Joined campaign room: $campaignId');
  }

  void leaveCampaign(String campaignId) {
    socket.emit('leave_campaign', campaignId);
    print('[SOCKET] Left campaign room: $campaignId');
  }

  void onMilestoneUpdate(Function(Map<String, dynamic>) handler) {
    socket.on('milestone_update', (data) {
      print('[SOCKET] Milestone Update received: $data');
      handler(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
