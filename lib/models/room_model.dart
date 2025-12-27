enum RoomStatus { available, occupied, maintenance }

class RoomModel {
  final String id;
  final String roomNumber;
  final double rate;
  final int capacity;
  final RoomStatus status;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.rate,
    required this.capacity,
    this.status = RoomStatus.available,
  });
}