class TotalNutrients {
  ENERCKCAL? fAT;
  ENERCKCAL? cHOCDF;
  ENERCKCAL? pROCNT;

  TotalNutrients({this.fAT, this.cHOCDF, this.pROCNT});

  factory TotalNutrients.fromJson(Map<String, dynamic> json) {
    return TotalNutrients(
      fAT: json['FAT'] != null ? ENERCKCAL.fromJson(json['FAT']) : null,
      cHOCDF: json['CHOCDF'] != null ? ENERCKCAL.fromJson(json['CHOCDF']) : null,
      pROCNT: json['PROCNT'] != null ? ENERCKCAL.fromJson(json['PROCNT']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.fAT != null) {
      data['FAT'] = this.fAT!.toJson();
    }
    if (this.cHOCDF != null) {
      data['CHOCDF'] = this.cHOCDF!.toJson();
    }
    if (this.pROCNT != null) {
      data['PROCNT'] = this.pROCNT!.toJson();
    }
    return data;
  }
}

class ENERCKCAL {
  String? label;
  double? quantity;
  String? unit;

  ENERCKCAL({this.label, this.quantity, this.unit});

  factory ENERCKCAL.fromJson(Map<String, dynamic> json) {
    return ENERCKCAL(
      label: json['label'],
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['quantity'] = this.quantity;
    data['unit'] = this.unit;
    return data;
  }
}
