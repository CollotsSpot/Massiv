import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_assistant_provider.dart';
import '../services/music_assistant_api.dart';
import '../services/settings_service.dart';
import 'debug_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _wsPortController = TextEditingController();
  final _authTokenController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<MusicAssistantProvider>();
    _serverUrlController.text = provider.serverUrl ?? 'ma.serverscloud.org';

    final wsPort = await SettingsService.getWebSocketPort();
    if (wsPort != null) {
      _wsPortController.text = wsPort.toString();
    }

    final authToken = await SettingsService.getAuthToken();
    if (authToken != null) {
      _authTokenController.text = authToken;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _wsPortController.dispose();
    _authTokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_serverUrlController.text.isEmpty) {
      _showError('Please enter a server URL');
      return;
    }

    // Save WebSocket port setting
    int? wsPort;
    if (_wsPortController.text.isNotEmpty) {
      wsPort = int.tryParse(_wsPortController.text);
      if (wsPort == null) {
        _showError('Invalid WebSocket port number');
        return;
      }
    }
    await SettingsService.setWebSocketPort(wsPort);

    // Save auth token
    await SettingsService.setAuthToken(
      _authTokenController.text.trim().isNotEmpty
        ? _authTokenController.text.trim()
        : null
    );

    setState(() {
      _isConnecting = true;
    });

    try {
      final provider = context.read<MusicAssistantProvider>();
      await provider.connectToServer(_serverUrlController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Connection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicAssistantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugLogScreen(),
                ),
              );
            },
            color: Colors.white,
            tooltip: 'Debug Logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(provider.connectionState),
                    color: _getStatusColor(provider.connectionState),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connection Status',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(provider.connectionState),
                          style: TextStyle(
                            color: _getStatusColor(provider.connectionState),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Server URL input
            const Text(
              'Music Assistant Server',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Music Assistant server URL or IP address',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _serverUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ma.serverscloud.org or 192.168.1.100',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.dns_rounded,
                  color: Colors.white54,
                ),
              ),
              enabled: !_isConnecting,
            ),

            const SizedBox(height: 24),

            // WebSocket Port input
            const Text(
              'WebSocket Port (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave empty for auto-detection. Try 8095 if connection fails.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _wsPortController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 8095 or 443 (leave empty for auto)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.settings_ethernet_rounded,
                  color: Colors.white54,
                ),
              ),
              enabled: !_isConnecting,
            ),

            const SizedBox(height: 24),

            // Authentication Token input
            const Text(
              'Authentication Token (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Required if your server uses authentication (e.g., Authelia). Leave empty if not needed.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _authTokenController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter authentication token or session cookie',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.vpn_key_rounded,
                  color: Colors.white54,
                ),
              ),
              enabled: !_isConnecting,
            ),

            const SizedBox(height: 24),

            // Connect button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1a1a1a),
                  disabledBackgroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1a1a1a),
                        ),
                      )
                    : const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            if (provider.isConnected) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    await provider.disconnect();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Disconnected from server'),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Debug logs button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugLogScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report_rounded),
                label: const Text('View Debug Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Connection Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Default ports: 443 for HTTPS, 8095 for HTTP\n'
                    '• You can override the port in the WebSocket Port field\n'
                    '• Use domain name or IP address for server\n'
                    '• Make sure your device can reach the server\n'
                    '• Check debug logs if connection fails',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(MAConnectionState state) {
    switch (state) {
      case MAConnectionState.connected:
        return Icons.check_circle_rounded;
      case MAConnectionState.connecting:
        return Icons.sync_rounded;
      case MAConnectionState.error:
        return Icons.error_rounded;
      case MAConnectionState.disconnected:
        return Icons.cloud_off_rounded;
    }
  }

  Color _getStatusColor(MAConnectionState state) {
    switch (state) {
      case MAConnectionState.connected:
        return Colors.green;
      case MAConnectionState.connecting:
        return Colors.orange;
      case MAConnectionState.error:
        return Colors.red;
      case MAConnectionState.disconnected:
        return Colors.white54;
    }
  }

  String _getStatusText(MAConnectionState state) {
    switch (state) {
      case MAConnectionState.connected:
        return 'Connected';
      case MAConnectionState.connecting:
        return 'Connecting...';
      case MAConnectionState.error:
        return 'Connection Error';
      case MAConnectionState.disconnected:
        return 'Disconnected';
    }
  }
}
