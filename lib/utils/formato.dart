String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// Ex.: 15/11/2026 21:05
String formatarData(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// Ex.: 5,2 km
String formatarDistancia(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Ex.: 24 °C
String formatarTemperatura(double t) => '${t.round()} °C';
