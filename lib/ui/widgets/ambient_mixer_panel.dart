import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/ambient_bus_controller.dart';

class AmbientMixerPanel extends StatelessWidget {
  const AmbientMixerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AmbientBusController>(
      builder: (context, ambient, _) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Эмбиент-слои (Фоновые звуки)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('ambient_stop_all_btn'),
                      onPressed: () => ambient.stopAllLayers(),
                      icon: const Icon(Icons.stop),
                      label: const Text('Выключить все'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ambient.layers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Нет загруженных эмбиентов. Импортируйте аудиофайлы или загрузите пресет.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Column(
                    children: ambient.layers.map((layer) {
                      return Padding(
                        key: ValueKey('ambient_row_${layer.id}'),
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Switch(
                              key: ValueKey('ambient_switch_${layer.id}'),
                              value: layer.isActive,
                              onChanged: (_) => ambient.toggleLayer(layer.id),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                layer.title,
                                style: TextStyle(
                                  fontWeight: layer.isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Slider(
                                key: ValueKey('ambient_slider_${layer.id}'),
                                value: layer.volume,
                                onChanged: layer.isActive
                                    ? (val) => ambient.setLayerVolume(layer.id, val)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
