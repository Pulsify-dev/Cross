import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross/providers/user_provider.dart';

class PremiumUpsellScreen extends StatelessWidget {
  const PremiumUpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 100),
            const SizedBox(height: 20),
            const Text(
              "Upgrade to Pro+",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Unlock unlimited uploads and ad-free listening.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _buildFeature(Icons.bolt, "Unlimited Track Uploads"),
            _buildFeature(Icons.ad_units_off, "No Interrupting Ads"),
            _buildFeature(Icons.download_for_offline, "Offline Mode (Mock)"),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  // Mock Stripe Payment Logic
                  context.read<UserProvider>().upgradeToPremium();
                  Navigator.pop(context);
                },
                child: const Text(
                  "GET PREMIUM",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}