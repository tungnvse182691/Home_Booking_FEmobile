List<dynamic> extractItems(dynamic value) {
  if (value == null) return [];
  if (value is List) return value;
  if (value is Map) {
    // Common wrappers: { items: [...] } or { data: { items: [...] } }
    if (value.containsKey('items') && value['items'] is List) return value['items'] as List;
    if (value.containsKey('data')) return extractItems(value['data']);
  }
  return [];
}

Map<String, dynamic> extractDataMap(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    final data = responseData['data'];
    if (data is Map<String, dynamic>) return data;
    return responseData;
  }
  if (responseData is Map) {
    final data = responseData['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(responseData);
  }
  return <String, dynamic>{};
}
