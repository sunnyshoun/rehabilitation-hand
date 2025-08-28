class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '請輸入$fieldName' : '此欄位為必填';
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入電子郵件';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '請輸入有效的電子郵件';
    }
    return null;
  }
  
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return fieldName != null 
        ? '$fieldName至少需要$min個字元'
        : '至少需要$min個字元';
    }
    return null;
  }
  
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return fieldName != null
        ? '$fieldName不能超過$max個字元'
        : '不能超過$max個字元';
    }
    return null;
  }
}