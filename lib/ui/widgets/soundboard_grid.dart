import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/sfx_bus_controller.dart';

class SoundboardGrid extends StatelessWidget {
  const SoundboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SfxBusController>(
      builder: (context, sfx, _) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Soundboard (Звуковые эффекты / SFX)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (sfx.triggers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Soundboard пуст. Добавьте SFX или быстрые триггеры.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: sfx.triggers.length,
                    itemBuilder: (context, index) {
                      final trigger = sfx.triggers[index];
                      final color = Color(trigger.colorHex);

                      return ElevatedButton(
                        key: ValueKey('sfx_btn_${trigger.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.withAlpha(200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => sfx.triggerSfx(trigger.id),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trigger.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (trigger.hotkey != null)
                              Text(
                                '[${trigger.hotkey}]',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
