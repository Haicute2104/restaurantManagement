class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số';
    }
    
    if (double.tryParse(value) == null) {
      return 'Giá trị phải là số';
    }
    
    return null;
  }

  static String? positiveNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) return numberError;
    
    if (double.parse(value!) <= 0) {
      return 'Giá trị phải lớn hơn 0';
    }
    
    return null;
  }

  static String? tableNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) return numberError;
    
    final num = int.tryParse(value!);
    if (num == null || num < 1 || num > 100) {
      return 'Số bàn phải từ 1 đến 100';
    }
    
    return null;
  }
}





