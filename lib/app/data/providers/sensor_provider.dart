import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/sensor_model.dart';

class SensorProvider {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://growsense-83ff2-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  /// Stream realtime sensor
  Stream<SensorModel> getRealtimeSensorStream() {
    return _dbRef.child('sensor_tanaman').onValue.map((DatabaseEvent event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return SensorModel.empty();
      }
      final rawMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return SensorModel.fromMap(rawMap);
    });
  }

  /// Memfilter riwayat sensor langsung dari server Firebase berdasarkan rentang waktu
  Future<List> getRiwayatFiltered(
    DateTime dtMulai,
    DateTime dtSelesai,
  ) async {
    String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dtMulai);
    String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dtSelesai);

    // Saring langsung di server Firebase agar tidak mengunduh seluruh database
    DataSnapshot snapshot = await _dbRef
        .child('riwayat_sensor')
        .orderByChild('waktu_lokal')
        .startAt(startStr)
        .endAt('$endStr\uf8ff')
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final dataMentah = snapshot.value;
    Map<String, Map<String, dynamic>> groupedMap = {};

    if (dataMentah is Map) {
      dataMentah.forEach((key, value) {
        if (value is Map) {
          DateTime? recordTime;

          // Parse waktu_lokal
          if (value['waktu_lokal'] != null && value['waktu_lokal'].toString().isNotEmpty) {
            try {
              recordTime = DateTime.parse(value['waktu_lokal'].toString());
            } catch (_) {}
          }

          // Fallback timestamp epoch
          if (recordTime == null) {
            var timeVal = value['timestamp_server'] ?? value['timestamp_esp32'] ?? value['timestamp'];
            if (timeVal != null) {
              int? epoch = int.tryParse(timeVal.toString()) ?? double.tryParse(timeVal.toString())?.toInt();
              if (epoch != null) {
                recordTime = epoch.toString().length <= 10
                    ? DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
              }
            }
          }

          if (recordTime != null) {
            bool isInRange = (recordTime.isAfter(dtMulai) || recordTime.isAtSameMomentAs(dtMulai)) &&
                (recordTime.isBefore(dtSelesai) || recordTime.isAtSameMomentAs(dtSelesai));

            if (isInRange) {
              String waktuRapi = recordTime.toString().substring(0, 19);
              String waktuExcel = value['waktu_lokal']?.toString() ?? waktuRapi;

              if (!groupedMap.containsKey(waktuRapi)) {
                groupedMap[waktuRapi] = {
                  'waktu': waktuExcel,
                  'timestamp_epoch': value['timestamp_server']?.toString() ?? value['timestamp_esp32']?.toString() ?? '-',
                  'suhu': '-',
                  'kelembapan': '-',
                  'ph': '-',
                  'nutrisi': '-',
                };
              }

              // Filter integer overflow nutrisi
              var rawNutrisi = value['nutrisi'];
              String nutrisiFormatted = rawNutrisi?.toString() ?? '-';
              if (nutrisiFormatted == "2147483648" || nutrisiFormatted == "2147483647") {
                nutrisiFormatted = "-99";
              }

              if (value['suhu'] != null) groupedMap[waktuRapi]!['suhu'] = value['suhu'];
              if (value['kelembapan'] != null) groupedMap[waktuRapi]!['kelembapan'] = value['kelembapan'];
              if (value['ph'] != null) groupedMap[waktuRapi]!['ph'] = value['ph'];
              if (rawNutrisi != null) groupedMap[waktuRapi]!['nutrisi'] = nutrisiFormatted;
            }
          }
        }
      });
    }

    List hasil = groupedMap.values.toList();
    hasil.sort((a, b) => a['waktu'].compareTo(b['waktu']));
    return hasil;
  }
}