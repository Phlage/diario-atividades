class Coordenadas {
  const Coordenadas(this.latitude, this.longitude, {this.nome});

  final double latitude;
  final double longitude;

  /// Nome do lugar, quando conhecido (ex.: cidade digitada).
  final String? nome;
}
