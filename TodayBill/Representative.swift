//
//  Representative.swift
//  TodayBill
//
//  Created by 김건호 on 11/24/23.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let represent = try? JSONDecoder().decode(Represent.self, from: jsonData)

import Foundation


struct Representative: Codable {
    let HG_NM: String?
    let HJ_NM: String?
    let ENG_NM: String?
    let BTH_GBN_NM: String?
    let BTH_DATE: String?
    let JOB_RES_NM: String?
    let POLY_NM: String?
    let ORIG_NM: String?
    let ELECT_GBN_NM: String?
    let CMIT_NM: String?
    let CMITS: String?
    let REELE_GBN_NM: String?
    let UNITS: String?
    let SEX_GBN_NM: String?
    let TEL_NO: String?
    let E_MAIL: String?
    let HOMEPAGE: String?
    let STAFF: String?
    let SECRETARY: String?
    let SECRETARY2: String?
    let MONA_CD: String?
    let MEM_TITLE: String?
    let ASSEM_ADDR: String?
}

