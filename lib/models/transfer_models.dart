import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Represents the type of content being transferred
enum TransferItemType { file, text }

/// Represents the file type for preview purposes
enum FilePreviewType { image, video, audio, pdf, text, other }

/// Represents a single item (file or text) to be transferred
class TransferItem {
  final String id; // Unique identifier for the item
  final TransferItemType type;
  final String name; // File name or description for text
  String? path; // Local file path (for files only)
  final int size; // Size in bytes
  final Uint8List? bytes; // File bytes (used during transfer)
  final String? textContent; // Text content (for text items only)
  final String? hash; // SHA256 hash of the item's content
  bool isSelected; // Whether this item is selected for transfer
  bool isVerified; // Whether the item has been verified against its hash
  bool isSaved; // Whether the file has been saved to storage
  FilePreviewType? previewType; // Type of file for preview purposes

  TransferItem({
    required this.id,
    required this.type,
    required this.name,
    this.path,
    required this.size,
    this.bytes,
    this.textContent,
    this.hash,
    this.isSelected = true,
    this.isVerified = false,
    this.isSaved = false,
    this.previewType,
  }) {
    // Determine preview type if not provided
    if (previewType == null && type == TransferItemType.file) {
      previewType = _determineFileType(name);
    }
  }

  /// Determine the file type based on extension
  FilePreviewType _determineFileType(String fileName) {
    // Extract extension manually to avoid path package issues
    final fileExtension = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase() : '';

    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'].contains(fileExtension)) {
      return FilePreviewType.image;
    }
    // Video files
    else if (['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.3gp'].contains(fileExtension)) {
      return FilePreviewType.video;
    }
    // Audio files
    else if (['.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'].contains(fileExtension)) {
      return FilePreviewType.audio;
    }
    // PDF files
    else if (fileExtension == '.pdf') {
      return FilePreviewType.pdf;
    }
    // Text files
    else if (['.txt', '.md', '.json', '.xml', '.html', '.css', '.js', '.dart', '.java', '.py', '.c', '.cpp'].contains(fileExtension)) {
      return FilePreviewType.text;
    }
    // Other files
    else {
      return FilePreviewType.other;
    }
  }

  /// Create a TransferItem from a PlatformFile
  factory TransferItem.fromPlatformFile(PlatformFile file) {
    return TransferItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      type: TransferItemType.file,
      name: file.name,
      path: file.path,
      size: file.size,
      isSelected: true,
      isSaved: false,
    );
  }

  /// Create a TransferItem from text content
  factory TransferItem.fromText(String text, {String name = 'Text message'}) {
    return TransferItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_text',
      type: TransferItemType.text,
      name: name,
      size: utf8.encode(text).length,
      textContent: text,
      isSelected: true,
      isSaved: true, // Text messages are considered saved by default
    );
  }

  /// Convert to JSON for network transfer
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'id': id, 'type': type == TransferItemType.file ? 'file' : 'text', 'name': name, 'size': size};

    if (hash != null) {
      json['hash'] = hash;
    }

    if (type == TransferItemType.file && bytes != null) {
      json['data'] = base64Encode(bytes!);
    } else if (type == TransferItemType.text && textContent != null) {
      json['data'] = textContent;
    }

    return json;
  }

  /// Create a TransferItem from JSON (received from network)
  factory TransferItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'file' ? TransferItemType.file : TransferItemType.text;

    Uint8List? bytes;
    if (type == TransferItemType.file && json['data'] != null) {
      bytes = base64Decode(json['data']);
    }

    return TransferItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: json['name'] ?? (type == TransferItemType.text ? 'Text message' : 'Unknown file'),
      size: json['size'] ?? 0,
      bytes: bytes,
      textContent: type == TransferItemType.text ? json['data'] : null,
      hash: json['hash'],
      isSelected: true,
      isVerified: false, // Will be verified after receiving
      isSaved: false,
    );
  }

  /// Create a copy of this TransferItem with updated properties
  TransferItem copyWith({
    String? id,
    TransferItemType? type,
    String? name,
    String? path,
    int? size,
    Uint8List? bytes,
    String? textContent,
    String? hash,
    bool? isSelected,
    bool? isVerified,
    bool? isSaved,
    FilePreviewType? previewType,
  }) {
    return TransferItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      bytes: bytes ?? this.bytes,
      textContent: textContent ?? this.textContent,
      hash: hash ?? this.hash,
      isSelected: isSelected ?? this.isSelected,
      isVerified: isVerified ?? this.isVerified,
      isSaved: isSaved ?? this.isSaved,
      previewType: previewType ?? this.previewType,
    );
  }
}

/// Represents a batch of items to be transferred together
class TransferBatch {
  final String id; // Unique identifier for the batch
  final List<TransferItem> items;
  final DateTime timestamp;
  final String protocol = 'toss-v4'; // Protocol version for compatibility
  final bool isHashOnly; // Whether this batch contains only hash information
  final bool isEncrypted; // Whether the batch is encrypted
  final String? encryptedData; // Encrypted data (when isEncrypted is true)

  TransferBatch({required this.id, required this.items, DateTime? timestamp, this.isHashOnly = false, this.isEncrypted = false, this.encryptedData})
    : timestamp = timestamp ?? DateTime.now();

  /// Create a batch with a single item
  factory TransferBatch.single(TransferItem item, {bool isHashOnly = false, bool isEncrypted = false, String? encryptedData}) {
    return TransferBatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: [item],
      isHashOnly: isHashOnly,
      isEncrypted: isEncrypted,
      encryptedData: encryptedData,
    );
  }

  /// Create a batch with only hash information
  factory TransferBatch.hashOnly(String batchId, List<TransferItem> items) {
    return TransferBatch(id: batchId, items: items, isHashOnly: true);
  }

  /// Create an encrypted batch
  factory TransferBatch.encrypted(String batchId, String encryptedData, {DateTime? timestamp}) {
    return TransferBatch(
      id: batchId,
      items: [], // Empty list since data is encrypted
      timestamp: timestamp,
      isEncrypted: true,
      encryptedData: encryptedData,
    );
  }

  /// Convert to JSON for network transfer
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'protocol': protocol,
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'itemCount': items.length,
      'isHashOnly': isHashOnly,
      'isEncrypted': isEncrypted,
    };

    // If encrypted, include encrypted data instead of items
    if (isEncrypted && encryptedData != null) {
      json['encryptedData'] = encryptedData;
    } else {
      // Otherwise include the items as usual
      json['items'] = items.map((item) => item.toJson()).toList();
    }

    return json;
  }

  /// Create a TransferBatch from JSON (received from network)
  factory TransferBatch.fromJson(Map<String, dynamic> json) {
    // Check if this is an encrypted batch
    final bool isEncrypted = json['isEncrypted'] ?? false;
    final String? encryptedData = json['encryptedData'];

    // If encrypted, create an encrypted batch
    if (isEncrypted && encryptedData != null) {
      return TransferBatch.encrypted(
        json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        encryptedData,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      );
    }

    // Otherwise, process as a normal batch
    final List<dynamic> itemsJson = json['items'] ?? [];
    final List<TransferItem> items = itemsJson.map((itemJson) => TransferItem.fromJson(itemJson)).toList();

    return TransferBatch(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isHashOnly: json['isHashOnly'] ?? false,
      isEncrypted: false,
    );
  }

  /// Get the total size of all items in the batch
  int get totalSize => items.fold(0, (sum, item) => sum + item.size);

  /// Get only the selected items
  List<TransferItem> get selectedItems => items.where((item) => item.isSelected).toList();
}
