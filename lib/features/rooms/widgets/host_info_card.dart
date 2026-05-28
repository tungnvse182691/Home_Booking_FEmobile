import 'dart:io';
import 'package:flutter/material.dart';
import '../models/room_model.dart';

class HostInfoCard extends StatelessWidget {
  final HostModel host;

  const HostInfoCard({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: host.avatarUrl != null && host.avatarUrl!.isNotEmpty
              ? (host.avatarUrl!.startsWith('http')
                  ? NetworkImage(host.avatarUrl!)
                  : FileImage(File(host.avatarUrl!)) as ImageProvider)
              : null,
          child: host.avatarUrl == null || host.avatarUrl!.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chủ nhà: ${host.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text('Thông tin chủ nhà', 
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
        )
      ],
    );
  }
}
