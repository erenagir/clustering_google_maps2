class Geohash {
  static String encode(double latitude, double longitude) {
    // Basit bir kodlama yapıyoruz (gerçek geohash gibi değil ama iş görür)
    return "${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}";
  }
}