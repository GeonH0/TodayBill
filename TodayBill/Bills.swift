struct Bills: Codable {
    let nzmimeepazxkubdpn: [Nzmimeepazxkubdpn]
}

struct Nzmimeepazxkubdpn: Codable {
    let head: [Head]?
    let row: [Row]?
}

struct Head: Codable {
    let list_total_count: Int?
    let RESULT: Result?
}

struct Result: Codable {
    let CODE: String
    let MESSAGE: String
}
struct Row: Codable {
    let BILL_ID: String
    let BILL_NO: String
    let BILL_NAME: String
    let COMMITTEE: String?
    let PROPOSE_DT: String
    let PROC_RESULT: String?
    let AGE: String
    let DETAIL_LINK: String
    let PROPOSER: String
    let MEMBER_LIST: String
    let LAW_PROC_DT: String?
    let LAW_PRESENT_DT: String?
    let LAW_SUBMIT_DT: String?
    let CMT_PROC_RESULT_CD: String?
    let CMT_PROC_DT: String?
    let CMT_PRESENT_DT: String?
    let COMMITTEE_DT: String?
    let PROC_DT: String?
    let COMMITTEE_ID: String?
    let PUBL_PROPOSER: String
    let LAW_PROC_RESULT_CD: String?
    let RST_PROPOSER: String?
    
    var favoriteInfo: FavoriteInfo // 즐겨찾기 정보를 따로 저장하는 클래스

    enum CodingKeys: String, CodingKey {
        case BILL_ID, BILL_NO, BILL_NAME, COMMITTEE, PROPOSE_DT, PROC_RESULT, AGE, DETAIL_LINK, PROPOSER, MEMBER_LIST, LAW_PROC_DT, LAW_PRESENT_DT, LAW_SUBMIT_DT, CMT_PROC_RESULT_CD, CMT_PROC_DT, CMT_PRESENT_DT, COMMITTEE_DT, PROC_DT, COMMITTEE_ID, PUBL_PROPOSER, LAW_PROC_RESULT_CD, RST_PROPOSER, favoriteInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        BILL_ID = try container.decode(String.self, forKey: .BILL_ID)
        BILL_NO = try container.decode(String.self, forKey: .BILL_NO)
        BILL_NAME = try container.decode(String.self, forKey: .BILL_NAME)
        COMMITTEE = try container.decode(String?.self, forKey: .COMMITTEE)
        PROPOSE_DT = try container.decode(String.self, forKey: .PROPOSE_DT)
        PROC_RESULT = try container.decode(String?.self, forKey: .PROC_RESULT)
        AGE = try container.decode(String.self, forKey: .AGE)
        DETAIL_LINK = try container.decode(String.self, forKey: .DETAIL_LINK)
        PROPOSER = try container.decode(String.self, forKey: .PROPOSER)
        MEMBER_LIST = try container.decode(String.self, forKey: .MEMBER_LIST)
        LAW_PROC_DT = try container.decode(String?.self, forKey: .LAW_PROC_DT)
        LAW_PRESENT_DT = try container.decode(String?.self, forKey: .LAW_PRESENT_DT)
        LAW_SUBMIT_DT = try container.decode(String?.self, forKey: .LAW_SUBMIT_DT)
        CMT_PROC_RESULT_CD = try container.decode(String?.self, forKey: .CMT_PROC_RESULT_CD)
        CMT_PROC_DT = try container.decode(String?.self, forKey: .CMT_PROC_DT)
        CMT_PRESENT_DT = try container.decode(String?.self, forKey: .CMT_PRESENT_DT)
        COMMITTEE_DT = try container.decode(String?.self, forKey: .COMMITTEE_DT)
        PROC_DT = try container.decode(String?.self, forKey: .PROC_DT)
        COMMITTEE_ID = try container.decode(String?.self, forKey: .COMMITTEE_ID)
        PUBL_PROPOSER = try container.decode(String.self, forKey: .PUBL_PROPOSER)
        LAW_PROC_RESULT_CD = try container.decode(String?.self, forKey: .LAW_PROC_RESULT_CD)
        RST_PROPOSER = try container.decode(String?.self, forKey: .RST_PROPOSER)
        
        favoriteInfo = FavoriteInfo(isFavorite: false) // 초기화
    }
}

struct FavoriteInfo: Codable {
    var isFavorite: Bool
}
