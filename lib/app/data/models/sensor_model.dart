class SensorModel {
  final double suhu;
  final double kelembapan;
  final double ph;
  final int nutrisi;
  final String waktuLokal;
  final String timestampEpoch;

  SensorModel({
    required this.suhu,
    required this.kelembapan,
    required this.ph,
    required this.nutrisi,
    required this.waktuLokal,
    required this.timestampEpoch,
  });

  factory SensorModel.fromMap(Map<dynamic, dynamic> map) {
    return SensorModel(
      suhu: double.tryParse(map['suhu']?.toString() ?? '0.0') ?? 0.0,
      kelembapan: double.tryParse(map['kelembapan']?.toString() ?? '0.0') ?? 0.0,
      ph: double.tryParse(map['ph']?.toString() ?? '0.0') ?? 0.0,
      nutrisi: int.tryParse(map['nutrisi']?.toString() ?? '0') ?? 0,
      waktuLokal: map['waktu_lokal']?.toString() ?? '-',
      timestampEpoch: map['timestamp_server']?.toString() ?? 
                      map['timestamp_esp32']?.toString() ?? 
                      map['timestamp_epoch']?.toString() ?? '-',
    );
  }

  /// Helper untuk nilai default/kosong
  factory SensorModel.empty() {
    return SensorModel(
      suhu: 0.0,
      kelembapan: 0.0,
      ph: 0.0,
      nutrisi: 0,
      waktuLokal: '-',
      timestampEpoch: '-',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suhu': suhu,
      'kelembapan': kelembapan,
      'ph': ph,
      'nutrisi': nutrisi,
      'waktu_lokal': waktuLokal,
      'timestamp_epoch': timestampEpoch,
    };
  }
}