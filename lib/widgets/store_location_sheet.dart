import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';

class StoreLocationSheet extends StatefulWidget {
  final String merchantId;
  final String currentSavedLocation;

  const StoreLocationSheet({
    super.key,
    required this.merchantId,
    required this.currentSavedLocation,
  });

  @override
  State<StoreLocationSheet> createState() => _StoreLocationSheetState();
}

class _StoreLocationSheetState extends State<StoreLocationSheet> {
  late TextEditingController manualLocationController;
  late String liveDetectedAddress;
  bool isDetecting = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    manualLocationController = TextEditingController();
    liveDetectedAddress = widget.currentSavedLocation;
  }

  @override
  void dispose() {
    manualLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Set Shop Location',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Live GPS address leda manual address set cheskondi:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          const Text(
            '1. Live GPS Location (Auto-Detected)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_rounded, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveDetectedAddress.isNotEmpty ? liveDetectedAddress : 'Detecting GPS...',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Google Maps live address',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: isDetecting
                      ? null
                      : () async {
                          setState(() => isDetecting = true);
                          final res = await LocationService.instance.getCurrentLiveLocation();
                          if (res.success) {
                            setState(() {
                              liveDetectedAddress = res.address;
                              isDetecting = false;
                            });
                          } else {
                            setState(() => isDetecting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res.errorMessage ?? 'GPS Error')),
                              );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDetecting)
                          const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5))
                        else
                          const Icon(Icons.refresh_rounded, size: 12, color: primaryBlue),
                        const SizedBox(width: 3),
                        const Text('Re-Detect', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryBlue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '2. Manual Custom Address (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: manualLocationController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: textDark),
            decoration: InputDecoration(
              hintText: 'Eg: Shop No. 5, Opp. RTC Bus Stand, Trunk Road, Nellore',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.edit_location_alt_outlined, color: primaryPurple, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final manualText = manualLocationController.text.trim();
                final finalLocation = manualText.isNotEmpty ? manualText : liveDetectedAddress;

                await FirebaseFirestore.instance.collection('merchants').doc(widget.merchantId).set({
                  'location': finalLocation,
                  'isManualLocation': manualText.isNotEmpty,
                  'lastLocationUpdate': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Save Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}