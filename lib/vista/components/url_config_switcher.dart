import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/UrlConfigProvider.dart';

class UrlConfigSwitcher extends StatelessWidget {
  const UrlConfigSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final urlConfigProvider = Provider.of<UrlConfigProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modo de conexión:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: urlConfigProvider.useOnlineUrl,
                  onChanged: (value) {
                    urlConfigProvider.setUseOnlineUrl(value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            Text(
              urlConfigProvider.useOnlineUrl ? 'En línea' : 'Local',
              style: TextStyle(
                color: urlConfigProvider.useOnlineUrl ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              urlConfigProvider.currentBaseUrl,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}