import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({super.key});

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  String _selectedSensor = 'temperature';
  String _selectedPeriod = '24h';
  List<dynamic> _historyData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    int? hours;
    int? days;
    
    switch (_selectedPeriod) {
      case '24h':
        hours = 24;
        break;
      case '7d':
        days = 7;
        break;
      case '30d':
        days = 30;
        break;
    }
    
    final data = await sensorProvider.fetchDataByType(
      _selectedSensor,
      hours: hours,
      days: days,
    );
    
    setState(() {
      _historyData = data;
      _isLoading = false;
    });
  }

  String _calculateAverage() {
    if (_historyData.isEmpty) return '--';
    final sum = _historyData.fold<double>(
      0,
      (prev, item) => prev + (item['value'] as num).toDouble(),
    );
    return (sum / _historyData.length).toStringAsFixed(1);
  }

  String _calculateMax() {
    if (_historyData.isEmpty) return '--';
    final max = _historyData.fold<double>(
      double.negativeInfinity,
      (prev, item) => (item['value'] as num).toDouble() > prev
          ? (item['value'] as num).toDouble()
          : prev,
    );
    return max.toStringAsFixed(1);
  }

  String _calculateMin() {
    if (_historyData.isEmpty) return '--';
    final min = _historyData.fold<double>(
      double.infinity,
      (prev, item) => (item['value'] as num).toDouble() < prev
          ? (item['value'] as num).toDouble()
          : prev,
    );
    return min.toStringAsFixed(1);
  }

  final Map<String, Map<String, dynamic>> _sensorInfo = {
    'temperature': {
      'label': 'Nhiệt độ',
      'icon': Icons.thermostat,
      'color': AppColors.temperature,
      'unit': '°C',
    },
    'humidity': {
      'label': 'Độ ẩm không khí',
      'icon': Icons.water_drop,
      'color': AppColors.humidity,
      'unit': '%',
    },
    'soil_moisture': {
      'label': 'Độ ẩm đất',
      'icon': Icons.grass,
      'color': AppColors.soilMoisture,
      'unit': '%',
    },
    'water_level': {
      'label': 'Mực nước',
      'icon': Icons.water,
      'color': AppColors.waterLevel,
      'unit': 'cm',
    },
    'light': {
      'label': 'Ánh sáng',
      'icon': Icons.wb_sunny,
      'color': AppColors.light,
      'unit': '%',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử cảm biến')),
      body: Column(
        children: [
          // Sensor selector
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sensorInfo.length,
              itemBuilder: (context, index) {
                final sensorKey = _sensorInfo.keys.elementAt(index);
                final sensor = _sensorInfo[sensorKey]!;
                final isSelected = _selectedSensor == sensorKey;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSensor = sensorKey);
                    _loadData();
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sensor['color']
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: sensor['color'].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sensor['icon'],
                          color: isSelected
                              ? Colors.white
                              : AppColors.textTertiary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sensor['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildPeriodChip('24h', '24 giờ'),
                const SizedBox(width: 8),
                _buildPeriodChip('7d', '7 ngày'),
                const SizedBox(width: 8),
                _buildPeriodChip('30d', '30 ngày'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _sensorInfo[_selectedSensor]!['color']
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _sensorInfo[_selectedSensor]!['icon'],
                            color: _sensorInfo[_selectedSensor]!['color'],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sensorInfo[_selectedSensor]!['label'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Đơn vị: ${_sensorInfo[_selectedSensor]!['unit']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _historyData.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Không có dữ liệu',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : LineChart(_buildChartData()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Statistics
          if (_historyData.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Trung bình',
                      _calculateAverage(),
                      Icons.show_chart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Cao nhất',
                      _calculateMax(),
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Thấp nhất',
                      _calculateMin(),
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _loadData();
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sensorInfo[_selectedSensor]!['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _sensorInfo[_selectedSensor]!['color'], size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _sensorInfo[_selectedSensor]!['color'],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    
    // Convert API data to chart spots
    if (_historyData.isNotEmpty) {
      for (int i = 0; i < _historyData.length; i++) {
        final item = _historyData[i];
        final value = (item['value'] as num).toDouble();
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    // Calculate min and max for better chart scaling
    double minY = 0;
    double maxY = 100;
    
    if (spots.isNotEmpty) {
      final values = spots.map((spot) => spot.y).toList();
      minY = values.reduce((a, b) => a < b ? a : b);
      maxY = values.reduce((a, b) => a > b ? a : b);
      
      // Add padding
      final range = maxY - minY;
      minY = minY - range * 0.1;
      maxY = maxY + range * 0.1;
    }

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _historyData.length > 10 
                ? (_historyData.length / 5).ceilToDouble()
                : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _historyData.length) {
                return const SizedBox.shrink();
              }
              
              // Format timestamp
              final timestamp = _historyData[index]['createdAt'];
              final dateTime = DateTime.parse(timestamp);
              
              // Show different format based on period
              String label;
              if (_selectedPeriod == '24h') {
                label = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
              } else if (_selectedPeriod == '7d') {
                label = '${dateTime.day}/${dateTime.month}';
              } else {
                label = '${dateTime.day}/${dateTime.month}';
              }
              
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _sensorInfo[_selectedSensor]!['color'],
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _sensorInfo[_selectedSensor]!['color'].withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
