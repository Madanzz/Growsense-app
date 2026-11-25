import 'dart:io';
import 'dart:developer' as developer;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import '../models/sensor_model.dart';

class GoogleDriveProvider {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  String? _googleDriveFileId;
  bool _isUploading = false;

  Future<void> initGoogleDriveOnce() async {
    try {
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      user ??= await _googleSignIn.signIn();

      if (user != null) {
        developer.log(
          "Terhubung dengan Google Drive akun: ${user.email}",
          name: "GoogleDriveProvider",
        );
      } else {
        developer.log(
          "Pengguna membatalkan pemilihan akun Google Sign-In.",
          name: "GoogleDriveProvider",
          level: 800,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error Google Sign-In Init",
        name: "GoogleDriveProvider",
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  // 🔥 FUNGSI UNTUK MENGUNGGAH FILE CSV UTUH DARI HP (LOKAL) KE GOOGLE DRIVE
  Future<void> uploadFileCsvLokal() async {
    if (_isUploading) return;
    _isUploading = true;

    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      googleUser ??= await _googleSignIn.signInSilently();

      if (googleUser == null) {
        _isUploading = false;
        return;
      }

      var httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        _isUploading = false;
        return;
      }

      var driveApi = drive.DriveApi(httpClient);
      String namaFileDrive = "log_growsense_v2.csv"; // 👈 NAMA FILE BARU PRESISI

      // Read File Lokal dari Storage HP
      final Directory? dir = await getExternalStorageDirectory();
      final File fileLokal = File("${dir?.path}/log_growsense_v2.csv");

      if (!await fileLokal.exists()) {
        developer.log("File CSV lokal belum dibuat.", name: "GoogleDriveProvider");
        _isUploading = false;
        return;
      }

      List<int> bytesFile = await fileLokal.readAsBytes();
      Stream<List<int>> stream = Stream.value(bytesFile);

      // Cari ID File di Google Drive
      if (_googleDriveFileId == null) {
        var listFiles = await driveApi.files.list(
          q: "name = '$namaFileDrive' and trashed = false",
        );

        if (listFiles.files != null && listFiles.files!.isNotEmpty) {
          _googleDriveFileId = listFiles.files!.first.id;
        }
      }

      // Buat File Baru jika belum ada di Drive, atau Overwrite (Update) jika sudah ada
      if (_googleDriveFileId == null) {
        var driveFile = drive.File()..name = namaFileDrive;
        var result = await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(stream, bytesFile.length),
        );
        _googleDriveFileId = result.id;
        developer.log("File Drive $namaFileDrive baru berhasil dibuat!", name: "GoogleDriveProvider");
      } else {
        await driveApi.files.update(
          drive.File(),
          _googleDriveFileId!,
          uploadMedia: drive.Media(stream, bytesFile.length),
        );
        developer.log("File Drive $namaFileDrive berhasil diperbarui (Batch Upload)!", name: "GoogleDriveProvider");
      }
    } catch (e, stackTrace) {
      developer.log(
        "Upload CSV File Error",
        name: "GoogleDriveProvider",
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    } finally {
      _isUploading = false;
    }
  }

  // METHOD LAMA TETAP DIPERTAHANKAN KARENA DIPAKAI OLEH KOMPONEN LAIN
  Future<void> simpanKeGoogleDrive(SensorModel sensor) async {
    await uploadFileCsvLokal();
  }
}