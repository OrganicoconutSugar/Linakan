/// Status listing limbah.
enum ListingStatus {
  available,
  reserved,
  completed,
  expired,
}

extension ListingStatusExtension on ListingStatus {
  String get id {
    switch (this) {
      case ListingStatus.available:
        return 'available';
      case ListingStatus.reserved:
        return 'reserved';
      case ListingStatus.completed:
        return 'completed';
      case ListingStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case ListingStatus.available:
        return 'Tersedia';
      case ListingStatus.reserved:
        return 'Dipesan';
      case ListingStatus.completed:
        return 'Selesai';
      case ListingStatus.expired:
        return 'Kadaluarsa';
    }
  }

  static ListingStatus fromId(String id) {
    switch (id) {
      case 'available':
        return ListingStatus.available;
      case 'reserved':
        return ListingStatus.reserved;
      case 'completed':
        return ListingStatus.completed;
      case 'expired':
        return ListingStatus.expired;
      default:
        return ListingStatus.available;
    }
  }
}
