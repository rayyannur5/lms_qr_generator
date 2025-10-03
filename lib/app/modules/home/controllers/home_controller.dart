import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:android_intent_plus/android_intent.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeController extends GetxController {
  final MobileScannerController cameraController = MobileScannerController();

  var scannedValue = Rxn<Map<String, dynamic>>();
  var rawValue = ''.obs;
  var scanResult = Rxn<List<BluetoothDevice>>();
  var selectedDevice = Rxn<BluetoothDevice>();
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  var isConnect = false.obs;
  var isSearching = false.obs;
  var loadingScanDevice = false.obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    var device = box.read('bluetoothDevice');
    if (device != null) {
      printer.isConnected.then( (result) {
        selectedDevice.value = BluetoothDevice(device['name'], device['address']);
        if(result!) {
          isConnect.value = true;
        } else {
          connectDevice(selectedDevice.value!);
        }
      });
    }

    printer.getBondedDevices().then((list) => scanResult.value = list);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> scanDevices() async {
    isSearching.value = true;
    scanResult.value = await printer.getBondedDevices();
    isSearching.value = false;
  }

  Future<void> openBluetoothSettings() async {
    final intent = AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS');
    await intent.launch();
  }

  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      selectedDevice.value = device;
      loadingScanDevice.value = true;
      await printer.connect(selectedDevice.value!);
      Get.snackbar("Berhasil", "berhasil terhubung ke ${device.name}", backgroundColor: Colors.green, colorText: Colors.white);
      isConnect.value = true;
      loadingScanDevice.value = false;
      await box.write('bluetoothDevice', {'name': device.name, 'address': device.address});
      return true;
    } catch (e) {
      isConnect.value = false;
      loadingScanDevice.value = false;
      Get.snackbar("Gagal", "Tidak bisa terhubung ke perangkat", backgroundColor: Colors.red, colorText: Colors.white);
      forgetDevice(device);
      return false;
    }
  }

  void forgetDevice(BluetoothDevice device) {
    selectedDevice.value = null;
    printer.disconnect();
    isConnect.value = false;
    box.remove('bluetoothDevice');
  }

  void bottomSheetConnectDevice() {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        width: Get.width,
        height: Get.height / 2 + 180,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('Pilih Perangkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: Get.height / 2,
              child: Obx(() {
                if (isSearching.value) {
                  return Center(child: CircularProgressIndicator());
                } else if (scanResult.value?.isEmpty ?? true) {
                  return Center(child: Image.asset('assets/images/no_data.png'));
                } else {
                  return ListView(
                    children: scanResult.value!.map((device) {
                      if (selectedDevice.value != null) {
                        if (device.address == selectedDevice.value!.address) {
                          if (loadingScanDevice.value) {
                            return Shimmer(
                              duration: Duration(milliseconds: 500),
                              child: Card(
                                color: Colors.grey.shade100,
                                elevation: 0,
                                child: ListTile(
                                  title: Text(device.name ?? '-', style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  subtitle: Text(device.address ?? '-', style: Get.textTheme.labelMedium),
                                ),
                              ),
                            );
                          }
                          return Card(
                            color: Get.theme.primaryColor,
                            elevation: 0,
                            child: ListTile(
                              onTap: () => forgetDevice(device),
                              title: Text(
                                device.name ?? '-',
                                style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(device.address ?? '-', style: Get.textTheme.labelMedium?.copyWith(color: Colors.white)),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            child: ListTile(
                              onTap: () async {
                                bool result = await connectDevice(device);
                                if (result) {
                                  Get.closeAllSnackbars();
                                  await Future.delayed(Duration(milliseconds: 100));
                                  Get.back();
                                }
                              },
                              title: Text(device.name ?? '-', style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(device.address ?? '-', style: Get.textTheme.labelMedium),
                            ),
                          );
                        }
                      } else {
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          child: ListTile(
                            onTap: () async {
                              bool result = await connectDevice(device);
                              if (result) {
                                Get.closeAllSnackbars();
                                await Future.delayed(Duration(milliseconds: 100));
                                Get.back();
                              }
                            },
                            title: Text(device.name ?? '-', style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(device.address ?? '-', style: Get.textTheme.labelMedium),
                          ),
                        );
                      }
                    }).toList(),
                  );
                }
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () => scanDevices(), child: Text('Scan')),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(onPressed: () => openBluetoothSettings(), icon: Icon(Icons.settings), label: Text('Pengaturan')),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void bottomSheetScan() {
    Get.bottomSheet(
      Container(
        width: Get.width,
        height: Get.height / 2,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Kamera scanner
              MobileScanner(
                controller: cameraController,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    var value = barcode.rawValue ?? "";
                    try {
                      scannedValue.value = jsonDecode(value);
                      if(scannedValue.value!.containsKey('it') && scannedValue.value!.containsKey('nt') && scannedValue.value!.containsKey('at') && scannedValue.value!.containsKey('pt')) {
                        // valid
                        rawValue.value = value;
                        print(rawValue);
                        print(scannedValue.value!['pt']);
                        Get.back();
                      } else {
                        throw Exception('QR Tidak valid');
                      }
                    } catch (e) {
                      cameraController.stop();
                      Get.snackbar("Error", 'QR Tidak valid', backgroundColor: Colors.red, colorText: Colors.white);
                      Future.delayed(const Duration(seconds: 2), () {
                        cameraController.start();
                      });
                    }
                    break;
                  }
                },
              ),

              // Tombol switch kamera (pojok kanan atas)
              Positioned(
                top: 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: () {
                      cameraController.switchCamera();
                    },
                  ),
                ),
              ),

              // Tombol close (pojok kiri atas)
              Positioned(
                top: 20,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> printTicket() async {
    printer.isConnected.then((isConnected) async {
      if (isConnected == true) {
        // Judul
        printer.printCustom("ID CUSTOMER", 2, 1);
        printer.printNewLine();

        // Format manual agar rapi di kertas 56mm
        printer.printCustom("ID        : ${scannedValue.value!["it"]}", 1, 0);
        printer.printCustom("Nama      : ${scannedValue.value!["nt"]}", 1, 0);
        printer.printCustom("Area      : ${scannedValue.value!["at"]}", 1, 0);
        printer.printCustom("Pelanggan : ${scannedValue.value!["pt"]}", 1, 0);

        printer.printNewLine();

        // QR Code
        // printer.printQRcode(rawValue.value, 200, 200, 1);

        // generate image QR + 2 baris teks
        final qrBytes = await generateQrWithText(
          data: rawValue.value,
          textLine1: "LG", // baris 1 (2 karakter)
          textLine2: "SA", // baris 2 (2 karakter)
          qrSize: 150,     // sesuaikan jika ingin lebih besar/kecil
        );

        // kirim ke printer (metode ini sesuai dengan library printer yang kamu pakai)
        printer.printImageBytes(qrBytes);

        printer.printNewLine();
        printer.printNewLine();
        printer.printNewLine();

      } else {
        bottomSheetConnectDevice();
      }
    });
  }

  /// Generate an image (PNG bytes) with TEXT on the left and QR on the right.
  Future<Uint8List> generateQrWithText({
    required String data,
    required String textLine1,
    required String textLine2,
    double qrSize = 150.0,          // ukuran QR
    double textWidth = 100.0,       // area teks utama
    double timestampWidth = 120.0,  // area timestamp
    double padding = 12.0,          // jarak antar elemen
    double fontSize = 40.0,         // ukuran font teks utama
    double timeFontSize = 24.0,     // ukuran font jam
    double dateFontSize = 24.0,     // ukuran font tanggal
  }) async {
    // --- Buat timestamp sekarang ---
    final now = DateTime.now();
    final shortYear = now.year.toString().substring(2);
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${shortYear}";

    // Hitung total lebar canvas
    final totalWidth = (timestampWidth + padding + textWidth + padding + qrSize).toInt();
    final totalHeight = qrSize.toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background putih
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), totalHeight.toDouble()),
      bgPaint,
    );

    // --- Gambar timestamp (jam besar, tanggal kecil) ---
    final tsSpan = TextSpan(
      children: [
        TextSpan(
          text: "$dateStr\n",
          style: TextStyle(
            color: Colors.black,
            fontSize: dateFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: timeStr,
          style: TextStyle(
            color: Colors.black87,
            fontSize: timeFontSize,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );

    final tsPainter = TextPainter(
      text: tsSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tsPainter.layout(minWidth: 0, maxWidth: timestampWidth);
    final offsetXTs = (timestampWidth - tsPainter.width) / 2;
    final offsetYTs = (totalHeight - tsPainter.height) / 2;
    tsPainter.paint(canvas, Offset(offsetXTs, offsetYTs));

    // --- Gambar textLine1 + textLine2 ---
    final textSpan = TextSpan(
      text: '$textLine1\n$textLine2',
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: textWidth);
    final offsetXText = timestampWidth + padding + (textWidth - textPainter.width) / 2;
    final offsetYText = (totalHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(offsetXText, offsetYText));

    // --- Gambar QR ---
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    canvas.save();
    canvas.translate(timestampWidth + padding + textWidth + padding, 0);
    qrPainter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    // --- Render ke image & bytes ---
    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(totalWidth, totalHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }


}
