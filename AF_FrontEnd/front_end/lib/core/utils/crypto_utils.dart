import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';

class CryptoUtils {
  // A constant salt for our deterministic key generation during development
  static const String _devSalt = "ASCENT_FIN_CORE_DEV_SALT_2026";

  /// Generates a deterministic Ethereum private key based on the user's email.
  /// This allows us to have consistent identities for test accounts across devices
  /// without needing to implement a full backend-sync for encrypted private keys yet.
  static EthPrivateKey getDeterministicKey(String email) {
    // 1. Create a seed string
    final String seed = "${email.toLowerCase()}:$_devSalt";
    
    // 2. Generate a Keccak-256 hash of the seed
    final Uint8List hash = keccak256(Uint8List.fromList(utf8.encode(seed)));
    
    // 3. Create a private key from the hash
    return EthPrivateKey.fromHex(bytesToHex(hash));
  }

  /// Signs a vote message with the provided private key.
  /// Matches the expected format in app/utils/crypto.py
  static String signVote({
    required EthPrivateKey privateKey,
    required String campaignId,
    required String milestoneId,
    required String voteValue,
    required String nonce,
  }) {
    // Standardized message dictionary matching backend get_vote_message
    final Map<String, dynamic> messageDict = {
      "app": "Ascent_Fin",
      "campaign_id": campaignId,
      "milestone_id": milestoneId,
      "nonce": nonce,
      "vote": voteValue.toUpperCase(),
    };

    // Encode as sorted JSON string (matches sort_keys=True in Python)
    // In Dart, we can achieve this with a SplayTreeMap or just hardcoding the order if it's simple
    // deterministic JSON stringification:
    final String message = _deterministicJson(messageDict);
    print('[CRYPTO] Signing message: "$message"');
    
    // Sign the message
    final Uint8List signature = privateKey.signPersonalMessageToUint8List(
      Uint8List.fromList(utf8.encode(message))
    );
    
    return bytesToHex(signature, include0x: true);
  }

  static String _deterministicJson(Map<String, dynamic> map) {
    // Sort keys alphabetically
    final sortedKeys = map.keys.toList()..sort();
    // Python json.dumps(sort_keys=True) has a space after the comma by default: ", "
    // and a space after the colon: ": "
    final body = sortedKeys.map((key) {
      final value = map[key];
      final encodedValue = value is String ? '"$value"' : value.toString();
      return '"$key": $encodedValue';
    }).join(", ");
    
    return '{$body}';
  }
}
