import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/presentation/screens/Weather/const.dart';
import 'package:weather/weather.dart';
import 'dart:async';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

void main() {
  runApp(const WeatherScreen());
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherFactory wf = WeatherFactory(OPENWEATHER_API_KEY);
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  Weather? _weather;
  List<Weather>? _forecast;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchWeatherData() async {
    try {
      final weather = await wf.currentWeatherByCityName("Caloocan");
      final forecast = await wf.fiveDayForecastByCityName("Caloocan");
      setState(() {
        _weather = weather;
        _forecast = forecast;
      });
      // Refresh weather data every 30 minutes
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        try {
          final updatedWeather = await wf.currentWeatherByCityName("Caloocan");
          final updatedForecast =
              await wf.fiveDayForecastByCityName("Caloocan");
          setState(() {
            _weather = updatedWeather;
            _forecast = updatedForecast;
          });
        } catch (e) {
          print('Error updating weather data: $e');
        }
      });
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/weather-background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildDateTime(),
          const SizedBox(height: 40),
          _buildWeatherTemperature(),
          _buildWeatherCard(),
          const SizedBox(height: 20),
          _buildWeatherInfo(),
          const SizedBox(height: 20),
          _buildWeatherTimeline(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Color.fromARGB(255, 0, 0, 0),
              size: 34,
            ),
            const SizedBox(width: 4),
            Text(
              _weather?.areaName ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                "assets/images/maps-location.png",
                width: 25,
                height: 25,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today, ${DateFormat("MMM d").format(_currentTime)} ${DateFormat("h:mm").format(_currentTime)}",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "https://openweathermap.org/img/wn/${_weather?.weatherIcon}@2x.png",
              ),
            ),
          ),
        ),
        Row(
          children: [
            Icon(
              _getWeatherIcon(_weather?.weatherMain ?? ''),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              _weather?.weatherDescription?.capitalize() ?? "",
              style: const TextStyle(
                color: Color.fromARGB(255, 255, 254, 254),
                fontSize: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherTimeline() {
    if (_forecast == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowForecasts = _forecast!
        .where((forecast) =>
            forecast.date!.day == tomorrow.day &&
            forecast.date!.month == tomorrow.month &&
            forecast.date!.year == tomorrow.year)
        .toList();

    var tomorrowCondition = "Unknown";
    if (tomorrowForecasts.isNotEmpty) {
      final conditions =
          tomorrowForecasts.map((f) => f.weatherMain ?? '').toList();
      final conditionMap = <String, int>{};
      for (final condition in conditions) {
        conditionMap[condition] = (conditionMap[condition] ?? 0) + 1;
      }
      tomorrowCondition =
          conditionMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final List<Weather> displayForecasts = tomorrowForecasts.take(4).toList();

    // Get today's hourly forecasts
    final todayForecasts = _forecast!
        .where((forecast) =>
            forecast.date!.day == DateTime.now().day &&
            forecast.date!.month == DateTime.now().month &&
            forecast.date!.year == DateTime.now().year)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        // Today's hourly forecast
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 80, 0, 0).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: todayForecasts.map((forecast) {
                  return SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Text(
                          "${forecast.temperature?.celsius?.toStringAsFixed(0)}°",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          _getWeatherIcon(forecast.weatherMain ?? ''),
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(forecast.date!.toLocal()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          forecast.weatherMain ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'WEATHER UPDATES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 80, 0, 0).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: displayForecasts.map((forecast) {
                  return _buildTimelineItem(
                    DateFormat('h:mm a').format(forecast.date!.toLocal()),
                    "${forecast.temperature?.celsius?.toStringAsFixed(0)}°",
                    _getWeatherIcon(forecast.weatherMain ?? ''),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                _getWeatherIcon(tomorrowCondition),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tomorrow, ${DateFormat("MMM d").format(tomorrow)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    tomorrowCondition,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (tomorrowForecasts.isNotEmpty)
                Text(
                  "${tomorrowForecasts.map((f) => f.temperature?.celsius ?? 0).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°↑ "
                  "${tomorrowForecasts.map((f) => f.temperature?.celsius ?? 0).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}°↓",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic time, dynamic temp, IconData icon) {
    return Column(
      children: [
        Text(
          time.toString(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          temp.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(dynamic condition) {
    final weatherMain = condition.toString().toLowerCase();
    if (weatherMain.contains('clear')) {
      return Icons.wb_sunny_outlined;
    } else if (weatherMain.contains('cloud')) {
      return Icons.cloud_outlined;
    } else if (weatherMain.contains('rain')) {
      return Icons.water_drop_outlined;
    } else if (weatherMain.contains('snow')) {
      return Icons.ac_unit_outlined;
    } else if (weatherMain.contains('thunderstorm')) {
      return Icons.flash_on_outlined;
    }
    return Icons.cloud_outlined;
  }

  Widget _buildWeatherTemperature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 106,
              height: 106,
              child: Text(
                "${_weather?.temperature?.celsius?.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Color.fromARGB(255, 136, 31, 31),
                  fontSize: 106,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                "°C",
                style: TextStyle(
                  color: Color.fromARGB(255, 136, 31, 31),
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${_weather?.tempMax?.celsius?.toStringAsFixed(0)}°↑",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${_weather?.tempMin?.celsius?.toStringAsFixed(0)}°↓",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfo() {
    var currentTime = DateFormat('h:mm').format(_currentTime);

    // Get precipitation probability from forecast if available
    double precipProbability = 0.0;
    if (_forecast != null && _forecast!.isNotEmpty) {
      final now = DateTime.now();
      final nearestForecast = _forecast!.reduce((a, b) {
        return (a.date!.difference(now).abs() < b.date!.difference(now).abs())
            ? a
            : b;
      });
      precipProbability = nearestForecast.rainLastHour ?? 0.0;
    }

    var rainStatus = "No Chance of Rain";
    var rainValue = currentTime;
    if (precipProbability > 0) {
      rainStatus = "Chance of Rain";
      rainValue = "${(precipProbability * 100).toStringAsFixed(0)}%";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem(
            rainValue,
            rainStatus,
            Icons.water_drop_outlined,
          ),
          _buildInfoItem(
            "${_weather?.windSpeed?.toStringAsFixed(0)}km/h",
            "Wind Speed",
            Icons.air,
          ),
          _buildInfoItem(
            "${_weather?.humidity?.toStringAsFixed(0)}%",
            "Humidity",
            Icons.water_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
