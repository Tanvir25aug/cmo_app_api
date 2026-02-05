class Customer {
  final String? id;
  final String? indexNo;
  final String? oldConsumerId;
  final String? customerName;
  final String? address;
  final String? floorNo;
  final String? flatNo;
  final String? passport;
  final String? birthCertificate;
  final String? nid;
  final String? mobileNo;
  final String? changedMobileNo;
  final String? secondaryMobileNo;
  final String? emailId;
  final String? fatherName;
  final String? motherName;
  final String? spouseName;
  final String? dob;
  final String? mailingCountry;
  final String? mailingPostalCode;
  final String? mailingDistrict;
  final String? premiseType;
  final String? country;
  final String? postalCode;
  final String? district;
  final String? thana;
  final String? area;
  final String? zone;
  final String? zoneCode;
  final String? circle;
  final String? circleCode;
  final String? nocs;
  final String? nocsCode;
  final String? sector;
  final String? customerCreatedDt;
  final String? billRouteType;
  final String? relationshipType;
  final String? billGroup;
  final String? oldNewCustomer;
  final String? vipCustomer;
  final String? connectionType;
  final String? oldAccountNo;
  final String? meterOwner;
  final String? meterType;
  final String? meterTypeRemarks;
  final String? transformerOwner;
  final String? transformerSide;
  final String? cpcCpr;
  final String? cprConsumerId;
  final String? likelyConsumption;
  final String? walkOrder;
  final String? book;
  final String? netmeterFlag;
  final String? xformerCd;
  final String? meteringMode;
  final String? omf;
  final String? custTariffCategory;
  final String? sanctionedLoad;
  final String? connectedLoad;
  final String? businessType;
  final String? businessTypeDesc;
  final String? noOfSpmCust;
  final String? vatRebate;
  final String? specialCategory;
  final String? statusCode;
  final String? ministry;
  final String? organization;
  final String? dmdChargeAftMigr;
  final String? subStationCd;
  final String? subStationName;
  final String? feederCd;
  final String? feederName;
  final String? oldMeterNo; // Old meter number from backend
  final DateTime? syncedAt;

  Customer({
    this.id,
    this.indexNo,
    this.oldConsumerId,
    this.customerName,
    this.address,
    this.floorNo,
    this.flatNo,
    this.passport,
    this.birthCertificate,
    this.nid,
    this.mobileNo,
    this.changedMobileNo,
    this.secondaryMobileNo,
    this.emailId,
    this.fatherName,
    this.motherName,
    this.spouseName,
    this.dob,
    this.mailingCountry,
    this.mailingPostalCode,
    this.mailingDistrict,
    this.premiseType,
    this.country,
    this.postalCode,
    this.district,
    this.thana,
    this.area,
    this.zone,
    this.zoneCode,
    this.circle,
    this.circleCode,
    this.nocs,
    this.nocsCode,
    this.sector,
    this.customerCreatedDt,
    this.billRouteType,
    this.relationshipType,
    this.billGroup,
    this.oldNewCustomer,
    this.vipCustomer,
    this.connectionType,
    this.oldAccountNo,
    this.meterOwner,
    this.meterType,
    this.meterTypeRemarks,
    this.transformerOwner,
    this.transformerSide,
    this.cpcCpr,
    this.cprConsumerId,
    this.likelyConsumption,
    this.walkOrder,
    this.book,
    this.netmeterFlag,
    this.xformerCd,
    this.meteringMode,
    this.omf,
    this.custTariffCategory,
    this.sanctionedLoad,
    this.connectedLoad,
    this.businessType,
    this.businessTypeDesc,
    this.noOfSpmCust,
    this.vatRebate,
    this.specialCategory,
    this.statusCode,
    this.ministry,
    this.organization,
    this.dmdChargeAftMigr,
    this.subStationCd,
    this.subStationName,
    this.feederCd,
    this.feederName,
    this.oldMeterNo,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'index_no': indexNo,
      'old_consumer_id': oldConsumerId,
      'customer_name': customerName,
      'address': address,
      'floor_no': floorNo,
      'flat_no': flatNo,
      'passport': passport,
      'birth_certificate': birthCertificate,
      'nid': nid,
      'mobile_no': mobileNo,
      'changed_mobile_no': changedMobileNo,
      'secondary_mobile_no': secondaryMobileNo,
      'email_id': emailId,
      'father_name': fatherName,
      'mother_name': motherName,
      'spouse_name': spouseName,
      'dob': dob,
      'mailing_country': mailingCountry,
      'mailing_postal_code': mailingPostalCode,
      'mailing_district': mailingDistrict,
      'premise_type': premiseType,
      'country': country,
      'postal_code': postalCode,
      'district': district,
      'thana': thana,
      'area': area,
      'zone': zone,
      'zone_code': zoneCode,
      'circle': circle,
      'circle_code': circleCode,
      'nocs': nocs,
      'nocs_code': nocsCode,
      'sector': sector,
      'customer_created_dt': customerCreatedDt,
      'bill_route_type': billRouteType,
      'relationship_type': relationshipType,
      'bill_group': billGroup,
      'old_new_customer': oldNewCustomer,
      'vip_customer': vipCustomer,
      'connection_type': connectionType,
      'old_account_no': oldAccountNo,
      'meter_owner': meterOwner,
      'meter_type': meterType,
      'meter_type_remarks': meterTypeRemarks,
      'transformer_owner': transformerOwner,
      'transformer_side': transformerSide,
      'cpc_cpr': cpcCpr,
      'cpr_consumer_id': cprConsumerId,
      'likely_consumption': likelyConsumption,
      'walk_order': walkOrder,
      'book': book,
      'netmeter_flag': netmeterFlag,
      'xformer_cd': xformerCd,
      'metering_mode': meteringMode,
      'omf': omf,
      'cust_tariff_category': custTariffCategory,
      'sanctioned_load': sanctionedLoad,
      'connected_load': connectedLoad,
      'business_type': businessType,
      'business_type_desc': businessTypeDesc,
      'no_of_spm_cust': noOfSpmCust,
      'vat_rebate': vatRebate,
      'special_category': specialCategory,
      'status_code': statusCode,
      'ministry': ministry,
      'organization': organization,
      'dmd_charge_aft_migr': dmdChargeAftMigr,
      'sub_station_cd': subStationCd,
      'sub_station_name': subStationName,
      'feeder_cd': feederCd,
      'feeder_name': feederName,
      'old_meter_no': oldMeterNo,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString(),
      indexNo: map['index_no']?.toString() ?? map['INDEX_NO']?.toString(),
      oldConsumerId: map['old_consumer_id']?.toString() ?? map['OLD_CONSUMER_ID']?.toString(),
      customerName: map['customer_name']?.toString() ?? map['CUSTOMER_NAME']?.toString(),
      address: map['address']?.toString() ?? map['ADDRESS']?.toString(),
      floorNo: map['floor_no']?.toString() ?? map['FLOOR_NO']?.toString(),
      flatNo: map['flat_no']?.toString() ?? map['FLAT_NO']?.toString(),
      passport: map['passport']?.toString() ?? map['PASSPORT']?.toString(),
      birthCertificate: map['birth_certificate']?.toString() ?? map['BIRTH_CERTIFICATE']?.toString(),
      nid: map['nid']?.toString() ?? map['NID']?.toString(),
      mobileNo: map['mobile_no']?.toString() ?? map['MOBILE_NO']?.toString(),
      changedMobileNo: map['changed_mobile_no']?.toString() ?? map['CHANGED_MOBILE_NO']?.toString(),
      secondaryMobileNo: map['secondary_mobile_no']?.toString() ?? map['SECONDARY_MOBILE_NO']?.toString(),
      emailId: map['email_id']?.toString() ?? map['EMAIL_ID']?.toString(),
      fatherName: map['father_name']?.toString() ?? map['FATHER_NAME']?.toString(),
      motherName: map['mother_name']?.toString() ?? map['MOTHER_NAME']?.toString(),
      spouseName: map['spouse_name']?.toString() ?? map['SPOUSE_NAME']?.toString(),
      dob: map['dob']?.toString() ?? map['DOB']?.toString(),
      mailingCountry: map['mailing_country']?.toString() ?? map['MAILING_COUNTRY']?.toString(),
      mailingPostalCode: map['mailing_postal_code']?.toString() ?? map['MAILING_POSTAL_CODE']?.toString(),
      mailingDistrict: map['mailing_district']?.toString() ?? map['MAILING_DISTRICT']?.toString(),
      premiseType: map['premise_type']?.toString() ?? map['PREMISE_TYPE']?.toString(),
      country: map['country']?.toString() ?? map['COUNTRY']?.toString(),
      postalCode: map['postal_code']?.toString() ?? map['POSTAL_CODE']?.toString(),
      district: map['district']?.toString() ?? map['DISTRICT']?.toString(),
      thana: map['thana']?.toString() ?? map['THANA']?.toString(),
      area: map['area']?.toString() ?? map['AREA']?.toString(),
      zone: map['zone']?.toString() ?? map['ZONE']?.toString(),
      zoneCode: map['zone_code']?.toString() ?? map['ZONE_CODE']?.toString(),
      circle: map['circle']?.toString() ?? map['CIRCLE']?.toString(),
      circleCode: map['circle_code']?.toString() ?? map['CIRCLE_CODE']?.toString(),
      nocs: map['nocs']?.toString() ?? map['NOCS']?.toString(),
      nocsCode: map['nocs_code']?.toString() ?? map['NOCS_CODE']?.toString(),
      sector: map['sector']?.toString() ?? map['SECTOR']?.toString(),
      customerCreatedDt: map['customer_created_dt']?.toString() ?? map['CUSTOMER_CREATED_DT']?.toString(),
      billRouteType: map['bill_route_type']?.toString() ?? map['BILL_ROUTE_TYPE']?.toString(),
      relationshipType: map['relationship_type']?.toString() ?? map['RELATIONSHIP_TYPE']?.toString(),
      billGroup: map['bill_group']?.toString() ?? map['BILL_GROUP']?.toString(),
      oldNewCustomer: map['old_new_customer']?.toString() ?? map['OLD_NEW_CUSTOMER']?.toString(),
      vipCustomer: map['vip_customer']?.toString() ?? map['VIP_CUSTOMER']?.toString(),
      connectionType: map['connection_type']?.toString() ?? map['CONNECTION_TYPE']?.toString(),
      oldAccountNo: map['old_account_no']?.toString() ?? map['OLD_ACCOUNT_NO']?.toString(),
      meterOwner: map['meter_owner']?.toString() ?? map['METER_OWNER']?.toString(),
      meterType: map['meter_type']?.toString() ?? map['METER_TYPE']?.toString(),
      meterTypeRemarks: map['meter_type_remarks']?.toString() ?? map['METER_TYPE_REMARKS']?.toString(),
      transformerOwner: map['transformer_owner']?.toString() ?? map['TRANSFORMER_OWNER']?.toString(),
      transformerSide: map['transformer_side']?.toString() ?? map['TRANSFORMER_SIDE']?.toString(),
      cpcCpr: map['cpc_cpr']?.toString() ?? map['CPC_CPR']?.toString(),
      cprConsumerId: map['cpr_consumer_id']?.toString() ?? map['CPR_CONSUMER_ID']?.toString(),
      likelyConsumption: map['likely_consumption']?.toString() ?? map['LIKELY_CONSUMPTION']?.toString(),
      walkOrder: map['walk_order']?.toString() ?? map['WALK_ORDER']?.toString(),
      book: map['book']?.toString() ?? map['BOOK']?.toString(),
      netmeterFlag: map['netmeter_flag']?.toString() ?? map['NETMETER_FLAG']?.toString(),
      xformerCd: map['xformer_cd']?.toString() ?? map['XFORMER_CD']?.toString(),
      meteringMode: map['metering_mode']?.toString() ?? map['METERING_MODE']?.toString(),
      omf: map['omf']?.toString() ?? map['OMF']?.toString(),
      custTariffCategory: map['cust_tariff_category']?.toString() ?? map['CUST_TARIFF_CATEGORY']?.toString(),
      sanctionedLoad: map['sanctioned_load']?.toString() ?? map['SANCTIONED_LOAD']?.toString(),
      connectedLoad: map['connected_load']?.toString() ?? map['CONNECTED_LOAD']?.toString(),
      businessType: map['business_type']?.toString() ?? map['BUSINESS_TYPE']?.toString(),
      businessTypeDesc: map['business_type_desc']?.toString() ?? map['BUSINESS_TYPE_DESC']?.toString(),
      noOfSpmCust: map['no_of_spm_cust']?.toString() ?? map['NO_OF_SPM_CUST']?.toString(),
      vatRebate: map['vat_rebate']?.toString() ?? map['VAT_REBATE']?.toString(),
      specialCategory: map['special_category']?.toString() ?? map['SPECIAL_CATEGORY']?.toString(),
      statusCode: map['status_code']?.toString() ?? map['STATUS_CODE']?.toString(),
      ministry: map['ministry']?.toString() ?? map['MINISTRY']?.toString(),
      organization: map['organization']?.toString() ?? map['ORGANIZATION']?.toString(),
      dmdChargeAftMigr: map['dmd_charge_aft_migr']?.toString() ?? map['DMD_CHARGE_AFT_MIGR']?.toString(),
      subStationCd: map['sub_station_cd']?.toString() ?? map['SUB_STATION_CD']?.toString(),
      subStationName: map['sub_station_name']?.toString() ?? map['SUB_STATION_NAME']?.toString(),
      feederCd: map['feeder_cd']?.toString() ?? map['FEEDER_CD']?.toString(),
      feederName: map['feeder_name']?.toString() ?? map['FEEDER_NAME']?.toString(),
      oldMeterNo: map['old_meter_no']?.toString() ?? map['OLD_METER_NO']?.toString() ?? map['meter_no']?.toString() ?? map['METER_NO']?.toString(),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'])
          : null,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}
