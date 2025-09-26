import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LMS QR Generator', style: Get.textTheme.headlineSmall),
        actions: [
          Obx(() {
            if(controller.isConnect.value) {
              return Icon(Icons.bluetooth, color: Colors.green);
            } else {
              return Icon(Icons.bluetooth_disabled, color: Colors.red);
            }
          }),
          const SizedBox(width: 20),
          IconButton(onPressed: () => controller.bottomSheetConnectDevice(), style: IconButton.styleFrom(backgroundColor: Get.theme.primaryColor.withAlpha(50)), icon: Icon(Icons.settings)),
          const SizedBox(width: 20)
        ],
      ),
      floatingActionButton: FilledButton.icon(onPressed: () => controller.bottomSheetScan(), icon: Icon(Icons.camera), label: Text('Scan')),
      body: Obx(() {
        if(controller.scannedValue.value == null) {
          return Center(child: Image.asset('assets/images/no_data.png', scale: 2,));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Table(
                          columnWidths: const {
                            0: IntrinsicColumnWidth(), // kolom label
                            1: FixedColumnWidth(10),   // kolom titik dua
                            2: FlexColumnWidth(),      // kolom isi
                          },
                          children: [
                            _buildRow("ID Toko", "${controller.scannedValue.value!["it"]}"),
                            _buildRow("Nama Toko", "${controller.scannedValue.value!["nt"]}"),
                            _buildRow("Area Toko", "${controller.scannedValue.value!["at"]}"),
                            _buildRow("Pelanggan Toko", "${controller.scannedValue.value!["pt"]}"),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Bagian QR Code
                        const Text(
                          "QR Code Toko",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: controller.rawValue.value,
                          version: QrVersions.auto,
                          size: 180,
                          gapless: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (controller.scannedValue.value != null)
                  Row(
                    children: [
                      FilledButton.icon(onPressed: () {
                        controller.scannedValue.value = null;
                        controller.rawValue.value = '';
                      }, style: FilledButton.styleFrom(backgroundColor: Colors.red), icon: Icon(Icons.delete), label: Text('Hapus')),
                      const SizedBox(width: 20),
                      Expanded(child: FilledButton.icon(onPressed: () => controller.printTicket(), icon: Icon(Icons.print), label: Text('Cetak')))
                    ],
                  )
              ],
            ),
          );
        }
      })
    );
  }

  TableRow _buildRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0,6,20,6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(":"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
