String? extractAccessKeyFromUrl(String url) {
  // A expressão regular procura por uma sequência de 44 dígitos numéricos
  final RegExp regExp = RegExp(r'(\d{44})');
  final match = regExp.firstMatch(url);
  
  // Retorna a chave encontrada ou null se não encontrar
  return match?.group(1);
}