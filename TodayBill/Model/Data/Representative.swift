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
    let HG_NM: String
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

struct RepresentativeResponse: Codable {
    let nwvrqwxyaytdsfvhu: [RepresentativeResponseSection]
}

struct RepresentativeResponseSection: Codable {
    let head: [Head]?
    let row: [Representative]?
}

enum RepresentativeLookup {
    static func proposerName(from value: String?) -> String? {
        guard let value else { return nil }

        let withoutCount = value.replacingOccurrences(
            of: #"\s*(외|등)\s*\d+\s*인.*$"#,
            with: "",
            options: .regularExpression
        )
        let separators = CharacterSet(charactersIn: ",;ㆍ·\n")
        guard let first = withoutCount.components(separatedBy: separators)
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty && $0 != "-" }) else {
            return nil
        }

        let name = first.replacingOccurrences(
            of: #"\s*의원\s*$"#,
            with: "",
            options: .regularExpression
        )
        return nonEmpty(name)
    }

    static func normalizedName(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }

    static func displayText(proposer: String?, representative: Representative?) -> String {
        guard let proposer = nonEmpty(proposer) else { return "미확인" }

        if let representative,
           let party = nonEmpty(representative.POLY_NM) {
            return "\(representative.HG_NM) 의원 · \(party)"
        }

        let withoutCount = proposer.replacingOccurrences(
            of: #"\s*(외|등)\s*\d+\s*인.*$"#,
            with: "",
            options: .regularExpression
        )
        let separators = CharacterSet(charactersIn: ",;ㆍ·\n")
        return withoutCount.components(separatedBy: separators)
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty && $0 != "-" }) ?? proposer
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "-" ? nil : trimmed
    }
}
