import 'package:flutter/material.dart';

class StoreHeaderWidget extends StatelessWidget {
  final String storeName;
  final String location;
  final String ownerName;
  final String category;
  final bool isOnline;
  final String merchantId;
  final int pendingCount;
  final bool isSearchOpen;
  final VoidCallback onToggleSearch;
  final Function(String, bool) onToggleOnline;
  final Function(BuildContext, String, String) onLocationTap;
  final VoidCallback onNotificationTap;
  final Function(BuildContext, String, String, String, String, String) onProfileTap;

  const StoreHeaderWidget({
    super.key,
    required this.storeName,
    required this.location,
    required this.ownerName,
    required this.category,
    required this.isOnline,
    required this.merchantId,
    required this.pendingCount,
    required this.isSearchOpen,
    required this.onToggleSearch,
    required this.onToggleOnline,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color textDark = Color(0xFF1E293B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => onToggleOnline(merchantId, isOnline),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isOnline ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              InkWell(
                onTap: () => onLocationTap(context, merchantId, location),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_location_rounded, size: 11, color: primaryBlue),
                            SizedBox(width: 2),
                            Text('Edit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryBlue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Search products',
          icon: Icon(
            isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
            color: isSearchOpen ? primaryBlue : const Color(0xFF475569),
            size: 22,
          ),
          onPressed: onToggleSearch,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: textDark, size: 22),
              onPressed: onNotificationTap,
            ),
            if (pendingCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$pendingCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        GestureDetector(
          onTap: () => onProfileTap(context, ownerName, storeName, location, category, merchantId),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(
                ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}