import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart'; 

class PremiumUpsellScreen extends StatelessWidget {
  const PremiumUpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Ballers Hub Premium")),
      body: Center(
        child: subProvider.isLoading 
          ? const CircularProgressIndicator() 
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, size: 100, color: Colors.orange),
                const SizedBox(height: 20),
                
                Text(
                  "Plan: ${subProvider.currentPlan}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                
                Text("Usage: ${subProvider.sub?.usedTracks ?? 0} / ${subProvider.sub?.trackLimit ?? '∞'} tracks"),
                
                const SizedBox(height: 30),

                if (!subProvider.isPremium)
                  ElevatedButton(
                    onPressed: () async {
                      await subProvider.upgradeAccount();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text("Upgrade to Artist Pro"),
                  )
                else
                  TextButton(
                    onPressed: () => subProvider.downgradeAccount(),
                    child: const Text("Cancel Subscription", style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
      ),
    );
  }
}