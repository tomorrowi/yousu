import 'package:flutter/material.dart';

/// 设置页面
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text('设置',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // 单位
            _sectionHeader('单位'),
            _settingCard(
              child: _pickerTile(
                label: '速度单位',
                selected: _speedUnit,
                options: _speedUnitOptions,
                onChanged: (v) => setState(() => _speedUnit = v),
              ),
            ),

            const SizedBox(height: 16),
            _sectionHeader('提醒'),
            _settingCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('速度预警',
                        style: TextStyle(color: Colors.white)),
                    value: _speedWarningEnabled,
                    onChanged: (v) =>
                        setState(() => _speedWarningEnabled = v),
                    activeColor: const Color(0xFF00D4FF),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_speedWarningEnabled) ...[
                    const Divider(color: Color(0xFF2A2A3E)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('预警阈值',
                              style: TextStyle(color: Color(0xFF8892B0))),
                          const Spacer(),
                          Text('${_speedWarningThreshold.round()} km/h',
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    Slider(
                      value: _speedWarningThreshold,
                      min: 30,
                      max: 350,
                      divisions: 64,
                      activeColor: const Color(0xFF00D4FF),
                      onChanged: (v) =>
                          setState(() => _speedWarningThreshold = v),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionHeader('性能'),
            _settingCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('省电模式',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('降低传感器采集频率',
                        style: TextStyle(color: Color(0xFF8892B0))),
                    value: _lowPowerMode,
                    onChanged: (v) =>
                        setState(() => _lowPowerMode = v),
                    activeColor: const Color(0xFF00D4FF),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: Color(0xFF2A2A3E)),
                  SwitchListTile(
                    title: const Text('触觉反馈',
                        style: TextStyle(color: Colors.white)),
                    value: _hapticFeedback,
                    onChanged: (v) =>
                        setState(() => _hapticFeedback = v),
                    activeColor: const Color(0xFF00D4FF),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionHeader('场景'),
            _settingCard(
              child: SwitchListTile(
                title: const Text('自动场景识别',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('根据速度和传感器数据自动判断出行方式',
                    style: TextStyle(color: Color(0xFF8892B0))),
                value: _autoSceneDetection,
                onChanged: (v) =>
                    setState(() => _autoSceneDetection = v),
                activeColor: const Color(0xFF00D4FF),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 16),
            _sectionHeader('关于'),
            _settingCard(
              child: Column(
                children: [
                  _infoTile('版本', '1.0.0'),
                  const Divider(color: Color(0xFF2A2A3E)),
                  _infoTile('数据来源', 'GPS + 传感器融合'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                '有速 · 传感器测速仅供参考，不作为法定依据',
                style: TextStyle(color: Color(0xFF4A4A6E), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 状态
  String _speedUnit = 'km/h';
  final _speedUnitOptions = ['km/h', 'mph', '节'];
  bool _speedWarningEnabled = false;
  double _speedWarningThreshold = 120;
  bool _lowPowerMode = false;
  bool _hapticFeedback = true;
  bool _autoSceneDetection = true;

  // MARK: - Widget Builders

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1)),
    );
  }

  Widget _settingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _pickerTile({
    required String label,
    required String selected,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8892B0), fontSize: 15)),
          const Spacer(),
          ...options.map((o) {
            final isSelected = o == selected;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF00D4FF))
                        : null,
                  ),
                  child: Text(o,
                      style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF8892B0),
                          fontSize: 13)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8892B0), fontSize: 15)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}
